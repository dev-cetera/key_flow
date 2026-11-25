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

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The commands one scope declares, and the context they run in.
final class KeyLayer {
  /// The commands, groups and dividers the scope declares.
  final List<KeyNode> nodes;

  /// Where they were declared: given to each command's [KeyCommand.onRun].
  final BuildContext? context;

  const KeyLayer(this.nodes, {this.context});
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The commands in force at one place in the app: every scope from the top of
/// the app down to that place, merged.
///
/// Built by [KeyTree.merge]; [KeyFlowController.currentTree] gives the one for
/// where the person is now.
final class KeyTree {
  /// The top of the tree: a group with no id, label or keys.
  final KeyGroupEntry root;

  /// Places where pressing the same keys could mean two things. Between
  /// scopes these are overrides and the nearer scope wins; within one scope
  /// they are mistakes, reported in debug builds.
  final List<KeyConflict> conflicts;

  KeyTree._(this.root, this.conflicts);

  /// Merges [layers], given from the outermost scope to the innermost.
  ///
  /// Groups with the same id merge; a command, or a group, replaces one with
  /// the same id from an outer layer. [keyOverrides] gives some full ids
  /// other keys than their own (see [KeyFlow.keyOverrides]).
  ///
  /// Throws an [ArgumentError] for an id that is empty or holds anything but
  /// letters, digits, `-` and `_`, and a [FormatException] for keys it cannot
  /// read, naming the command.
  factory KeyTree.merge(
    List<KeyLayer> layers, {
    Map<String, List<String>> keyOverrides = const {},
  }) {
    final top = _GroupDraft('');
    for (var i = 0; i < layers.length; i++) {
      for (final node in layers[i].nodes) {
        top.add(node, i, layers[i].context, '');
      }
    }
    final root = top.build(null, keyOverrides);
    return KeyTree._(root, _findConflicts(root));
  }

  /// A tree with nothing in it.
  static final empty = KeyTree.merge(const []);

  /// The command or group with this full id, such as `go.inbox`, if it is
  /// here.
  KeyItemEntry? find(String id) {
    KeyItemEntry? found;
    var group = root;
    final parts = id.split('.');
    for (var i = 0; i < parts.length; i++) {
      found = null;
      for (final child in group.children) {
        if (child is KeyItemEntry && child.localId == parts[i]) {
          found = child;
          break;
        }
      }
      if (found == null) return null;
      if (i < parts.length - 1) {
        if (found is! KeyGroupEntry) return null;
        group = found;
      }
    }
    return found;
  }

  /// Every command, depth first.
  Iterable<KeyCommandEntry> get commands => root.allCommands;

  /// Every command shown on [surface], as plain data an agent or an app's own
  /// AI can read: id, label, where it sits, its keys and whether it can run.
  ///
  /// Keys include those of the groups the command is in, so `keys` is what to
  /// press from the top: `["g p s"]`. `shortcuts` is the same, as a person
  /// would write it: `["G P S"]`.
  List<Map<String, Object?>> toCommandList({
    KeySurface surface = KeySurface.agents,
  }) {
    return [
      for (final command in commands)
        if (!command.isHiddenFrom(surface)) command.toJson(),
    ];
  }

  /// The commands an AI model may call now, as tool definitions: one per
  /// enabled command not hidden from [KeySurface.agents], each with a `name`,
  /// a `description` and JSON-schema `parameters` made from the command's
  /// [KeyCommand.params].
  ///
  /// Hand them to the model in its provider's shape, and run the one it calls
  /// with [KeyFlowController.runTool].
  List<Map<String, Object?>> toToolList() {
    return [
      for (final MapEntry(key: name, value: command) in _toolNames.entries)
        {
          'name': name,
          'description': command.toolDescription,
          'parameters': command.parametersSchema,
        },
    ];
  }

  /// The command [toToolList] named [name], if it is still here.
  KeyCommandEntry? commandForTool(String name) => _toolNames[name];

  late final Map<String, KeyCommandEntry> _toolNames = () {
    final names = <String, KeyCommandEntry>{};
    for (final command in commands) {
      if (!command.enabled || command.isHiddenFrom(KeySurface.agents)) {
        continue;
      }
      // Tool names allow letters, digits, "_" and "-", up to 64 characters.
      final base = command.id.replaceAll('.', '__');
      var name = base.length > 64 ? base.substring(0, 64) : base;
      for (var n = 2; names.containsKey(name); n++) {
        final suffix = '_$n';
        name =
            (base.length + suffix.length > 64
                ? base.substring(0, 64 - suffix.length)
                : base) +
            suffix;
      }
      names[name] = command;
    }
    return names;
  }();

