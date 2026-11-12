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

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The panel that lists what to press next while a group is open or keys are
/// pending, like this, after G:
///
/// ```text
/// ┌ Go to ───────────────┐
/// │ P   Projects       › │
/// │ S   Settings         │
/// └ Esc to close · ⌫ to go back
/// ```
///
/// Each line is also a button, read by screen readers and agents as its name
/// with its keys as the value.
class KeyPrefixPanel extends StatelessWidget {
  /// The controller of the [KeyFlow] showing it.
  final KeyFlowController controller;

  /// The tree the open group is in.
  final KeyTree tree;

  const KeyPrefixPanel({
    super.key,
    required this.controller,
    required this.tree,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final style = KeyFlowStyle.of(context);
        final position = controller.position;
        final next = position.nextIn(tree);
        final pending = position.pending.isEmpty
            ? null
            : position.pending.map(_strokeText).join(' ');
        final title = [
          ...position.path,
          if (pending != null) pending,
        ].join(' › ');
        return _Modal(
          onDismiss: controller.close,
          alignment: Alignment.bottomCenter,
          scrim: false,
          child: _Card(
            width: 560,
            semanticsLabel: title,
            liveRegion: true,
            footer: controller.strings.prefixFooter,
            title: title,
            child: Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Wrap(
                  children: [
                    for (final option in next)
                      _PrefixOption(
                        option: option,
                        onPressed: () => switch (option.item) {
                          KeyGroupEntry group => controller.openEntry(group),
                          KeyCommandEntry command => controller.runEntry(
                            command,
                          ),
                        },
                        style: style,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _strokeText(KeyStroke stroke) {
    final label = stroke.character ?? stroke.logical.keyLabel;
    return label.length == 1 ? label.toUpperCase() : label;
  }
}

class _PrefixOption extends StatelessWidget {
  final KeyNext option;
  final VoidCallback onPressed;
  final KeyFlowStyle style;

  const _PrefixOption({
    required this.option,
    required this.onPressed,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final item = option.item;
    final enabled = item is! KeyCommandEntry || item.enabled;
    final isGroup = item is KeyGroupEntry;
    return _Pressable(
      label: item.label,
      value: option.remaining.describe(),
      hint: item.description,
      enabled: enabled,
      onPressed: onPressed,
      child: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              KeyCaps(binding: option.remaining, dimmed: !enabled),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: style.textStyle.copyWith(
                    color: enabled ? style.onSurface : style.muted,
                  ),
                ),
              ),
              if (isGroup) Text('›', style: TextStyle(color: style.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The command palette: a search field over every command in force, with
/// where each sits and its keys. ↑ and ↓ choose, Enter runs, Escape closes.
class KeyCommandPalette extends StatefulWidget {
  /// The controller of the [KeyFlow] showing it.
  final KeyFlowController controller;

  /// The commands to search.
  final KeyTree tree;

  const KeyCommandPalette({
    super.key,
    required this.controller,
    required this.tree,
  });

  @override
  State<KeyCommandPalette> createState() => _KeyCommandPaletteState();
}

class _KeyCommandPaletteState extends State<KeyCommandPalette> {
  static const _rowHeight = 48.0;

  final _query = TextEditingController();
  final _field = FocusNode(debugLabel: 'KeyCommandPalette search');
  final _scroll = ScrollController();
  late List<KeyCommandEntry> _all;
  late List<KeyCommandEntry> _shown;
  var _selected = 0;

  @override
  void initState() {
    super.initState();
    final shown = [
      for (final command in widget.tree.commands)
        if (!command.isHiddenFrom(KeySurface.palette)) command,
    ];
    // The app's own commands first, key_flow's after them.
    bool builtIn(KeyCommandEntry command) => command.id.startsWith('keyflow.');
    _all = [
      ...shown.where((command) => !builtIn(command)),
      ...shown.where(builtIn),
    ];
    _shown = _all;
  }

  @override
  void dispose() {
    _query.dispose();
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _search(String text) {
    setState(() {
      _shown = searchCommands(_all, text);
      _selected = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _select(int index) {
    if (_shown.isEmpty) return;
    setState(() => _selected = index.clamp(0, _shown.length - 1));
    if (!_scroll.hasClients) return;
    final top = _selected * _rowHeight;
    final view = _scroll.position.viewportDimension;
    if (top < _scroll.offset) {
      _scroll.jumpTo(top);
    } else if (top + _rowHeight > _scroll.offset + view) {
      _scroll.jumpTo(top + _rowHeight - view);
    }
  }

  void _run(KeyCommandEntry command) {
    if (command.enabled) widget.controller.runEntry(command);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.controller.close();
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _select(_selected + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _select(_selected - 1);
    } else if (key == LogicalKeyboardKey.pageDown) {
      _select(_selected + 8);
    } else if (key == LogicalKeyboardKey.pageUp) {
      _select(_selected - 8);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_shown.isNotEmpty) _run(_shown[_selected]);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final style = KeyFlowStyle.of(context);
    final strings = widget.controller.strings;
    final screen = MediaQuery.sizeOf(context);
    final field = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Stack(
        children: [
          if (_query.text.isEmpty)
            Text(
              strings.searchHint,
              style: style.textStyle.copyWith(fontSize: 16, color: style.muted),
            ),
          Focus(
            onKeyEvent: _onKey,
            child: EditableText(
              controller: _query,
              focusNode: _field,
              autofocus: true,
              style: style.textStyle.copyWith(fontSize: 16),
              cursorColor: style.accent,
              backgroundCursorColor: style.muted,
              onChanged: _search,
            ),
          ),
        ],
      ),
    );
    final list = _shown.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.noMatches,
              style: style.textStyle.copyWith(color: style.muted),
            ),
          )
        : ListView.builder(
            controller: _scroll,
            shrinkWrap: true,
            itemExtent: _rowHeight,
            itemCount: _shown.length,
            itemBuilder: (context, index) => _PaletteRow(
              command: _shown[index],
              selected: index == _selected,
              style: style,
              unavailable: strings.unavailable,
              onPressed: () => _run(_shown[index]),
            ),
          );
    return _Modal(
      onDismiss: widget.controller.close,
      alignment: Alignment.topCenter,
      scrim: true,
      child: Padding(
        padding: EdgeInsets.only(top: math.min(96, screen.height * 0.1)),
        child: _Card(
          width: 640,
          semanticsLabel: strings.searchHint,
          child: Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field,
                Divider(height: 1, thickness: 1, color: style.border),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: screen.height * 0.6),
                    child: list,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  final KeyCommandEntry command;
  final bool selected;
  final KeyFlowStyle style;
  final String unavailable;
  final VoidCallback onPressed;

  const _PaletteRow({
    required this.command,
    required this.selected,
    required this.style,
    required this.unavailable,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final shortcut = command.fullBindings.firstOrNull;
    final where = command.path.length > 1
        ? command.path.sublist(0, command.path.length - 1).join(' › ')
        : null;
    final enabled = command.enabled;
    return _Pressable(
      label: command.path.join(' › '),
      value: shortcut?.describe(),
      hint: enabled ? command.description : unavailable,
      enabled: enabled,
      selected: selected,
      onPressed: onPressed,
      child: Container(
        color: selected ? style.accent.withValues(alpha: 0.14) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.label,
                    overflow: TextOverflow.ellipsis,
                    style: style.textStyle.copyWith(
                      color: enabled ? style.onSurface : style.muted,
                    ),
                  ),
                  if (where != null || !enabled)
                    Text(
                      [
                        if (where != null) where,
                        if (!enabled) unavailable,
                      ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: style.textStyle.copyWith(
                        color: style.muted,
                        fontSize: (style.textStyle.fontSize ?? 14) - 2,
                      ),
                    ),
                ],
              ),
            ),
            if (shortcut != null) KeyCaps(binding: shortcut, dimmed: !enabled),
          ],
        ),
      ),
    );
  }
}

/// The commands in [commands] that match [query], best first: every word of
/// the query must appear in the command's name, the groups it is in or its
/// description, and a match at the start of the name ranks highest.
List<KeyCommandEntry> searchCommands(
  List<KeyCommandEntry> commands,
  String query,
) {
  final words = query.toLowerCase().split(RegExp(r'\s+'))
    ..removeWhere((word) => word.isEmpty);
  if (words.isEmpty) return commands;
  final scored = <(int, int, KeyCommandEntry)>[];
  for (var i = 0; i < commands.length; i++) {
    final command = commands[i];
    final label = command.label.toLowerCase();
    final around = [
      ...command.path,
      command.description ?? '',
    ].join(' ').toLowerCase();
    var score = 0;
    for (final word in words) {
      if (label.startsWith(word)) {
        continue;
      } else if (label.contains(word)) {
        score += 1;
      } else if (around.contains(word)) {
        score += 3;
      } else {
        score = -1;
        break;
      }
    }
    if (score >= 0) scored.add((score, i, command));
  }
  scored.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  return [for (final (_, _, command) in scored) command];
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The sheet of every shortcut in force, grouped as the commands are. Escape,
/// `?` or ⌘/ closes it; ↑, ↓, Page Up and Page Down scroll it.
class KeyHelpSheet extends StatefulWidget {
  /// The controller of the [KeyFlow] showing it.
  final KeyFlowController controller;

  /// The commands to list.
  final KeyTree tree;

  /// Hands the [KeyFlow] the sheet's key handler.
  @internal
  final void Function(KeyEventResult Function(KeyEvent event) handler)?
  onKeysHandler;

  const KeyHelpSheet({
    super.key,
    required this.controller,
    required this.tree,
    this.onKeysHandler,
  });

  @override
  State<KeyHelpSheet> createState() => _KeyHelpSheetState();
}

class _KeyHelpSheetState extends State<KeyHelpSheet> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final stroke = KeyStroke.fromEvent(event);
    if (stroke.isModifier) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final page = _scroll.hasClients
        ? _scroll.position.viewportDimension * 0.9
        : 300.0;
    double? by;
    if (key == LogicalKeyboardKey.arrowDown) by = 40;
    if (key == LogicalKeyboardKey.arrowUp) by = -40;
    if (key == LogicalKeyboardKey.pageDown || key == LogicalKeyboardKey.space) {
      by = page;
    }
    if (key == LogicalKeyboardKey.pageUp) by = -page;
    if (by != null) {
      if (_scroll.hasClients) {
        final position = _scroll.position;
        _scroll.jumpTo(
          (position.pixels + by).clamp(0, position.maxScrollExtent),
        );
      }
      return KeyEventResult.handled;
    }
    final closes =
        key == LogicalKeyboardKey.escape ||
        stroke.character == '?' ||
        ((stroke.meta || stroke.control) && key == LogicalKeyboardKey.slash);
    if (closes) widget.controller.close();
    // The sheet is modal: no key reaches the app behind it.
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    widget.onKeysHandler?.call(_onKey);
    final style = KeyFlowStyle.of(context);
    final strings = widget.controller.strings;
    final screen = MediaQuery.sizeOf(context);
    final sections = helpSections(widget.tree);
    return _Modal(
      onDismiss: widget.controller.close,
      alignment: Alignment.center,
      scrim: true,
      child: _Card(
        width: 720,
        title: strings.helpTitle,
        semanticsLabel: strings.helpTitle,
        footer: strings.helpFooter,
        child: Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screen.height * 0.75),
            child: ListView(
              controller: _scroll,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Semantics(
                      header: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              section.title,
                              style: style.textStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (section.keys != null)
                            KeyCaps(binding: section.keys!),
                        ],
                      ),
                    ),
                  ),
                  for (final command in section.commands)
                    _HelpRow(
                      command: command,
                      style: style,
                      onPressed: () => widget.controller.runEntry(command),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  final KeyCommandEntry command;
  final KeyFlowStyle style;
  final VoidCallback onPressed;

  const _HelpRow({
    required this.command,
    required this.style,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bindings = command.fullBindings;
    return _Pressable(
      label: command.label,
      value: bindings.map((binding) => binding.describe()).join(' or '),
      hint: command.description,
      enabled: command.enabled,
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                command.label,
                style: style.textStyle.copyWith(
                  color: command.enabled ? style.onSurface : style.muted,
                ),
              ),
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final binding in bindings)
                  KeyCaps(binding: binding, dimmed: !command.enabled),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One heading of the shortcut sheet and the commands under it.
@immutable
final class KeyHelpSection {
  /// The heading: the group's path, or empty for commands at the top.
  final String title;

  /// The keys that open the group, if it has any.
  final KeyBinding? keys;

  /// The commands directly in the group that have keys.
  final List<KeyCommandEntry> commands;

  const KeyHelpSection._(this.title, this.keys, this.commands);
}

/// The headings of the shortcut sheet for [tree]: the commands at the top,
/// then each group, depth first, each with the commands directly in it that
/// have keys and are not hidden from the sheet.
List<KeyHelpSection> helpSections(KeyTree tree, {String topTitle = 'General'}) {
  final sections = <KeyHelpSection>[];
  void visit(KeyGroupEntry group) {
    if (group.isHiddenFrom(KeySurface.helpSheet)) return;
    final commands = [
      for (final child in group.children)
        if (child is KeyCommandEntry &&
            child.fullBindings.isNotEmpty &&
            !child.isHiddenFrom(KeySurface.helpSheet))
          child,
    ];
    if (commands.isNotEmpty) {
      sections.add(
        KeyHelpSection._(
          group.isRoot ? topTitle : group.path.join(' › '),
          group.isRoot ? null : group.fullBindings.firstOrNull,
          commands,
        ),
      );
    }
    for (final child in group.children) {
      if (child is KeyGroupEntry) visit(child);
    }
  }

  visit(tree.root);
  return sections;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Jump mode: two letters on every control on screen that can take the
/// focus. Typing a control's letters focuses it and presses it; a text field
/// is focused. Escape cancels; Backspace takes back a letter.
class KeyJumpLayer extends StatefulWidget {
  /// The controller of the [KeyFlow] showing it.
  final KeyFlowController controller;

  /// Hands the [KeyFlow] the layer's key handler.
  @internal
  final void Function(KeyEventResult Function(KeyEvent event) handler)?
  onKeysHandler;

  const KeyJumpLayer({super.key, required this.controller, this.onKeysHandler});

  @override
  State<KeyJumpLayer> createState() => _KeyJumpLayerState();
}

class _KeyJumpLayerState extends State<KeyJumpLayer> {
  static const _letters = 'asdfghjklqwertyuiopzxcvbnm';

  List<(FocusNode, Rect, String)> _targets = const [];
  var _typed = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _targets = _findTargets());
    });
  }

  List<(FocusNode, Rect, String)> _findTargets() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return const [];
    final bounds = Offset.zero & box.size;
    final found = <(FocusNode, Rect)>[];
    for (final node in FocusManager.instance.rootScope.traversalDescendants) {
      // A scope holds controls; it is not one.
      if (node is FocusScopeNode) continue;
      final target = node.context;
      if (target == null || !target.mounted) continue;
      if (target.findAncestorWidgetOfExactType<KeyJumpExclude>() != null) {
        continue;
      }
      final route = ModalRoute.of(target);
      if (route != null && !route.isCurrent) continue;
      final Rect rect;
      try {
        rect = node.rect;
      } catch (_) {
        continue;
      }
      final local = Rect.fromPoints(
        box.globalToLocal(rect.topLeft),
        box.globalToLocal(rect.bottomRight),
      );
      if (local.isEmpty || !bounds.overlaps(local)) continue;
      found.add((node, local));
    }
    found.sort((a, b) {
      final byTop = a.$2.top.compareTo(b.$2.top);
      return byTop != 0 ? byTop : a.$2.left.compareTo(b.$2.left);
    });
    final labels = jumpLabels(found.length, alphabet: _letters);
    return [
      for (var i = 0; i < found.length; i++)
        (found[i].$1, found[i].$2, labels[i]),
    ];
  }

  void _press(FocusNode node) {
    widget.controller.close();
    node.requestFocus();
    final target = node.context;
    if (target != null && target.mounted) {
      Actions.maybeInvoke<ActivateIntent>(target, const ActivateIntent());
    }
  }

  KeyEventResult _onKey(KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final stroke = KeyStroke.fromEvent(event);
    if (stroke.isModifier) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.controller.close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace) {
      if (_typed.isNotEmpty) {
        setState(() => _typed = _typed.substring(0, _typed.length - 1));
      }
      return KeyEventResult.handled;
    }
    final letter = (stroke.character ?? key.keyLabel).toLowerCase();
    if (letter.length != 1 || !_letters.contains(letter)) {
      return KeyEventResult.handled;
    }
    final typed = _typed + letter;
    final matching = [
      for (final target in _targets)
        if (target.$3.startsWith(typed)) target,
    ];
    if (matching.length == 1 && matching.single.$3 == typed) {
      _press(matching.single.$1);
    } else {
      setState(() => _typed = matching.isEmpty ? '' : typed);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    widget.onKeysHandler?.call(_onKey);
    final style = KeyFlowStyle.of(context);
    return _Modal(
      onDismiss: widget.controller.close,
      alignment: Alignment.bottomCenter,
      scrim: false,
      layer: [
        for (final (node, rect, letters) in _targets)
          if (letters.startsWith(_typed))
            Positioned(
              left: rect.left,
              top: rect.top,
              child: _Pressable(
                label: letters.toUpperCase(),
                enabled: true,
                onPressed: () => _press(node),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: style.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: letters
                                .substring(0, _typed.length)
                                .toUpperCase(),
                            style: TextStyle(
                              color: style.onAccent.withValues(alpha: 0.5),
                            ),
                          ),
                          TextSpan(
                            text: letters
                                .substring(_typed.length)
                                .toUpperCase(),
                          ),
                        ],
                      ),
                      style: style.textStyle.copyWith(
                        color: style.onAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: _Card(
          width: 480,
          semanticsLabel: widget.controller.strings.jumpFooter,
          liveRegion: true,
          footer: widget.controller.strings.jumpFooter,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Keeps the controls inside [child] out of jump mode. For controls only
/// the person should press, such as approving what an agent asks for: an
/// agent typing letters must not reach them. Tab still does, as it must for
/// a person without a mouse.
class KeyJumpExclude extends StatelessWidget {
  /// The controls to keep out.
  final Widget child;

  const KeyJumpExclude({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// [count] labels that no other label starts with: single letters while
/// they last, else pairs.
List<String> jumpLabels(int count, {String alphabet = 'asdfghjkl'}) {
  if (count <= alphabet.length) {
    return [for (var i = 0; i < count; i++) alphabet[i]];
  }
  final labels = <String>[];
  for (var i = 0; i < alphabet.length && labels.length < count; i++) {
    for (var j = 0; j < alphabet.length && labels.length < count; j++) {
      labels.add(alphabet[i] + alphabet[j]);
    }
  }
  return labels;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A layer over the app that closes when clicked outside [child].
class _Modal extends StatelessWidget {
  final VoidCallback onDismiss;
  final Alignment alignment;
  final bool scrim;
  final Widget child;
  final List<Widget> layer;

  const _Modal({
    required this.onDismiss,
    required this.alignment,
    required this.scrim,
    required this.child,
    this.layer = const [],
  });

  @override
  Widget build(BuildContext context) {
    final style = KeyFlowStyle.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: onDismiss,
            child: scrim ? ColoredBox(color: style.scrim) : null,
          ),
        ),
        ...layer,
        Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: alignment,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ],
    );
  }
}

/// A panel's card: a title, its content and a line of help below.
class _Card extends StatelessWidget {
  final double width;
  final String? title;
  final String? footer;
  final String semanticsLabel;
  final bool liveRegion;
  final Widget child;

  const _Card({
    required this.width,
    required this.semanticsLabel,
    required this.child,
    this.title,
    this.footer,
    this.liveRegion = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = KeyFlowStyle.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticsLabel,
      liveRegion: liveRegion,
      child: GestureDetector(
        // Clicks on the card stay on it.
        onTap: () {},
        excludeFromSemantics: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: DefaultTextStyle(
            style: style.textStyle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.surface,
                border: Border.all(color: style.border),
                borderRadius: BorderRadius.circular(style.radius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(style.radius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null && title!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          title!,
                          style: style.textStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    child,
                    if (footer != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                        child: Text(
                          footer!,
                          style: style.textStyle.copyWith(
                            color: style.muted,
                            fontSize: (style.textStyle.fontSize ?? 14) - 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Something in a panel that can be clicked, read by screen readers and
/// agents as a button with [label] and [value].
class _Pressable extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final bool enabled;
  final bool? selected;
  final VoidCallback onPressed;
  final Widget child;

  const _Pressable({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.child,
    this.value,
    this.hint,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      value: value == null || value!.isEmpty ? null : value,
      hint: hint,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled ? onPressed : null,
          child: child,
        ),
      ),
    );
  }
}
