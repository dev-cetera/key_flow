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

import 'dart:ui' as ui;

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
  late Offset dragged;

  setUp(() {
    log = [];
    controller = KeyFlowController();
    text = TextEditingController();
    dragged = Offset.zero;
  });
  tearDown(resetHardwareKeyboard);

  Widget app({Widget? body}) {
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
        body:
            body ??
            Column(
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
                  child: SizedBox(
                    width: 300,
                    child: TextField(
                      controller: text,
                      onSubmitted: (value) => log.add('submitted $value'),
                    ),
                  ),
                ),
                for (var i = 0; i < 3; i++)
                  KeyAnchor(
                    id: 'row-$i',
                    child: Row(
                      children: [
                        Text('Row $i'),
                        KeyAnchor(
                          id: 'tick',
                          child: IconButton(
                            onPressed: () => log.add('tick $i'),
                            icon: const Icon(Icons.check),
                          ),
                        ),
                      ],
                    ),
                  ),
                KeyAnchor(
                  id: 'pad',
                  child: GestureDetector(
                    onPanUpdate: (details) => dragged += details.delta,
                    child: const ColoredBox(
                      color: Colors.blue,
                      child: SizedBox(width: 100, height: 60),
                    ),
                  ),
                ),
                const Offstage(
                  child: KeyAnchor(id: 'hidden', child: Text('Hidden')),
                ),
              ],
            ),
      ),
    );
  }

  KeyScript script(List<KeyStep> steps, {List<KeyCursor>? cursors}) {
    return KeyScript(
      steps: steps,
      cursors:
          cursors ?? const [KeyCursor(id: 'me', kind: KeyCursorKind.touch)],
      speed: 4,
    );
  }

  group('pressing for real', () {
    testWidgets('a tap on a KeyTarget runs its command', (tester) async {
      await tester.pumpWidget(app());
      final end = await playAll(
        tester,
        controller,
        script([const KeyStep.tap('save')]),
      );
      expect(end, KeyPlayEnd.finished);
      expect(log, ['save']);
      expect(controller.isPlaying, isFalse);
    });

    testWidgets('a tap and a hold reach an anchored button', (tester) async {
      await tester.pumpWidget(app());
      await playAll(
        tester,
        controller,
        script([const KeyStep.tap('button'), const KeyStep.hold('button')]),
      );
      expect(log, ['pressed', 'held']);
    });

    testWidgets('a tap waits for a sheet sliding up to settle', (tester) async {
      await tester.pumpWidget(
        app(
          body: Builder(
            builder: (context) => Center(
              child: KeyAnchor(
                id: 'open',
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => SizedBox(
                      height: 200,
                      child: Center(
                        child: KeyAnchor(
                          id: 'ok',
                          child: TextButton(
                            onPressed: () => log.add('ok'),
                            child: const Text('OK'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await playAll(
        tester,
        controller,
        script([const KeyStep.tap('open'), const KeyStep.tap('ok')]),
      );
      expect(log, ['ok']);
    });

    testWidgets('typing fills a field and submits it', (tester) async {
      await tester.pumpWidget(app());
      await playAll(
        tester,
        controller,
        script([const KeyStep.type('Milk 2', at: 'field', submit: true)]),
      );
      expect(text.text, 'Milk 2');
      expect(log, ['submitted Milk 2']);
    });

    Widget longList() {
      return app(
        body: KeyAnchor(
          id: 'rows',
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (context, i) => KeyAnchor(
              id: 'row-$i',
              child: ListTile(
                title: Text('Row $i'),
                onTap: () => log.add('row $i'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scrollTo swipes a list until a row not yet built shows', (
      tester,
    ) async {
      await tester.pumpWidget(longList());
      expect(() => controller.findSpot('row-80'), throwsStateError);
      await playAll(
        tester,
        controller,
        script([
          const KeyStep.scrollTo('row-80', within: 'rows'),
          const KeyStep.tap('row-80'),
        ]),
      );
      expect(log, ['row 80']);
    });

    testWidgets('scrollTo fails once the list is swiped through', (
      tester,
    ) async {
      await tester.pumpWidget(longList());
      await expectPlayFails(
        tester,
        controller,
        script([const KeyStep.scrollTo('row-999', within: 'rows')]),
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('did not show while scrolling'),
        ),
      );
    });

    testWidgets('a drag moves by what it is told', (tester) async {
      await tester.pumpWidget(app());
      await playAll(
        tester,
        controller,
        script([const KeyStep.drag('pad', by: Offset(80, 0))]),
      );
      expect(dragged.dx, closeTo(80, 20));
    });

    testWidgets('keys open a group and run a command in it', (tester) async {
      await tester.pumpWidget(app());
      await playAll(tester, controller, script([const KeyStep.keys('g i')]));
      expect(log, ['go.inbox']);
    });

    testWidgets('keys that do nothing here fail', (tester) async {
      await tester.pumpWidget(app());
      await expectPlayFails(
        tester,
        controller,
        script([const KeyStep.keys('meta+q')]),
        isStateError,
      );
    });

    testWidgets('a mouse cursor hovers what it passes over', (tester) async {
      var entered = false;
      await tester.pumpWidget(
        app(
          body: Center(
            child: KeyAnchor(
              id: 'hover',
              child: MouseRegion(
                onEnter: (_) => entered = true,
                child: const SizedBox(width: 80, height: 80),
              ),
            ),
          ),
        ),
      );
      await playAll(
        tester,
        controller,
        script(
          [const KeyStep.point('hover')],
          cursors: const [KeyCursor(id: 'me', kind: KeyCursorKind.mouse)],
        ),
      );
      expect(entered, isTrue);
    });

    testWidgets('a tap scrolls its anchor into view first', (tester) async {
      await tester.pumpWidget(
        app(
          body: ListView(
            children: [
              for (var i = 0; i < 40; i++)
                KeyAnchor(
                  id: 'item-$i',
                  child: ListTile(
                    title: Text('Item $i'),
                    onTap: () => log.add('item $i'),
                  ),
                ),
            ],
          ),
        ),
      );
      // Built by the list's cache, but off screen.
      await playAll(tester, controller, script([const KeyStep.tap('item-12')]));
      expect(log, ['item 12']);
    });
  });

  group('places', () {
    testWidgets('an anchor around names which of several', (tester) async {
      await tester.pumpWidget(app());
      await playAll(
        tester,
        controller,
        script([const KeyStep.tap('row-1/tick'), const KeyStep.tap('tick[2]')]),
      );
      expect(log, ['tick 1', 'tick 2']);
    });

    testWidgets('an id on screen more than once fails', (tester) async {
      await tester.pumpWidget(app());
      await expectPlayFails(
        tester,
        controller,
        script([const KeyStep.tap('tick')]),
        allOf(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('names 3 things'),
          ),
        ),
      );
      expect(controller.isPlaying, isFalse);
    });

    testWidgets('an anchor not drawn is not on screen', (tester) async {
      await tester.pumpWidget(app());
      expect(
        controller.spots.map((spot) => spot.place),
        isNot(contains('hidden')),
      );
      expect(() => controller.findSpot('hidden'), throwsStateError);
    });

    testWidgets('spots list what is on screen for an agent', (tester) async {
      await tester.pumpWidget(app());
      final places = controller.spots.map((spot) => spot.place).toList();
      expect(places.first, 'save');
      expect(places, containsAll(['row-0', 'row-0/tick', 'pad', 'field']));
      final save = controller.findSpot('save').toJson();
      expect(save['label'], 'Save');
      expect(save['reachable'], isTrue);
    });

    testWidgets('a tap on something covered fails', (tester) async {
      await tester.pumpWidget(
        app(
          body: Stack(
            children: [
              KeyAnchor(
                id: 'under',
                child: TextButton(
                  onPressed: () => log.add('under'),
                  child: const Text('Under'),
                ),
              ),
              const Positioned.fill(child: ModalBarrier(dismissible: false)),
            ],
          ),
        ),
      );
      await expectPlayFails(
        tester,
        controller,
        script([const KeyStep.tap('under')]),
        allOf(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('covered'),
          ),
        ),
      );
      expect(log, isEmpty);
    });

    testWidgets('waitFor waits for an anchor, then gives up', (tester) async {
      await tester.pumpWidget(app());
      await playAll(tester, controller, script([const KeyStep.waitFor('pad')]));
      await expectPlayFails(
        tester,
        controller,
        script([
          const KeyStep.waitFor(
            'nowhere',
            timeout: Duration(milliseconds: 300),
          ),
        ]),
        isStateError,
      );
    });
  });

  group('commands', () {
    testWidgets('run taps the control of a command on screen', (tester) async {
      await tester.pumpWidget(app());
      await playAll(tester, controller, script([const KeyStep.run('save')]));
      expect(log, ['save']);
    });

    testWidgets('run gives a command its args', (tester) async {
      await tester.pumpWidget(app());
      await playAll(
        tester,
        controller,
        script([
          const KeyStep.run('add', args: {'text': 'Milk'}),
        ]),
      );
      expect(log, ['add Milk']);
    });

    testWidgets('run checks args before anything changes', (tester) async {
      await tester.pumpWidget(app());
      await expectLater(
        controller.run('add', args: {'text': 3}),
        throwsArgumentError,
      );
      await expectLater(controller.run('add'), throwsArgumentError);
      expect(log, isEmpty);
    });

    testWidgets('runTool passes args', (tester) async {
      await tester.pumpWidget(app());
      await controller.runTool('add', args: {'text': 'Eggs'});
      expect(log, ['add Eggs']);
    });
  });

  group('the show', () {
    testWidgets('shows cursors with names and captions while it plays', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      var sawLabels = false;
      var sawCaption = false;
      await playAll(
        tester,
        controller,
        script(
          [
            const KeyStep.caption('Two people at once'),
            const KeyStep.together([
              KeyStep.point('pad', cursor: 'ana'),
              KeyStep.point('field', cursor: 'ben'),
            ]),
          ],
          cursors: const [
            KeyCursor(id: 'ana', kind: KeyCursorKind.touch, label: 'Ana'),
            KeyCursor(id: 'ben', kind: KeyCursorKind.mouse, label: 'Ben'),
          ],
        ),
        meanwhile: () async {
          sawLabels =
              find.text('Ana').evaluate().isNotEmpty &&
              find.text('Ben').evaluate().isNotEmpty;
          sawCaption = find.text('Two people at once').evaluate().isNotEmpty;
        },
        meanwhileAtFrame: 30,
      );
      expect(sawLabels, isTrue);
      expect(sawCaption, isTrue);
      await tester.pump();
      expect(find.text('Ana'), findsNothing);
      expect(find.text('Two people at once'), findsNothing);
    });

    testWidgets('one cursor twice in a together step fails', (tester) async {
      await tester.pumpWidget(app());
      await expectPlayFails(
        tester,
        controller,
        script([
          const KeyStep.together([KeyStep.tap('save'), KeyStep.tap('pad')]),
        ]),
        isArgumentError,
      );
    });

    testWidgets('a step naming a cursor the script lacks fails', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      await expectPlayFails(
        tester,
        controller,
        script([const KeyStep.tap('save', cursor: 'nobody')]),
        isArgumentError,
      );
    });

    testWidgets('stopPlaying stops it', (tester) async {
      await tester.pumpWidget(app());
      final end = await playAll(
        tester,
        controller,
        script([const KeyStep.wait(Duration(seconds: 30))]),
        meanwhile: () async => controller.stopPlaying(),
      );
      expect(end, KeyPlayEnd.stopped);
      expect(controller.isPlaying, isFalse);
    });

    testWidgets('Escape stops it', (tester) async {
      await tester.pumpWidget(app());
      final end = await playAll(
        tester,
        controller,
        script([const KeyStep.wait(Duration(seconds: 30))]),
        meanwhile: () => tester.sendKeyEvent(LogicalKeyboardKey.escape),
      );
      expect(end, KeyPlayEnd.stopped);
    });

    testWidgets('a press of the person\'s own stops it, or is dropped', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      void personPresses() {
        tester.binding.platformDispatcher.onPointerDataPacket!(
          const ui.PointerDataPacket(
            data: [ui.PointerData(change: ui.PointerChange.down)],
          ),
        );
      }

      final stopped = await playAll(
        tester,
        controller,
        script([const KeyStep.wait(Duration(seconds: 2))]),
        meanwhile: () async => personPresses(),
      );
      expect(stopped, KeyPlayEnd.stopped);

      final finished = await playAll(
        tester,
        controller,
        script([const KeyStep.wait(Duration(seconds: 2))]),
        personPress: KeyPersonPress.ignored,
        meanwhile: () async => personPresses(),
      );
      expect(finished, KeyPlayEnd.finished);
    });

    testWidgets('taking the KeyFlow away mid-script stops it cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(app());
      final end = await playAll(
        tester,
        controller,
        script([const KeyStep.wait(Duration(seconds: 30))]),
        meanwhile: () => tester.pumpWidget(const SizedBox()),
      );
      expect(end, KeyPlayEnd.stopped);
    });

    testWidgets('a second play while one plays fails', (tester) async {
      await tester.pumpWidget(app());
      await playAll(
        tester,
        controller,
        script([const KeyStep.wait(Duration(seconds: 1))]),
        meanwhile: () async {
          expect(() => controller.play(script(const [])), throwsStateError);
        },
      );
    });
  });
}