  /// The whole tree as plain data, groups and dividers included.
  Map<String, Object?> toJson() => root.toJson();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// One item in a merged [KeyTree].
sealed class KeyEntry {
  /// The group this is in; null only for the root.
  final KeyGroupEntry? parent;

  /// Which scope it came from, counted from the outermost (0). A nearer
  /// scope's keys win over an outer one's.
  final int layer;

  KeyEntry._(this.parent, this.layer);
}

/// A line between items.
final class KeyDividerEntry extends KeyEntry {
  KeyDividerEntry._(super.parent, super.layer) : super._();
}

/// A command or a group in a merged [KeyTree].
sealed class KeyItemEntry extends KeyEntry {
  /// Its id among its siblings.
  final String localId;

  /// Its full id: the ids of the groups it is in and its own, joined with
  /// dots, such as `go.projects.settings`.
  final String id;

  /// Its keys, relative to the group it is in.
  final List<KeyBinding> bindings;

  /// The context of the scope that declared it.
  final BuildContext? context;

  final Set<KeySurface> _hiddenFrom;

  KeyItemEntry._(
    super.parent,
    super.layer, {
    required this.localId,
    required this.bindings,
    required this.context,
    required Set<KeySurface> hiddenFrom,
  }) : id = parent == null || parent.parent == null
           ? localId
           : '${parent.id}.$localId',
       _hiddenFrom = hiddenFrom,
       super._();

  /// What it is called.
  String get label;

  /// More about it, if given.
  String? get description;

  /// The labels of the groups it is in, then its own: what a person reads in
  /// a breadcrumb, "Go to › Projects › Settings".
  List<String> get path {
    final labels = <String>[label];
    for (var group = parent; group != null && group.parent != null;) {
      labels.add(group.label);
      group = group.parent;
    }
    return labels.reversed.toList();
  }

  /// Its keys from the top of the tree: the keys of each group it is in that
  /// has keys, then its own. Empty when it has no keys of its own.
  List<KeyBinding> get fullBindings {
    if (bindings.isEmpty) return const [];
    var result = bindings;
    for (var group = parent; group != null; group = group.parent) {
      if (group.bindings.isEmpty) continue;
      result = [
        for (final prefix in group.bindings)
          for (final binding in result) binding.after(prefix),
      ];
    }
    return result;
  }

  /// Whether it, or a group it is in, is left out of [surface].
  bool isHiddenFrom(KeySurface surface) {
    if (_hiddenFrom.contains(surface)) return true;
    return parent?.isHiddenFrom(surface) ?? false;
  }

  /// It as plain data.
  Map<String, Object?> toJson();
}

/// A command in a merged [KeyTree].
final class KeyCommandEntry extends KeyItemEntry {
  /// The command as its scope declared it.
  final KeyCommand command;

  KeyCommandEntry._(
    super.parent,
    super.layer, {
    required this.command,
    required super.bindings,
    required super.context,
  }) : super._(localId: command.id, hiddenFrom: command.hiddenFrom);

  @override
  String get label => command.label;

  @override
  String? get description => command.description;

  /// Whether it can run now.
  bool get enabled =>
      command.enabled &&
      (command.onRun != null || command.onRunWithArgs != null);

  /// The values it takes; see [KeyCommand.params].
  List<KeyParam> get params => command.params;

  /// Whether a switch is on; null for a command that is not a switch.
  bool? get checked => command.checked;

  /// Runs it with [args], in [fallback] when the scope that declared it is
  /// gone.
  ///
  /// Throws an [ArgumentError] when [args] do not fit its [params].
  FutureOr<void> run(
    BuildContext fallback, {
    Map<String, Object?> args = const {},
  }) {
    final checked = KeyArgs.check(command.params, args);
    final context = this.context;
    final into = context != null && context.mounted ? context : fallback;
    final onRunWithArgs = command.onRunWithArgs;
    if (onRunWithArgs != null) return onRunWithArgs(into, checked);
    return command.onRun?.call(into);
  }

  /// Its [params] as the JSON schema of a tool's parameters.
  Map<String, Object?> get parametersSchema {
    return {
      'type': 'object',
      'properties': {
        for (final param in params) param.name: param.toJsonSchema(),
      },
      if (params.any((param) => param.required))
        'required': [
          for (final param in params)
            if (param.required) param.name,
        ],
    };
  }

  /// How [KeyTree.toToolList] describes it to a model.
  String get toolDescription {
    final shortcuts = fullBindings.map((binding) => binding.describe());
    return [
      path.join(' › '),
      ?description,
      if (checked != null) checked! ? 'Currently on.' : 'Currently off.',
      if (shortcuts.isNotEmpty) 'Shortcut: ${shortcuts.join(' or ')}.',
    ].join('. ').replaceAll('..', '.');
  }

