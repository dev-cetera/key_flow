//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The keyboard layer of an app: every command, the keys that run them, and
/// the panels that make them findable without a mouse.
///
/// Put one around the whole app, best in `MaterialApp.builder` (or
/// `WidgetsApp.builder`) so it covers every route and dialog:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => KeyFlow(
///     commands: [
///       KeyCommand(id: 'new', label: 'New project', keys: ['meta+n'],
///           onRun: (context) => newProject()),
///       KeyGroup(id: 'go', label: 'Go to', keys: ['g'], children: [
///         KeyCommand(id: 'inbox', label: 'Inbox', keys: ['i'],
///             onRun: (context) => openInbox()),
///       ]),
///     ],
///     child: child!,
///   ),
/// )
/// ```
///
/// Then wrap each part of the screen that has commands of its own in a
/// [KeyFlowScope]. The commands in force are this widget's, then each scope's
/// around the focused widget, the nearest last and winning.
///
/// Out of the box a person can also:
///
/// - press a group's keys and see a panel of what to press next, which stays
///   until they choose, press Escape, or Backspace to go back a level;
/// - search every command by name (⌘K);
/// - see every shortcut on one sheet (`?` or ⌘/);
/// - jump to any control on screen by typing the letters shown on it (⌘J);
/// - move between the areas of the screen (F6 and ⇧F6).
///
/// [KeyFlowBuiltIns] changes those keys and names. Agents and an app's own AI
/// reach the same commands through [KeyFlowController.currentTree] and
/// [KeyFlowController.run].
class KeyFlow extends StatefulWidget {
  /// The app-wide commands.
  final List<KeyNode> commands;

  /// The app.
  final Widget child;

  /// Lets code outside the widget tree read and drive key_flow. One is made
  /// when this is null; [KeyFlow.of] finds either.
  final KeyFlowController? controller;

  /// Keys a person chose instead of a command's own, by full id:
  /// `{'go.inbox': ['g i'], 'keyflow.palette': ['meta+p']}`. An empty list
  /// takes a command's keys away. Save what [onKeyOverridesChanged] reports
  /// and pass it back here.
  final Map<String, List<String>> keyOverrides;

  /// Called when [KeyFlowController.setKeys] changes [keyOverrides].
  final ValueChanged<Map<String, List<String>>>? onKeyOverridesChanged;

  /// The names and keys of the commands key_flow adds.
  final KeyFlowBuiltIns builtIns;

  /// The words key_flow's panels use.
  final KeyFlowStrings strings;

  /// How key_flow's panels, focus rings and key caps look. Taken from the
  /// app's [Theme] when null.
  final KeyFlowStyle? style;

  /// How long a group stays open with no key pressed. Null, the default,
  /// keeps it open until a command runs or Escape closes it: what people
  /// new to the keys and agents both need.
  final Duration? prefixTimeout;

  /// Whether controls linked to a command also give its shortcut as their
  /// accessibility value, so it reaches screen readers and agents on
  /// platforms that drop the hint (macOS). Null decides by platform.
  final bool? shortcutsInSemanticsValue;

  /// Called each time a command runs, from keys, a panel, a menu, a linked
  /// control or code: for logging, or to tell an app's AI what the person
  /// just did.
  final ValueChanged<KeyCommandEntry>? onCommandRun;

  /// Wraps or replaces a panel. Given the default panel as [child]; return it
  /// wrapped (a theme, a different position) or something else drawn from
  /// [KeyFlow.of].
  final Widget Function(BuildContext context, KeyFlowPanel panel, Widget child)?
  panelBuilder;

  const KeyFlow({
    super.key,
    this.commands = const [],
    required this.child,
    this.controller,
    this.keyOverrides = const {},
    this.onKeyOverridesChanged,
    this.builtIns = const KeyFlowBuiltIns(),
    this.strings = const KeyFlowStrings(),
    this.style,
    this.prefixTimeout,
    this.shortcutsInSemanticsValue,
    this.onCommandRun,
    this.panelBuilder,
  });

