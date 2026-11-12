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

import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

void _noop(BuildContext context) {}

KeyCommand command(
  String id, {
  String? label,
  List<String> keys = const [],
  bool enabled = true,
  bool? checked,
  Set<KeySurface> hiddenFrom = const {},
  String? description,
}) {
  return KeyCommand(
    id: id,
    label: label ?? id,
    keys: keys,
    onRun: _noop,
    enabled: enabled,
    checked: checked,
    hiddenFrom: hiddenFrom,
    description: description,
  );
}

void main() {
  final app = [
    command('palette', label: 'Search', keys: ['meta+k']),
    const KeyDivider(),
    KeyGroup(
      id: 'go',
      label: 'Go to',
      keys: ['g'],
      children: [
        command('inbox', label: 'Inbox', keys: ['i']),
        KeyGroup(
          id: 'projects',
          label: 'Projects',
          keys: ['p'],
          children: [
            command('settings', label: 'Settings', keys: ['s']),
          ],
        ),
      ],
    ),
    KeyGroup(
      id: 'file',
      label: 'File',
      inMenuBar: true,
      children: [
        command('open', label: 'Open…', keys: ['meta+o']),
        const KeyDivider(),
        const KeyDivider(),
        command('close', label: 'Close', keys: ['meta+w']),
        const KeyDivider(),
      ],
    ),
  ];

  group('merge', () {
    test('full ids join the groups they are in', () {
      final tree = KeyTree.merge([KeyLayer(app)]);
      expect(tree.find('go.projects.settings')?.label, 'Settings');
      expect(tree.find('file.open')?.label, 'Open…');
      expect(tree.find('go.nowhere'), isNull);
      expect(tree.find('palette.x'), isNull);
    });

    test('a keyed group puts its keys in front; a keyless one does not', () {
      final tree = KeyTree.merge([KeyLayer(app)]);
      final settings = tree.find('go.projects.settings')!;
      expect(settings.fullBindings.map((b) => b.toSpec()), ['g p s']);
      expect(settings.path, ['Go to', 'Projects', 'Settings']);
      final open = tree.find('file.open')!;
      expect(open.fullBindings.map((b) => b.toSpec()), ['meta+o']);
    });

    test('commands in a keyless group are reachable from the top', () {
      final tree = KeyTree.merge([KeyLayer(app)]);
      final top = tree.root.reachable.map((item) => item.id).toList();
      expect(top, containsAll(['palette', 'go', 'file.open', 'file.close']));
      expect(top, isNot(contains('go.inbox')));
    });

    test('dividers never lead, trail or double up', () {
      final tree = KeyTree.merge([KeyLayer(app)]);
      final file = tree.find('file')! as KeyGroupEntry;
      expect(file.children.map((child) => child.runtimeType.toString()), [
        'KeyCommandEntry',
        'KeyDividerEntry',
        'KeyCommandEntry',
      ]);
    });

    test('an inner scope adds to a group by id, and replaces by id', () {
      final inner = [
        KeyGroup(
          id: 'go',
          children: [
            command('inbox', label: 'Mail', keys: ['m']),
            command('drafts', label: 'Drafts', keys: ['d']),
          ],
        ),
      ];
      final tree = KeyTree.merge([KeyLayer(app), KeyLayer(inner)]);
      final go = tree.find('go')! as KeyGroupEntry;
      expect(
        go.label,
        'Go to',
        reason: 'a group without a label keeps its name',
      );
      expect(tree.find('go.inbox')!.label, 'Mail');
      expect(tree.find('go.inbox')!.fullBindings.single.toSpec(), 'g m');
      expect(tree.find('go.drafts'), isNotNull);
      expect(tree.find('go.projects.settings'), isNotNull);
      // Order: replaced items keep their place, new ones come last.
      expect(
        go.children.whereType<KeyItemEntry>().map((item) => item.localId),
        ['inbox', 'projects', 'drafts'],
      );
    });

    test('key overrides replace keys by full id', () {
      final tree = KeyTree.merge(
        [KeyLayer(app)],
        keyOverrides: {
          'go.inbox': ['n'],
          'go': ['meta+g'],
          'palette': [],
        },
      );
      expect(tree.find('go.inbox')!.fullBindings.single.toSpec(), 'meta+g n');
      expect(tree.find('palette')!.fullBindings, isEmpty);
    });

    test('bad ids and keys are refused, naming the command', () {
      expect(
        () => KeyTree.merge([
          KeyLayer([command('has.dot')]),
        ]),
        throwsArgumentError,
      );
      expect(
        () => KeyTree.merge([
          KeyLayer([
            KeyGroup(
              id: 'g',
              children: [
                command('x', keys: ['hyper+x']),
              ],
            ),
          ]),
        ]),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('"g.x"'),
          ),
        ),
      );
    });
  });

  group('conflicts', () {
    test('within one scope they are mistakes', () {
      final tree = KeyTree.merge([
        KeyLayer([
          command('a', keys: ['g']),
          KeyGroup(
            id: 'go',
            keys: ['g'],
            children: [
              command('b', keys: ['i']),
            ],
          ),
          command('c', keys: ['meta+k']),
        ]),
      ]);
      expect(tree.conflicts, hasLength(1));
      expect(tree.conflicts.single.isOverride, isFalse);
      expect(tree.conflicts.single.toString(), contains('"a"'));
    });

    test('between scopes they are overrides', () {
      final tree = KeyTree.merge([
        KeyLayer([
          command('outer', keys: ['meta+r']),
        ]),
        KeyLayer([
          command('inner', keys: ['meta+r']),
        ]),
      ]);
      expect(tree.conflicts.single.isOverride, isTrue);
    });
  });

  group('plain data for agents', () {
    test('toCommandList gives full keys, paths and state', () {
      final tree = KeyTree.merge([
        KeyLayer([
          ...app,
          command('mute', label: 'Mute', checked: true, keys: ['m']),
          command('later', enabled: false, description: 'Not yet'),
          command('secret', hiddenFrom: {KeySurface.agents}),
        ]),
      ]);
      final list = tree.toCommandList();
      final settings = list.firstWhere(
        (c) => c['id'] == 'go.projects.settings',
      );
      expect(settings['keys'], ['g p s']);
      expect(settings['path'], ['Go to', 'Projects', 'Settings']);
      expect(settings['enabled'], isTrue);
      expect(list.firstWhere((c) => c['id'] == 'mute')['checked'], isTrue);
      expect(list.firstWhere((c) => c['id'] == 'later')['enabled'], isFalse);
      expect(list.any((c) => c['id'] == 'secret'), isFalse);
    });

    test('toToolList names tools a model accepts, and maps them back', () {
      final tree = KeyTree.merge([
        KeyLayer([...app, command('later', enabled: false)]),
      ]);
      final tools = tree.toToolList();
      final names = tools.map((t) => t['name']! as String).toList();
      expect(names, contains('go__projects__settings'));
      expect(names, isNot(contains('later')), reason: 'only what can run now');
      for (final name in names) {
        expect(RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(name), isTrue);
      }
      final settings = tools.firstWhere(
        (t) => t['name'] == 'go__projects__settings',
      );
      expect(settings['description'], contains('Go to › Projects › Settings'));
      expect(settings['description'], contains('Shortcut: G P S'));
      expect(
        tree.commandForTool('go__projects__settings')!.id,
        'go.projects.settings',
      );
    });

    test('toJson keeps groups and dividers', () {
      final json = KeyTree.merge([KeyLayer(app)]).toJson();
      final children = json['children']! as List;
      expect(children.map((c) => (c as Map)['kind']), [
        'command',
        'divider',
        'group',
        'group',
      ]);
    });
  });
}