  @override
  Map<String, Object?> toJson() {
    final full = fullBindings;
    return {
      'kind': 'command',
      'id': id,
      'label': label,
      'path': path,
      if (description != null) 'description': description,
      'keys': [for (final binding in full) binding.toSpec()],
      'shortcuts': [for (final binding in full) binding.describe()],
      'enabled': enabled,
      if (checked != null) 'checked': checked,
      if (params.isNotEmpty)
        'params': [for (final param in params) param.toJson()],
    };
  }
}

/// A group in a merged [KeyTree].
final class KeyGroupEntry extends KeyItemEntry {
  @override
  final String label;

  @override
  final String? description;

  /// Whether it is a menu in the menu bar.
  final bool inMenuBar;

  final List<KeyEntry> _children = [];

  KeyGroupEntry._(
    super.parent,
    super.layer, {
    required super.localId,
    required this.label,
    required this.description,
    required this.inMenuBar,
    required super.bindings,
    required super.context,
    required super.hiddenFrom,
  }) : super._();

  /// What is in it, in order, with dividers.
  List<KeyEntry> get children => List.unmodifiable(_children);

  /// Whether this is the top of the tree.
  bool get isRoot => parent == null;

  /// What a person can press next once inside this group: the commands and
  /// groups in it that have keys, and those of any group in it that has none.
  Iterable<KeyItemEntry> get reachable sync* {
    for (final child in _children) {
      if (child is KeyGroupEntry && child.bindings.isEmpty) {
        yield* child.reachable;
      } else if (child is KeyItemEntry && child.bindings.isNotEmpty) {
        yield child;
      }
    }
  }

  /// Every command in it, at any depth.
  Iterable<KeyCommandEntry> get allCommands sync* {
    for (final child in _children) {
      switch (child) {
        case KeyCommandEntry():
          yield child;
        case KeyGroupEntry():
          yield* child.allCommands;
        case KeyDividerEntry():
          break;
      }
    }
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'kind': 'group',
      if (!isRoot) ...{
        'id': id,
        'label': label,
        if (description != null) 'description': description,
        'keys': [for (final binding in fullBindings) binding.toSpec()],
        'shortcuts': [for (final binding in fullBindings) binding.describe()],
        if (inMenuBar) 'inMenuBar': true,
      },
      'children': [
        for (final child in _children)
          switch (child) {
            KeyItemEntry() => child.toJson(),
            KeyDividerEntry() => const {'kind': 'divider'},
          },
      ],
    };
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Two items that the same keys could reach.
final class KeyConflict {
  /// The item that comes first in the tree.
  final KeyItemEntry first;

  /// The item that comes after it.
  final KeyItemEntry second;

  /// The overlapping keys of [first].
  final KeyBinding firstBinding;

  /// The overlapping keys of [second].
  final KeyBinding secondBinding;

  const KeyConflict._(
    this.first,
    this.second,
    this.firstBinding,
    this.secondBinding,
  );

  /// Whether the two come from different scopes, so the nearer one
  /// deliberately overrides the other where both apply.
  bool get isOverride => first.layer != second.layer;