  /// The controller of the nearest [KeyFlow] above [context].
  static KeyFlowController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No KeyFlow above this context');
    return controller!;
  }

  /// The controller of the nearest [KeyFlow] above [context], if any.
  static KeyFlowController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_KeyFlowData>()
        ?.controller;
  }

  /// The style the nearest [KeyFlow] was given, if any; see
  /// [KeyFlowStyle.of].
  @internal
  static KeyFlowStyle? styleOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_KeyFlowData>()?.style;
  }

  @override
  State<KeyFlow> createState() => _KeyFlowState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A part of the screen with commands of its own: they apply while the focus
/// is inside it, on top of the commands around it.
///
/// Scopes nest as deep as the screen does. Clicking inside a scope moves the
/// focus into it (unless something inside takes it), so its commands apply
/// from then on.
class KeyFlowScope extends StatefulWidget {
  /// The commands this part of the screen adds.
  final List<KeyNode> commands;

  /// This part of the screen.
  final Widget child;

  /// A name for this part of the screen, such as "Sidebar". Named scopes are
  /// the areas F6 moves between, and screen readers and agents read the name.
  final String? region;

  /// Whether a click inside moves the focus here.
  final bool focusOnPointerDown;

  const KeyFlowScope({
    super.key,
    this.commands = const [],
    required this.child,
    this.region,
    this.focusOnPointerDown = true,
  });

  @override
  State<KeyFlowScope> createState() => _KeyFlowScopeState();
}

class _KeyFlowScopeState extends State<KeyFlowScope> {
  late final FocusNode _node = FocusNode(
    debugLabel: 'KeyFlowScope ${widget.region ?? ''}'.trim(),
    skipTraversal: true,
  );
  _KeyFlowState? _host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = KeyFlow.maybeOf(context)?._host;
    if (!identical(host, _host)) {
      _host?._regions.remove(this);
      _host = host;
    }
    if (widget.region != null) _host?._regions.add(this);
  }

  @override
  void didUpdateWidget(KeyFlowScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.region == null) _host?._regions.remove(this);
    if (widget.region != null) _host?._regions.add(this);
  }

  @override
  void dispose() {
    _host?._regions.remove(this);
    _node.dispose();
    super.dispose();
  }

  /// Moves the focus into this area: to the first control in it that takes
  /// focus, else to the area itself.
  void enter() {
    final first = _node.traversalDescendants.firstOrNull;
    (first ?? _node).requestFocus();
  }

  Rect? get _rect {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;
    if (widget.focusOnPointerDown) {
      child = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (!_node.hasFocus) _node.requestFocus();
        },
        child: child,
      );
    }
    child = Focus(focusNode: _node, includeSemantics: false, child: child);
    final region = widget.region;
    if (region != null) {
      child = Semantics(
        container: true,
        explicitChildNodes: true,
        label: region,
        child: child,
      );
    }
    return KeyLayerScope(commands: widget.commands, child: child);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Marks where a [KeyFlowScope]'s commands apply. [KeyTarget] and [KeyHint]
/// depend on it, so they rebuild when the commands change. Apps use
/// [KeyFlowScope], not this.
class KeyLayerScope extends InheritedWidget {
  /// The commands of the scope.
  final List<KeyNode> commands;

  const KeyLayerScope({
    super.key,
    required this.commands,
    required super.child,
  });

  @override
  bool updateShouldNotify(KeyLayerScope oldWidget) =>
      !identical(oldWidget.commands, commands);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Which of key_flow's panels is showing.
enum KeyFlowPanel {
  /// None.
  none,

  /// What to press next, while a group is open or keys are pending.
  prefix,

  /// The command palette.
  palette,

  /// The sheet of every shortcut.
  help,

  /// Letters on every control, to press one by typing them.
  jump,
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Reads and drives a [KeyFlow] from code: what can be done where the person
/// is, running a command by id (for an app's own AI, through
/// [KeyTree.toToolList] and [runTool]), opening panels and changing keys.
///
/// Listeners hear every change of [position], [panel] and [keyOverrides].
class KeyFlowController extends ChangeNotifier {
  _KeyFlowState? _host;

  /// Where the person is in the tree of commands.
  KeyPosition get position => _host?._matcher.position ?? KeyPosition.top;

  /// The panel showing now.
  KeyFlowPanel get panel => _host?._panel ?? KeyFlowPanel.none;

