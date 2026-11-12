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

import 'dart:ui' show Tristate;

// Material leaves Flutter's core for package:material_ui, which needs Flutter
// 3.47; this keeps key_flow working on 3.32 and later until it moves.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

import '../helpers.dart';

/// Presses keys written as text, such as `meta+k` or `g`, as a person would:
/// modifiers down, the key, modifiers up.
Future<void> press(WidgetTester tester, String spec) async {
  for (final step in KeyBinding.parse(spec).steps) {
    final apple = KeyActivator.isAppleHost;
    final modifiers = [
      if (step.meta && apple) LogicalKeyboardKey.metaLeft,
      if (step.control || (step.meta && !apple)) LogicalKeyboardKey.controlLeft,
      if (step.alt) LogicalKeyboardKey.altLeft,
      if (step.shift) LogicalKeyboardKey.shiftLeft,
    ];
    for (final modifier in modifiers) {
      await tester.sendKeyDownEvent(modifier);
    }
    final character = step.character;
    if (character != null) {
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.slash,
        character: character,
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.slash);
    } else {
      await tester.sendKeyEvent(step.logical!);
    }
    for (final modifier in modifiers.reversed) {
      await tester.sendKeyUpEvent(modifier);
    }
    await tester.pump();
  }
}

void main() {
  final ran = <String>[];
  setUp(ran.clear);
  tearDown(resetHardwareKeyboard);

  KeyCommand command(
    String id,
    String label,
    List<String> keys, {
    bool enabled = true,
    bool? checked,
    String? description,
  }) {
    return KeyCommand(
      id: id,
      label: label,
      keys: keys,
      enabled: enabled,
      checked: checked,
      description: description,
      onRun: (_) => ran.add(id),
    );
  }

  final appCommands = <KeyNode>[
    command('save', 'Save', ['meta+s']),
    KeyGroup(
      id: 'go',
      label: 'Go to',
      keys: ['g'],
      children: [
        command('inbox', 'Inbox', ['i']),
        KeyGroup(
          id: 'projects',
          label: 'Projects',
          keys: ['p'],
          children: [
            command('settings', 'Project settings', ['s']),
          ],
        ),
      ],
    ),
  ];

  Future<KeyFlowController> pumpApp(
    WidgetTester tester, {
    List<KeyNode>? commands,
    Widget body = const SizedBox.expand(),
    Duration? prefixTimeout,
    Map<String, List<String>> keyOverrides = const {},
    ValueChanged<Map<String, List<String>>>? onKeyOverridesChanged,
  }) async {
    final controller = KeyFlowController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeyFlow(
          commands: commands ?? appCommands,
          controller: controller,
          prefixTimeout: prefixTimeout,
          keyOverrides: keyOverrides,
          onKeyOverridesChanged: onKeyOverridesChanged,
          child: child!,
        ),
        home: Scaffold(body: body),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('keys', () {
    testWidgets('a shortcut runs its command with nothing focused', (
      tester,
    ) async {
      await pumpApp(tester);
      await press(tester, 'meta+s');
      expect(ran, ['save']);
    });

    testWidgets('G P S opens nested groups, shows the next keys, and runs', (
      tester,
    ) async {
      final controller = await pumpApp(tester);
      await press(tester, 'g');
      expect(controller.panel, KeyFlowPanel.prefix);
      expect(find.text('Go to'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('Projects'), findsOneWidget);

      // It waits: no timeout by default.
      await tester.pump(const Duration(minutes: 5));
      expect(controller.panel, KeyFlowPanel.prefix);

      await press(tester, 'p');
      expect(find.text('Go to › Projects'), findsOneWidget);
      expect(find.text('Project settings'), findsOneWidget);
      await press(tester, 's');
      await tester.pumpAndSettle();
      expect(ran, ['settings']);
      expect(controller.panel, KeyFlowPanel.none);
      expect(find.text('Inbox'), findsNothing);
    });

    testWidgets('Escape closes, Backspace goes back, a click runs', (
      tester,
    ) async {
      final controller = await pumpApp(tester);
      await press(tester, 'g');
      await press(tester, 'p');
      await press(tester, 'backspace');
      expect(find.text('Inbox'), findsOneWidget);
      await press(tester, 'escape');
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.none);

      await press(tester, 'g');
      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      expect(ran, ['inbox']);
    });

    testWidgets('a timeout closes a group when one is set', (tester) async {
      final controller = await pumpApp(
        tester,
        prefixTimeout: const Duration(seconds: 2),
      );
      await press(tester, 'g');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.none);
    });

    testWidgets('a text field keeps its keys; ⌘ shortcuts still work', (
      tester,
    ) async {
      await pumpApp(tester, body: const TextField(autofocus: true));
      await tester.pumpAndSettle();
      await press(tester, 'g');
      expect(find.text('Inbox'), findsNothing);
      await press(tester, 'meta+s');
      expect(ran, ['save']);
    });

    testWidgets('the scope around the focus adds and overrides commands', (
      tester,
    ) async {
      final left = FocusNode();
      final right = FocusNode();
      addTearDown(left.dispose);
      addTearDown(right.dispose);
      await pumpApp(
        tester,
        body: Row(
          children: [
            KeyFlowScope(
              region: 'Sidebar',
              commands: [
                command('new', 'New', ['meta+n']),
              ],
              child: TextButton(
                focusNode: left,
                onPressed: () {},
                child: const Text('L'),
              ),
            ),
            KeyFlowScope(
              region: 'Editor',
              commands: [
                command('run', 'Run', ['meta+r']),
                command('editor-save', 'Save draft', ['meta+s']),
              ],
              child: TextButton(
                focusNode: right,
                onPressed: () {},
                child: const Text('R'),
              ),
            ),
          ],
        ),
      );
      left.requestFocus();
      await tester.pump();
      await press(tester, 'meta+n');
      await press(tester, 'meta+r');
      await press(tester, 'meta+s');
      expect(ran, ['new', 'save']);

      ran.clear();
      right.requestFocus();
      await tester.pump();
      await press(tester, 'meta+n');
      await press(tester, 'meta+r');
      await press(tester, 'meta+s');
      expect(ran, ['run', 'editor-save']);
    });

    testWidgets('F6 moves between named areas', (tester) async {
      final left = FocusNode();
      final right = FocusNode();
      addTearDown(left.dispose);
      addTearDown(right.dispose);
      final controller = await pumpApp(
        tester,
        body: Row(
          children: [
            KeyFlowScope(
              region: 'Sidebar',
              child: TextButton(
                focusNode: left,
                onPressed: () {},
                child: const Text('L'),
              ),
            ),
            KeyFlowScope(
              region: 'Editor',
              child: TextButton(
                focusNode: right,
                onPressed: () {},
                child: const Text('R'),
              ),
            ),
          ],
        ),
      );
      expect(controller.areas, ['Sidebar', 'Editor']);
      await press(tester, 'f6');
      expect(left.hasFocus, isTrue);
      await press(tester, 'f6');
      expect(right.hasFocus, isTrue);
      await press(tester, 'shift+f6');
      expect(left.hasFocus, isTrue);
    });
  });

  group('panels', () {
    testWidgets('the palette finds a command by name and runs it', (
      tester,
    ) async {
      final controller = await pumpApp(tester);
      await press(tester, 'meta+k');
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.palette);
      await tester.enterText(find.byType(EditableText), 'proj sett');
      await tester.pump();
      expect(find.text('Project settings'), findsOneWidget);
      expect(find.text('Inbox'), findsNothing);
      await press(tester, 'enter');
      await tester.pumpAndSettle();
      expect(ran, ['settings']);
      expect(controller.panel, KeyFlowPanel.none);
    });

    testWidgets('↓ chooses the next match', (tester) async {
      await pumpApp(tester);
      await press(tester, 'meta+k');
      await tester.pumpAndSettle();
      // Both commands under "Go to" match, in tree order.
      await tester.enterText(find.byType(EditableText), 'go to');
      await tester.pump();
      await press(tester, 'down');
      await press(tester, 'enter');
      await tester.pumpAndSettle();
      expect(ran, ['settings']);
    });

    testWidgets('the help sheet lists shortcuts and closes with Escape', (
      tester,
    ) async {
      final controller = await pumpApp(tester);
      await press(tester, 'meta+/');
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.help);
      expect(find.text('Keyboard shortcuts'), findsWidgets);
      expect(find.text('Project settings'), findsOneWidget);
      await press(tester, 'escape');
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.none);
    });

    testWidgets('? opens the help sheet outside text fields', (tester) async {
      final controller = await pumpApp(tester);
      await press(tester, '?');
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.help);
    });

    testWidgets('jump mode presses a control by its letters', (tester) async {
      var pressed = '';
      await pumpApp(
        tester,
        body: Column(
          children: [
            TextButton(
              onPressed: () => pressed = 'first',
              child: const Text('First'),
            ),
            TextButton(
              onPressed: () => pressed = 'second',
              child: const Text('Second'),
            ),
          ],
        ),
      );
      await press(tester, 'meta+j');
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
      await press(tester, 's');
      await tester.pumpAndSettle();
      expect(pressed, 'second');
    });
  });

  testWidgets('jump mode skips controls kept out of it', (tester) async {
    var pressed = '';
    await pumpApp(
      tester,
      body: Column(
        children: [
          KeyJumpExclude(
            child: TextButton(
              onPressed: () => pressed = 'allow',
              child: const Text('Allow'),
            ),
          ),
          TextButton(
            onPressed: () => pressed = 'other',
            child: const Text('Other'),
          ),
        ],
      ),
    );
    await press(tester, 'meta+j');
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(
      find.text('S'),
      findsNothing,
      reason: 'only one control gets letters',
    );
    await press(tester, 'a');
    await tester.pumpAndSettle();
    expect(pressed, 'other');
  });

  group('controls and accessibility', () {
    testWidgets('KeyTarget is named, focusable and pressed with Enter', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        commands: [
          command('run', 'Run', ['meta+r'], description: 'Runs it'),
        ],
        body: const Center(
          child: KeyTarget(command: 'run', child: Text('▶')),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Run')),
        matchesSemantics(
          label: 'Run',
          hint: 'Runs it. Shortcut Ctrl+R',
          identifier: 'run',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await press(tester, 'enter');
      expect(ran, ['run']);
      handle.dispose();
    });

    testWidgets('on macOS the shortcut is also the value', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        commands: [
          command('run', 'Run', ['meta+r']),
        ],
        body: const Center(
          child: KeyTarget(command: 'run', child: Text('▶')),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel('Run'))
          .getSemanticsData();
      expect(data.label, 'Run');
      expect(data.value, '⌘R');
      handle.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a disabled command greys its control out', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        commands: [
          command('run', 'Run', ['meta+r'], enabled: false),
        ],
        body: const Center(
          child: KeyTarget(command: 'run', child: Text('▶')),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel('Run'))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      await tester.tap(find.byType(KeyTarget));
      expect(ran, isEmpty);
      handle.dispose();
    });

    testWidgets('KeyHint names an existing button', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        commands: [
          command('run', 'Run', ['meta+r']),
        ],
        body: Center(
          child: Builder(
            builder: (context) => KeyHint(
              command: 'run',
              child: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: KeyFlow.of(context).callbackFor(context, 'run'),
              ),
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(IconButton))
          .getSemanticsData();
      expect(data.label, 'Run');
      expect(data.identifier, 'run');
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(ran, ['run']);
      handle.dispose();
    });

    testWidgets('the audit finds a tappable control no keyboard reaches', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        commands: [
          command('run', 'Run', ['meta+r']),
        ],
        body: Column(
          children: [
            const KeyTarget(command: 'run', child: Text('▶')),
            GestureDetector(onTap: () {}, child: const Text('Mouse only')),
          ],
        ),
      );
      final view = tester.binding.renderViews.first;
      final root = view.owner!.semanticsOwner!.rootSemanticsNode!;
      final issues = findAccessibilityIssues(root);
      expect(issues, hasLength(1));
      expect(issues.single.name, 'Mouse only');
      expect(issues.single.problem, contains('keyboard'));
      handle.dispose();
    });
  });

  group('for code and agents', () {
    testWidgets('run, runTool and the lists agree', (tester) async {
      final controller = await pumpApp(
        tester,
        commands: [
          ...appCommands,
          command('later', 'Later', [], enabled: false),
        ],
      );
      await controller.run('go.inbox');
      expect(ran, ['inbox']);
      await controller.runTool('go__projects__settings');
      expect(ran, ['inbox', 'settings']);
      await expectLater(controller.run('nope'), throwsArgumentError);
      await expectLater(controller.run('later'), throwsStateError);

      final ids = controller.currentTree
          .toCommandList()
          .map((command) => command['id'])
          .toList();
      expect(ids, containsAll(['save', 'go.inbox', 'go.projects.settings']));
      expect(ids, isNot(contains('keyflow.palette')));
    });

    testWidgets('run opens a group by id', (tester) async {
      final controller = await pumpApp(tester);
      await controller.run('go');
      await tester.pumpAndSettle();
      expect(controller.panel, KeyFlowPanel.prefix);
      expect(find.text('Inbox'), findsOneWidget);
    });

    testWidgets('setKeys changes keys and reports them', (tester) async {
      Map<String, List<String>>? saved;
      final controller = await pumpApp(
        tester,
        onKeyOverridesChanged: (overrides) => saved = overrides,
      );
      controller.setKeys('go.inbox', ['n']);
      await tester.pump();
      expect(saved, {
        'go.inbox': ['n'],
      });
      await press(tester, 'g');
      await press(tester, 'n');
      expect(ran, ['inbox']);
      expect(
        () => controller.setKeys('go.inbox', ['hyper+x']),
        throwsFormatException,
      );
    });
  });
}
