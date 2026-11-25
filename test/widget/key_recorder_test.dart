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

// Material leaves Flutter's core for package:material_ui, which needs Flutter
// 3.47; this keeps key_flow working on 3.32 and later until it moves.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

import '../helpers.dart';

void main() {
  late List<String> log;
  late KeyFlowController controller;
  late TextEditingController text;

  setUp(() {
    log = [];
    controller = KeyFlowController();
    text = TextEditingController();
  });
  tearDown(resetHardwareKeyboard);

  Widget app() {
    return MaterialApp(
      builder: (context, child) => KeyFlow(
        controller: controller,
        commands: [
          KeyCommand(
            id: 'save',
            label: 'Save',
            keys: const ['meta+s'],
            onRun: (_) => log.add('save'),
          ),
          KeyCommand(
            id: 'add',
            label: 'Add',
            params: const [KeyParam(name: 'text')],
            onRunWithArgs: (_, args) => log.add('add ${args.string('text')}'),
          ),
          KeyCommand(
            id: 'stop-recording',
            label: 'Stop recording',
            keys: const ['meta+shift+r'],
            onRun: (_) => controller.stopRecording(),
          ),
          KeyGroup(
            id: 'go',
            label: 'Go to',
            keys: const ['g'],
            children: [
              KeyCommand(
                id: 'inbox',
                label: 'Inbox',
                keys: const ['i'],
                onRun: (_) => log.add('go.inbox'),
              ),
            ],
          ),
        ],
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KeyTarget(
                command: 'save',
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Save it'),
                ),
              ),
              KeyAnchor(
                id: 'button',
                child: ElevatedButton(
                  onPressed: () => log.add('pressed'),
                  onLongPress: () => log.add('held'),
                  child: const Text('Button'),
                ),
              ),
              KeyAnchor(
                id: 'field',
                child: SizedBox(width: 300, child: TextField(controller: text)),
              ),
              for (var i = 0; i < 2; i++)
                KeyAnchor(
                  id: 'row-$i',
                  child: Row(
                    children: [
                      Text('Row $i'),
                      KeyAnchor(
                        id: 'tick',
                        child: IconButton(
                          onPressed: () => log.add('tick $i'),
                          icon: Icon(Icons.check, semanticLabel: 'tick $i'),
                        ),
                      ),
                    ],
                  ),
                ),
              KeyAnchor(
                id: 'stop',
                child: TextButton(
                  onPressed: () => controller.stopRecording(),
                  child: const Text('Stop'),
                ),
              ),
              // Not an anchor: a press on it records as a miss, and the
              // command it runs as a run step.
              TextButton(
                onPressed: KeyFlow.of(context).callbackFor(context, 'save'),
                child: const Text('Unnamed save'),
              ),
              Expanded(
                child: KeyAnchor(
                  id: 'rows',
                  child: ListView.builder(
                    itemCount: 100,
                    itemBuilder: (context, i) => KeyAnchor(
                      id: 'item-$i',
                      child: ListTile(
                        title: Text('Item $i'),
                        onTap: () => log.add('item $i'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, Object?>> stepsOf(KeyRecording recording) {
    return [for (final step in recording.steps) step.toJson()];
  }

  group('recording', () {
    testWidgets('a tap, a hold and a drag on anchors', (tester) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.text('Button'));
      await tester.longPress(find.text('Button'));
      await tester.drag(find.text('Button'), const Offset(0, 40));
      await tester.pumpAndSettle();
      controller.stopRecording();
      expect(stepsOf(recording), [
        {'do': 'tap', 'at': 'button', 'cursor': 'you'},
        // tester.longPress holds for kLongPressTimeout + kPressTimeout.
        {'do': 'hold', 'at': 'button', 'ms': 600, 'cursor': 'you'},
        {
          'do': 'drag',
          'at': 'button',
          'by': [0.0, 40.0],
          'cursor': 'you',
        },
      ]);
      expect(recording.toScript().cursors.single.kind, KeyCursorKind.touch);
      expect(recording.misses, isEmpty);
      expect(recording.isRecording, isFalse);
    });

    testWidgets('names an anchor shown twice by the one around it', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.bySemanticsLabel('tick 1'));
      await tester.pump();
      controller.stopRecording();
      expect(stepsOf(recording), [
        {'do': 'tap', 'at': 'row-1/tick', 'cursor': 'you'},
      ]);
    });

    testWidgets('a tap on a KeyTarget records the tap, not a run as well', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.text('Save it'));
      await tester.pump();
      controller.stopRecording();
      expect(log, ['save']);
      expect(stepsOf(recording), [
        {'do': 'tap', 'at': 'save', 'cursor': 'you'},
      ]);
    });

    testWidgets('a press inside no anchor is a miss; its command a run', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.text('Unnamed save'));
      await tester.pump();
      controller.stopRecording();
      expect(log, ['save']);
      expect(stepsOf(recording), [
        {'do': 'run', 'command': 'save'},
      ]);
      expect(recording.misses.single.reason, contains('inside no KeyAnchor'));
      expect(recording.misses.single.position, isNotNull);
    });

    testWidgets('keys key_flow handles, a sequence as one step', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      // Ctrl on the test's Android host: key_flow's "meta" there.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      controller.stopRecording();
      expect(log, ['go.inbox', 'save']);
      expect(stepsOf(recording), [
        {'do': 'keys', 'keys': 'g i'},
        {'do': 'keys', 'keys': 'meta+s'},
      ]);
    });

    testWidgets('typing into a field, with Enter as a submit', (tester) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      controller.stopRecording();
      expect(stepsOf(recording), [
        {'do': 'tap', 'at': 'field', 'cursor': 'you'},
        {'do': 'type', 'text': 'Milk', 'submit': true},
      ]);
    });

    testWidgets('a field emptied as it is submitted keeps what was typed', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Hi');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      text.clear();
      await tester.enterText(find.byType(TextField), 'Again');
      await tester.pump();
      controller.stopRecording();
      expect(stepsOf(recording), [
        {'do': 'tap', 'at': 'field', 'cursor': 'you'},
        {'do': 'type', 'text': 'Hi', 'submit': true},
        {'do': 'type', 'text': 'Again'},
      ]);
    });

    testWidgets('commands run from code, with their args, and notes', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      recording.note('Add some milk');
      await controller.run('add', args: {'text': 'Milk'});
      await controller.runTool('save');
      controller.stopRecording();
      expect(stepsOf(recording), [
        {'do': 'caption', 'text': 'Add some milk'},
        {
          'do': 'run',
          'command': 'add',
          'args': {'text': 'Milk'},
        },
        {'do': 'run', 'command': 'save'},
      ]);
    });

    testWidgets('a scrolled list gets a scrollTo before the press', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.drag(find.text('Item 2'), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Item 14'));
      await tester.pump();
      controller.stopRecording();
      final steps = stepsOf(recording);
      // The drag started on a list at its start: no scrollTo before it.
      expect(steps[0], containsPair('do', 'drag'));
      expect(steps.sublist(1), [
        {'do': 'scrollTo', 'at': 'item-14', 'within': 'rows', 'cursor': 'you'},
        {'do': 'tap', 'at': 'item-14', 'cursor': 'you'},
      ]);
    });

    testWidgets('steps a script plays go in as they are, its presses not', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await playAll(
        tester,
        controller,
        const KeyScript(
          cursors: [KeyCursor(id: 'ana', kind: KeyCursorKind.mouse)],
          speed: 4,
          steps: [
            KeyStep.caption('Watch'),
            KeyStep.tap('button'),
            KeyStep.keys('g i'),
            KeyStep.type('Eggs', at: 'field'),
            KeyStep.run('add', args: {'text': 'Tea'}),
          ],
        ),
      );
      controller.stopRecording();
      expect(log, ['pressed', 'go.inbox', 'add Tea']);
      expect(stepsOf(recording), [
        {'do': 'caption', 'text': 'Watch'},
        {'do': 'tap', 'at': 'button', 'cursor': 'ana'},
        {'do': 'keys', 'keys': 'g i'},
        {'do': 'type', 'text': 'Eggs', 'at': 'field', 'cursor': 'ana'},
        {
          'do': 'run',
          'command': 'add',
          'args': {'text': 'Tea'},
          'cursor': 'ana',
        },
      ]);
      expect(recording.toScript().cursors.single.id, 'ana');
    });

    testWidgets('a recording plays back what was recorded', (tester) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.text('Button'));
      await tester.tap(find.bySemanticsLabel('tick 0'));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.pump();
      controller.stopRecording();
      final json = recording.toJson();
      expect(json['misses'], isEmpty);
      final script = KeyScript.fromJson(
        json['script']! as Map<String, Object?>,
      );
      log.clear();
      text.clear();
      await tester.pump();
      final end = await playAll(tester, controller, script);
      expect(end, KeyPlayEnd.finished);
      expect(log, ['pressed', 'tick 0']);
      expect(text.text, 'Milk');
    });

    testWidgets('the press that stops it is left out', (tester) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.tap(find.text('Button'));
      await tester.tap(find.text('Stop'));
      await tester.pump();
      expect(recording.isRecording, isFalse);
      expect(stepsOf(recording), [
        {'do': 'tap', 'at': 'button', 'cursor': 'you'},
      ]);
    });

    testWidgets('the keys that stop it are left out', (tester) async {
      await tester.pumpWidget(app());
      final recording = controller.startRecording();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(recording.isRecording, isFalse);
      expect(stepsOf(recording), [
        {'do': 'keys', 'keys': 'g i'},
      ]);
    });

    testWidgets('shows a badge while recording', (tester) async {
      await tester.pumpWidget(app());
      controller.startRecording();
      await tester.pump();
      expect(find.text('Recording'), findsOneWidget);
      controller.stopRecording();
      await tester.pump();
      expect(find.text('Recording'), findsNothing);
    });

    testWidgets('one recording at a time, and none after it ends', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      expect(controller.stopRecording, throwsStateError);
      final recording = controller.startRecording();
      expect(controller.recording, same(recording));
      expect(controller.startRecording, throwsStateError);
      controller.stopRecording();
      expect(controller.recording, isNull);
      expect(() => recording.note('late'), throwsStateError);
    });
  });
}