  /// The tree in force while a group is open or a panel shows: the one for
  /// where the person was when it opened.
  KeyTree? get openTree => _host?._openTree;

  /// The commands in force where the focus is now.
  KeyTree get currentTree {
    final host = _host;
    if (host == null) return KeyTree.empty;
    return host._openTree ??
        host._treeAt(FocusManager.instance.primaryFocus?.context);
  }

  /// The commands in force at [context].
  KeyTree treeAt(BuildContext context) =>
      _host?._treeAt(context) ?? KeyTree.empty;

  /// Keys a person chose instead of commands' own, by full id.
  Map<String, List<String>> get keyOverrides =>
      Map.unmodifiable(_host?._overrides ?? const <String, List<String>>{});

  /// The words key_flow's panels use.
  KeyFlowStrings get strings => _host?.widget.strings ?? const KeyFlowStrings();

  /// Whether linked controls give their shortcut as their accessibility
  /// value; see [KeyFlow.shortcutsInSemanticsValue].
  bool get shortcutsInSemanticsValue {
    return _host?.widget.shortcutsInSemanticsValue ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS);
  }

  /// Runs the command with this full id where the person is now, or opens
  /// the group with it.
  ///
  /// Completes when the command has finished. Throws an [ArgumentError] when
  /// nothing here has this id, and a [StateError] when the command cannot
  /// run now.
  Future<void> run(String id) async {
    final host = _requireHost();
    final item = currentTree.find(id);
    switch (item) {
      case null:
        throw ArgumentError.value(id, 'id', 'no command or group here');
      case KeyGroupEntry():
        host._openGroup(item, currentTree);
      case KeyCommandEntry() when !item.enabled:
        throw StateError('"$id" cannot run now');
      case KeyCommandEntry():
        host._closeAll();
        host.widget.onCommandRun?.call(item);
        await item.run(host.context);
    }
  }

  /// Runs the command a model called by a name from [KeyTree.toToolList].
  ///
  /// Throws an [ArgumentError] when no command has that name now.
  Future<void> runTool(String name) {
    final command = currentTree.commandForTool(name);
    if (command == null) {
      throw ArgumentError.value(name, 'name', 'no such tool here');
    }
    return run(command.id);
  }

  /// A callback that runs the command with this full id among those in force
  /// at [context], or null when it cannot run now: an `onPressed` that greys
  /// a button out along with its command.
  VoidCallback? callbackFor(BuildContext context, String id) {
    final command = treeAt(context).find(id);
    if (command is! KeyCommandEntry || !command.enabled) return null;
    return () => runEntry(command);
  }

  /// Opens the group with this full id, showing what to press next.
  void openGroup(String id) {
    final host = _requireHost();
    final tree = currentTree;
    final group = tree.find(id);
    if (group is! KeyGroupEntry) {
      throw ArgumentError.value(id, 'id', 'no group here');
    }
    host._openGroup(group, tree);
  }

  /// Shows the command palette.
  void showPalette() => _requireHost()._show(KeyFlowPanel.palette);

  /// Shows the sheet of every shortcut.
  void showHelp() => _requireHost()._show(KeyFlowPanel.help);

  /// Puts letters on every control on screen, to press one by typing them.
  void startJump() => _requireHost()._show(KeyFlowPanel.jump);

  /// Closes whatever is open and gives the focus back.
  void close() => _host?._closeAll();

  /// Changes the keys of the command or group with this full id; null gives
  /// it back its own. Reported through [KeyFlow.onKeyOverridesChanged].
  void setKeys(String id, List<String>? keys) {
    if (keys != null) {
      for (final spec in keys) {
        KeyBinding.parse(spec);
      }
    }
    _requireHost()._setKeys(id, keys);
  }

  /// Moves the focus to the next named [KeyFlowScope] area, or the previous
  /// one with [backwards].
  void moveToArea({bool backwards = false}) =>
      _requireHost()._moveToArea(backwards: backwards);

  /// The names of the areas on screen, in the order F6 visits them.
  List<String> get areas => [
    for (final scope in _host?._sortedRegions() ?? const <_KeyFlowScopeState>[])
      scope.widget.region!,
  ];