  @override
  String toString() {
    return '"${first.id}" (${firstBinding.toSpec()}) and "${second.id}" '
        '(${secondBinding.toSpec()}) share keys';
  }
}

List<KeyConflict> _findConflicts(KeyGroupEntry root) {
  final conflicts = <KeyConflict>[];
  final levels = <KeyGroupEntry>[root];
  for (var i = 0; i < levels.length; i++) {
    final items = levels[i].reachable.toList();
    for (var a = 0; a < items.length; a++) {
      final first = items[a];
      if (first is KeyGroupEntry) levels.add(first);
      for (var b = a + 1; b < items.length; b++) {
        final second = items[b];
        for (final x in first.bindings) {
          for (final y in second.bindings) {
            if (x.overlaps(y)) {
              conflicts.add(KeyConflict._(first, second, x, y));
            }
          }
        }
      }
    }
  }
  return conflicts;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final _idPattern = RegExp(r'^[A-Za-z0-9_-]+$');

void _checkId(String id, String where) {
  if (!_idPattern.hasMatch(id)) {
    throw ArgumentError.value(
      id,
      'id',
      'at "${where.isEmpty ? '(top)' : where}": use letters, digits, '
          '"-" and "_" only',
    );
  }
}

final _paramNamePattern = RegExp(r'^[A-Za-z0-9_]+$');

void _checkCommand(KeyCommand command, String where) {
  final id = where.isEmpty ? command.id : '$where.${command.id}';
  if (command.onRun != null && command.onRunWithArgs != null) {
    throw ArgumentError.value(
      id,
      'id',
      'give onRun or onRunWithArgs, not both',
    );
  }
  if (command.params.isNotEmpty && command.onRun != null) {
    throw ArgumentError.value(
      id,
      'id',
      'a command with params runs through onRunWithArgs',
    );
  }
  final names = <String>{};
  for (final param in command.params) {
    if (!_paramNamePattern.hasMatch(param.name)) {
      throw ArgumentError.value(
        param.name,
        'params',
        'of "$id": use letters, digits and "_" only',
      );
    }
    if (!names.add(param.name)) {
      throw ArgumentError.value(param.name, 'params', 'of "$id": given twice');
    }
    if (param.choices.isNotEmpty && param.type != KeyParamType.string) {
      throw ArgumentError.value(
        param.name,
        'params',
        'of "$id": only a string param takes choices',
      );
    }
  }
}

List<KeyBinding> _parseKeys(List<String> keys, String id) {
  return [
    for (final spec in keys)
      () {
        try {
          return KeyBinding.parse(spec);
        } on FormatException catch (e) {
          throw FormatException('Keys of "$id": ${e.message}', e.source);
        }
      }(),
  ];
}

final class _GroupDraft {
  final String localId;
  String? label;
  String? description;
  List<String> keys = const [];
  int keysLayer = 0;
  int layer = 0;
  bool inMenuBar = false;
  final Set<KeySurface> hiddenFrom = {};
  BuildContext? context;
  final List<Object> items = [];
  final Map<String, int> byId = {};

  _GroupDraft(this.localId);

  void add(KeyNode node, int layer, BuildContext? context, String where) {
    switch (node) {
      case KeyDivider():
        items.add(_DividerDraft(layer));
      case KeyCommand():
        _checkId(node.id, where);
        _checkCommand(node, where);
        _put(node.id, _CommandDraft(node, layer, context));
      case KeyGroup():
        _checkId(node.id, where);
        final index = byId[node.id];
        final existing = index == null ? null : items[index];
        final group = existing is _GroupDraft ? existing : _GroupDraft(node.id);
        if (!identical(existing, group)) _put(node.id, group);
        if (node.label != null) {
          group.label = node.label;
          group.context = context;
          group.layer = layer;
        }
        if (node.description != null) group.description = node.description;
        if (node.keys.isNotEmpty) {
          group.keys = node.keys;
          group.keysLayer = layer;
        }
        group.inMenuBar = group.inMenuBar || node.inMenuBar;
        group.hiddenFrom.addAll(node.hiddenFrom);
        group.context ??= context;
        final inside = where.isEmpty ? node.id : '$where.${node.id}';
        for (final child in node.children) {
          group.add(child, layer, context, inside);
        }
    }
  }

  void _put(String id, Object draft) {
    final index = byId[id];
    if (index == null) {
      byId[id] = items.length;
      items.add(draft);
    } else {
      items[index] = draft;
    }
  }

  KeyGroupEntry build(
    KeyGroupEntry? parent,
    Map<String, List<String>> overrides,
  ) {
    final id = parent == null || parent.isRoot
        ? localId
        : '${parent.id}.$localId';
    final keys = overrides[id] ?? this.keys;
    final built = KeyGroupEntry._(
      parent,
      keys.isEmpty ? layer : keysLayer,
      localId: localId,
      label: label ?? localId,
      description: description,
      inMenuBar: inMenuBar,
      bindings: _parseKeys(keys, id),
      context: context,
      hiddenFrom: hiddenFrom,
    );
    for (final item in items) {
      final KeyEntry child;
      switch (item) {
        case _GroupDraft():
          child = item.build(built, overrides);
        case _CommandDraft(:final command, :final layer, :final context):
          final id = built.isRoot ? command.id : '${built.id}.${command.id}';
          child = KeyCommandEntry._(
            built,
            layer,
            command: command,
            bindings: _parseKeys(overrides[id] ?? command.keys, id),
            context: context,
          );
        case _DividerDraft(:final layer):
          child = KeyDividerEntry._(built, layer);
        default:
          throw StateError('Unknown draft $item');
      }
      // No divider first, last or twice in a row.
      if (child is KeyDividerEntry &&
          (built._children.isEmpty ||
              built._children.last is KeyDividerEntry)) {
        continue;
      }
      built._children.add(child);
    }
    while (built._children.isNotEmpty &&
        built._children.last is KeyDividerEntry) {
      built._children.removeLast();
    }
    return built;
  }
}

final class _CommandDraft {
  final KeyCommand command;
  final int layer;
  final BuildContext? context;
  const _CommandDraft(this.command, this.layer, this.context);
}

final class _DividerDraft {
  final int layer;
  const _DividerDraft(this.layer);
}
