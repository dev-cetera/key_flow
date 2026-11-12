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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

import '../helpers.dart';

void main() {
  final ran = <String>[];
  setUp(ran.clear);

  KeyCommand command(String id, List<String> keys, {bool enabled = true}) {
    return KeyCommand(
      id: id,
      label: id[0].toUpperCase() + id.substring(1),
      keys: keys,
      enabled: enabled,
      onRun: (_) => ran.add(id),
    );
  }

  final commands = <KeyNode>[
    KeyGroup(
      id: 'file',
      label: 'File',
      inMenuBar: true,
      children: [
        command('open', ['meta+o']),
        command('recent', ['g r']),
        const KeyDivider(),
        command('close', ['meta+w'], enabled: false),
        KeyGroup(
          id: 'export',
          label: 'Export',
          children: [
            command('pdf', ['meta+shift+e']),
          ],
        ),
      ],
    ),
    KeyGroup(id: 'hidden', label: 'Not a menu', children: [command('x', [])]),
  ];

  test('native menus: one per menu group, dividers as item groups', () {
    final tree = KeyTree.merge([KeyLayer(commands)]);
    final menus = platformMenusOf(tree, onSelected: (c) => ran.add(c.id));
    expect(menus, hasLength(1));
    final file = menus.single as PlatformMenu;
    expect(file.label, 'File');
    expect(file.menus, hasLength(2));
    final first = file.menus.first as PlatformMenuItemGroup;
    final open = first.members.first;
    expect(open.label, 'Open');
    expect(
      open.shortcut,
      isA<SingleActivator>().having(
        (s) => s.trigger,
        'trigger',
        LogicalKeyboardKey.keyO,
      ),
    );
    final recent = first.members[1];
    expect(
      recent.shortcut,
      isNull,
      reason: 'keys in a row cannot show natively',
    );
    final second = file.menus[1] as PlatformMenuItemGroup;
    expect(second.members.first.onSelected, isNull);
    expect((second.members[1] as PlatformMenu).label, 'Export');
    open.onSelected!();
    expect(ran, ['file.open']);
  });

  test('a ⌘ shortcut is Cmd on macOS and Ctrl elsewhere', () {
    final tree = KeyTree.merge([KeyLayer(commands)]);
    final open = tree.find('file.open')! as KeyCommandEntry;
    final mac =
        withPlatform(TargetPlatform.macOS, () => menuShortcutOf(open))!
            as SingleActivator;
    final windows =
        withPlatform(TargetPlatform.windows, () => menuShortcutOf(open))!
            as SingleActivator;
    expect(mac.meta, isTrue);
    expect(mac.control, isFalse);
    expect(windows.meta, isFalse);
    expect(windows.control, isTrue);
  });

  testWidgets('drawn menus where there is no native bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyFlow(
          commands: commands,
          child: KeyFlowMenuBar(drawOnOtherPlatforms: true, child: child!),
        ),
        home: const Scaffold(body: Text('Body')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(ran, ['open']);
    expect(find.text('Not a menu'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
}