  /// Runs [command] from a panel or a linked control.
  @internal
  void runEntry(KeyCommandEntry command) => _host?._runFromKeys(command);

  /// Closes the open group and opens [group] instead, from a panel.
  @internal
  void openEntry(KeyGroupEntry group) {
    final host = _host;
    if (host == null) return;
    host._openGroup(group, host._openTree ?? currentTree);
  }

  /// Goes back a level from a panel, as Backspace does.
  @internal
  void back() => _host?._back();

  _KeyFlowState _requireHost() {
    final host = _host;
    if (host == null) {
      throw StateError('This KeyFlowController is not attached to a KeyFlow');
    }
    return host;
  }

  void _changed() => notifyListeners();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _KeyFlowData extends InheritedWidget {
  final KeyFlowController controller;
  final KeyFlowStyle? style;

  const _KeyFlowData({
    required this.controller,
    required this.style,
    required super.child,
  });

  @override
  bool updateShouldNotify(_KeyFlowData oldWidget) =>
      !identical(oldWidget.controller, controller) || oldWidget.style != style;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _KeyFlowState extends State<KeyFlow> {
  late KeyFlowController _controller;
  bool _ownsController = false;

  final _matcher = KeyMatcher();
  final _rootNode = FocusNode(debugLabel: 'KeyFlow', skipTraversal: true);
  final _panelNode = FocusNode(
    debugLabel: 'KeyFlow panel',
    skipTraversal: true,
  );
  final _regions = <_KeyFlowScopeState>{};

  KeyFlowPanel _panel = KeyFlowPanel.none;
  KeyTree? _openTree;
  FocusNode? _returnFocus;
  FocusNode? _lastReturnFocus;
  Timer? _timer;
  late Map<String, List<String>> _overrides;
  bool _focusCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _overrides = Map.of(widget.keyOverrides);
    _attach(widget.controller);
    FocusManager.instance.addListener(_keepFocusReachable);
    _keepFocusReachable();
    if (kDebugMode) _noteMacAccessibility();
  }

  static var _notedMacAccessibility = false;

  /// Flutter on macOS shows its controls to accessibility clients other than
  /// VoiceOver (agents, automation, Accessibility Inspector) only once the
  /// window says a screen reader started. Says how, once, in debug builds.
  void _noteMacAccessibility() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_notedMacAccessibility ||
          WidgetsBinding.instance.platformDispatcher.semanticsEnabled) {
        return;
      }
      _notedMacAccessibility = true;
      debugPrint(
        'key_flow: on macOS, agents and automation see no controls until the '
        'window turns accessibility on. Add to macos/Runner/'
        'MainFlutterWindow.swift, after RegisterGeneratedPlugins: '
        'DispatchQueue.main.async { NotificationCenter.default.post(name: '
        'NSNotification.Name("NSApplicationDidChangeAccessibilityEnhanced'
        'UserInterfaceNotification"), object: NSApp, userInfo: '
        '["AXEnhancedUserInterface": true]) }',
      );
    });
  }

  @override
  void didUpdateWidget(KeyFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _detach();
      _attach(widget.controller);
    }
    if (!mapEquals(widget.keyOverrides, oldWidget.keyOverrides)) {
      _overrides = Map.of(widget.keyOverrides);
    }
  }

  void _attach(KeyFlowController? given) {
    _ownsController = given == null;
    _controller = given ?? KeyFlowController();
    assert(
      _controller._host == null,
      'This KeyFlowController is already used by another KeyFlow',
    );
    _controller._host = this;
  }

  void _detach() {
    if (identical(_controller._host, this)) _controller._host = null;
    if (_ownsController) _controller.dispose();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepFocusReachable);
    _timer?.cancel();
    _detach();
    _rootNode.dispose();
    _panelNode.dispose();
    super.dispose();
  }

  // ── The tree ──────────────────────────────────────────────────────────────

  KeyTree _treeAt(BuildContext? from) {
    final scopes = <KeyLayer>[];
    if (from != null && from.mounted) {
      void visit(Element element) {
        final widget = element.widget;
        if (widget is KeyLayerScope) {
          scopes.add(KeyLayer(widget.commands, context: element));
        }
      }

      if (from is Element) visit(from);
      from.visitAncestorElements((element) {
        if (identical(element, context)) return false;
        visit(element);
        return true;
      });
    }
    final tree = KeyTree.merge([
      KeyLayer(_builtIns(), context: context),
      KeyLayer(widget.commands, context: context),
      ...scopes.reversed,
    ], keyOverrides: _overrides);
    if (kDebugMode) _reportMistakes(tree);
    return tree;
  }

  final _reported = <String>{};

  void _reportMistakes(KeyTree tree) {
    for (final conflict in tree.conflicts) {
      if (conflict.isOverride) continue;
      final text = conflict.toString();
      if (_reported.add(text)) debugPrint('key_flow: $text');
    }
  }

  List<KeyNode> _builtIns() {
    final b = widget.builtIns;
    if (!b.enabled) return const [];
    return [
      KeyGroup(
        id: 'keyflow',
        label: b.groupLabel,
        inMenuBar: b.inMenuBar,
        children: [
          KeyCommand(
            id: 'palette',
            label: b.paletteLabel,
            keys: b.paletteKeys,
            onRun: (_) => _show(KeyFlowPanel.palette),
            hiddenFrom: const {KeySurface.palette, KeySurface.agents},
          ),
          KeyCommand(
            id: 'help',
            label: b.helpLabel,
            keys: b.helpKeys,
            onRun: (_) => _show(KeyFlowPanel.help),
            hiddenFrom: const {KeySurface.agents},
          ),
          KeyCommand(
            id: 'jump',
            label: b.jumpLabel,
            keys: b.jumpKeys,
            onRun: (_) => _show(KeyFlowPanel.jump),
            hiddenFrom: const {KeySurface.agents},
          ),
          KeyCommand(
            id: 'next-area',
            label: b.nextAreaLabel,
            keys: b.nextAreaKeys,
            onRun: (_) => _moveToArea(),
          ),
          KeyCommand(
            id: 'previous-area',
            label: b.previousAreaLabel,
            keys: b.previousAreaKeys,
            onRun: (_) => _moveToArea(backwards: true),
          ),
        ],
      ),
    ];
  }

  // ── Keys ──────────────────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    // The palette, the help sheet and jump mode read their own keys.
    if (_panel == KeyFlowPanel.palette ||
        _panel == KeyFlowPanel.help ||
        _panel == KeyFlowPanel.jump) {
      return KeyEventResult.ignored;
    }
    final stroke = KeyStroke.fromEvent(event);
    if (stroke.isModifier) return KeyEventResult.ignored;
    final wasOpen = _matcher.position.isOpen;
    final tree = wasOpen
        ? (_openTree ?? KeyTree.empty)
        : _treeAt(FocusManager.instance.primaryFocus?.context);
    final match = _matcher.handle(
      stroke,
      tree,
      isRepeat: event is KeyRepeatEvent,
      inTextField: _isTyping(),
    );
    switch (match) {
      case KeyMatchIgnored():
        return KeyEventResult.ignored;
      case KeyMatchRun(:final command):
        _runFromKeys(command);
      case KeyMatchClosed():
        _closeAll();
      case KeyMatchOpened() || KeyMatchWaiting():
        if (!wasOpen) _openPanel(KeyFlowPanel.prefix, tree);
        _restartTimer();
        _changed();
    }
    return KeyEventResult.handled;
  }

  static bool _isTyping() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return false;
    if (focused.widget is EditableText) return true;
    return focused.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _restartTimer() {
    _timer?.cancel();
    final timeout = widget.prefixTimeout;
    if (timeout != null) _timer = Timer(timeout, _closeAll);
  }

  // ── Panels ────────────────────────────────────────────────────────────────

  /// Where the person was before a panel took the focus: a panel opened
  /// from another (help from the prefix panel) gives back the first one's.
  FocusNode? _personFocus() {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == _panelNode || focused == _rootNode) {
      return _returnFocus ?? _lastReturnFocus;
    }
    return focused;
  }

  void _openPanel(KeyFlowPanel panel, KeyTree tree) {
    if (_panel == KeyFlowPanel.none) _returnFocus = _personFocus();
    _openTree = tree;
    setState(() => _panel = panel);
    // The palette focuses its own search field.
    if (panel != KeyFlowPanel.palette) _panelNode.requestFocus();
  }

  void _show(KeyFlowPanel panel) {
    final tree = _openTree ?? _treeAt(_personFocus()?.context);
    _matcher.close();
    _timer?.cancel();
    _openPanel(panel, tree);
    _changed();
  }

  void _openGroup(KeyGroupEntry group, KeyTree tree) {
    _matcher.open(group);
    if (_panel != KeyFlowPanel.prefix) _openPanel(KeyFlowPanel.prefix, tree);
    _restartTimer();
    _changed();
  }

  void _back() {
    final match = _matcher.handle(
      const KeyStroke(
        logical: LogicalKeyboardKey.backspace,
        physical: PhysicalKeyboardKey.backspace,
      ),
      _openTree ?? KeyTree.empty,
    );
    if (match is KeyMatchClosed) {
      _closeAll();
    } else {
      _changed();
    }
  }

  void _closeAll() {
    _timer?.cancel();
    _matcher.close();
    final wasShowing = _panel != KeyFlowPanel.none;
    _openTree = null;
    if (mounted && wasShowing) setState(() => _panel = KeyFlowPanel.none);
    final back = _returnFocus;
    _returnFocus = null;
    if (back != null) _lastReturnFocus = back;
    if (wasShowing && back != null && back.context != null) {
      back.requestFocus();
    } else if (wasShowing) {
      _rootNode.requestFocus();
    }
    _changed();
  }

  void _runFromKeys(KeyCommandEntry command) {
    // Give the focus back first, so a command that moves the focus wins.
    _closeAll();
    if (!command.enabled) return;
    widget.onCommandRun?.call(command);
    Future<void>.sync(() => command.run(context)).catchError((
      Object error,
      StackTrace stack,
    ) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'key_flow',
          context: ErrorDescription('while running "${command.id}"'),
        ),
      );
    });
  }

  void _changed() => _controller._changed();

  // ── Keys a person chose ───────────────────────────────────────────────────

  void _setKeys(String id, List<String>? keys) {
    setState(() {
      if (keys == null) {
        _overrides.remove(id);
      } else {
        _overrides[id] = List.unmodifiable(keys);
      }
    });
    widget.onKeyOverridesChanged?.call(Map.unmodifiable(_overrides));
    _changed();
  }

  // ── Areas ─────────────────────────────────────────────────────────────────

  List<_KeyFlowScopeState> _sortedRegions() {
    final placed =
        [
          for (final scope in _regions)
            if (scope.mounted && scope._rect != null) (scope, scope._rect!),
        ]..sort((a, b) {
          final byTop = a.$2.top.compareTo(b.$2.top);
          return byTop != 0 ? byTop : a.$2.left.compareTo(b.$2.left);
        });
    return [for (final (scope, _) in placed) scope];
  }

  void _moveToArea({bool backwards = false}) {
    _closeAll();
    final regions = _sortedRegions();
    if (regions.isEmpty) return;
    final current = regions.indexWhere((scope) => scope._node.hasFocus);
    final step = backwards ? -1 : 1;
    final next = current < 0
        ? (backwards ? regions.length - 1 : 0)
        : (current + step) % regions.length;
    regions[next].enter();
  }

  // ── Focus ─────────────────────────────────────────────────────────────────

  /// Keys reach key_flow only from a focused widget inside it. When nothing
  /// is focused, focus key_flow itself, after any autofocus has had its turn.
  void _keepFocusReachable() {
    if (_focusCheckScheduled) return;
    _focusCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        _focusCheckScheduled = false;
        if (!mounted) return;
        final focused = FocusManager.instance.primaryFocus;
        if (focused == null || focused == FocusManager.instance.rootScope) {
          _rootNode.requestFocus();
        }
      });
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _KeyFlowData(
      controller: _controller,
      style: widget.style,
      child: Focus(
        focusNode: _rootNode,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: Stack(
          fit: StackFit.passthrough,
          alignment: Alignment.topLeft,
          children: [
            widget.child,
            Positioned(
              left: 0,
              top: 0,
              width: 0,
              height: 0,
              child: Focus(
                focusNode: _panelNode,
                includeSemantics: false,
                onKeyEvent: _onPanelKey,
                child: const SizedBox.shrink(),
              ),
            ),
            if (_panel != KeyFlowPanel.none)
              Positioned.fill(child: _buildPanel(context)),
          ],
        ),
      ),
    );
  }

  KeyEventResult _onPanelKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (_panel == KeyFlowPanel.help || _panel == KeyFlowPanel.jump) {
      return _panelKeys.call(event);
    }
    return KeyEventResult.ignored;
  }

  /// The key handler of the help sheet or jump mode while it shows.
  KeyEventResult Function(KeyEvent event) _panelKeys = (_) =>
      KeyEventResult.ignored;

  Widget _buildPanel(BuildContext context) {
    final controller = _controller;
    final tree = _openTree ?? KeyTree.empty;
    final panel = switch (_panel) {
      KeyFlowPanel.prefix => KeyPrefixPanel(controller: controller, tree: tree),
      KeyFlowPanel.palette => KeyCommandPalette(
        controller: controller,
        tree: tree,
      ),
      KeyFlowPanel.help => KeyHelpSheet(
        controller: controller,
        tree: tree,
        onKeysHandler: (handler) => _panelKeys = handler,
      ),
      KeyFlowPanel.jump => KeyJumpLayer(
        controller: controller,
        onKeysHandler: (handler) => _panelKeys = handler,
      ),
      KeyFlowPanel.none => const SizedBox.shrink(),
    };
    final builder = widget.panelBuilder;
    return builder == null ? panel : builder(context, _panel, panel);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The names and keys of the commands every [KeyFlow] adds, in a group with
/// the id `keyflow`. Set a key list to `const []` to give a command no keys,
/// or [enabled] to false to add none.
@immutable
class KeyFlowBuiltIns {
  /// Whether to add the commands at all.
  final bool enabled;

  /// The name of their group.
  final String groupLabel;

  /// Whether their group is a menu in the menu bar.
  final bool inMenuBar;

  /// The command palette's name.
  final String paletteLabel;

  /// The command palette's keys.
  final List<String> paletteKeys;

  /// The shortcut sheet's name.
  final String helpLabel;

  /// The shortcut sheet's keys.
  final List<String> helpKeys;

  /// Jump mode's name.
  final String jumpLabel;

  /// Jump mode's keys.
  final List<String> jumpKeys;

  /// The name of moving to the next area.
  final String nextAreaLabel;

  /// The keys that move to the next area.
  final List<String> nextAreaKeys;

  /// The name of moving to the previous area.
  final String previousAreaLabel;

  /// The keys that move to the previous area.
  final List<String> previousAreaKeys;

  const KeyFlowBuiltIns({
    this.enabled = true,
    this.groupLabel = 'Keyboard',
    this.inMenuBar = false,
    this.paletteLabel = 'Search commands',
    this.paletteKeys = const ['meta+k'],
    this.helpLabel = 'Keyboard shortcuts',
    this.helpKeys = const ['?', 'meta+/'],
    this.jumpLabel = 'Jump to a control',
    this.jumpKeys = const ['meta+j'],
    this.nextAreaLabel = 'Next area',
    this.nextAreaKeys = const ['f6'],
    this.previousAreaLabel = 'Previous area',
    this.previousAreaKeys = const ['shift+f6'],
  });
}

/// The words key_flow's panels use.
@immutable
class KeyFlowStrings {
  /// The palette's search field.
  final String searchHint;

  /// When nothing matches a search.
  final String noMatches;

  /// Below the panel of what to press next.
  final String prefixFooter;

  /// The shortcut sheet's title.
  final String helpTitle;

  /// Below the shortcut sheet.
  final String helpFooter;

  /// Shown while jump mode puts letters on controls.
  final String jumpFooter;

  /// After a command that cannot run now.
  final String unavailable;

  const KeyFlowStrings({
    this.searchHint = 'Search commands',
    this.noMatches = 'No commands match',
    this.prefixFooter = 'Esc to close · ⌫ to go back',
    this.helpTitle = 'Keyboard shortcuts',
    this.helpFooter = 'Esc to close',
    this.jumpFooter =
        'Type the letters on a control to press it · Esc to cancel',
    this.unavailable = 'not available now',
  });
}
