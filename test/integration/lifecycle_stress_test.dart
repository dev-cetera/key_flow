//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by Steve Morin & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Lifecycle and stress tests — dispose mid-sequence, rapid input, large
// mapping sets, dynamic mutations during dispatch.
//.title~

import 'package:key_flow/key_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  tearDown(() async {
    await resetHardwareKeyboard();
  });

  group('dispose mid-sequence', () {
    testWidgets('disposing during a pending sequence cancels the timer cleanly',
        (tester) async {
      final key = UniqueKey();
      final control = KeyFlowControl(
        sequenceTimeout: const Duration(seconds: 30),
        mappings: {
          key: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG),
            KeyActivator.logical(LogicalKeyboardKey.keyI),
          ],
        },
        callbacks: {key: (_, __) {}},
      );

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      // Start a partial sequence — timer is now armed.
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);

      // Dispose the control. No pending timer must outlive it.
      control.dispose();

      // Replace the widget tree with a bare SizedBox — KeyFlowFocus must
      // tear down without throwing despite the disposed control.
      await tester.pumpWidget(const SizedBox());
      // The test framework's _verifyInvariants will fail at the end of
      // this test if any pending Timer remains. Passing means clean.
    });

    testWidgets(
        'disposing the surrounding widget does not leave a dangling node ref',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNotNull);

      await tester.pumpWidget(const SizedBox());
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNull);
    });

    testWidgets('reset() mid-sequence drops the pending buffer',
        (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG),
            KeyActivator.logical(LogicalKeyboardKey.keyI),
          ],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);

      // Mid-sequence reset — the next "i" must NOT fire anything since
      // the mapping was wiped and the buffer cleared.
      control.reset();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      expect(fired, 0);
    });
  });

  group('rapid input', () {
    testWidgets('100 rapid presses of a single-key binding fire 100 times',
        (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.space)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      for (var i = 0; i < 100; i++) {
        await simulateKeyDownEvent(LogicalKeyboardKey.space);
        await simulateKeyUpEvent(LogicalKeyboardKey.space);
      }
      expect(fired, 100);
    });

    testWidgets('interleaved sequence and chord input', (tester) async {
      final seqKey = UniqueKey();
      final chordKey = UniqueKey();
      var seqFired = 0;
      var chordFired = 0;
      final control = KeyFlowControl(
        mappings: {
          seqKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG),
            KeyActivator.logical(LogicalKeyboardKey.keyI),
          ],
          chordKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyS, control: true),
          ],
        },
        callbacks: {
          seqKey: (_, __) => seqFired += 1,
          chordKey: (_, __) => chordFired += 1,
        },
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      // Interleave: g → s+ctrl → g i → s+ctrl
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);
      // Chord fires immediately, but in between a sequence is buffered.
      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyS);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyS);
      await simulateKeyUpEvent(LogicalKeyboardKey.controlLeft);
      // The interrupting chord with ctrl is bare-prefixed — it neither
      // matches "g i" prefix nor breaks it gracefully? Actually any
      // non-matching input resets the buffer. So after this, g i needs
      // to be retried fresh.
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      expect(seqFired, 1);
      expect(chordFired, 1);
    });
  });

  group('large mapping sets', () {
    testWidgets('500 mappings — exact match still fires correctly',
        (tester) async {
      final targetKey = UniqueKey();
      var fired = 0;

      // 499 noise mappings + 1 target.
      final mappings = <Key, List<KeyActivator>>{};
      final callbacks = <Key, TContextCallback>{};
      for (var i = 0; i < 499; i++) {
        final k = ValueKey('noise-$i');
        mappings[k] = [
          KeyActivator.logical(LogicalKeyboardKey(0x100 + i)),
        ];
        callbacks[k] = (_, __) {};
      }
      mappings[targetKey] = const [
        KeyActivator.logical(LogicalKeyboardKey.escape),
      ];
      callbacks[targetKey] = (_, __) => fired += 1;

      final control = KeyFlowControl(
        mappings: mappings,
        callbacks: callbacks,
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.escape);
      expect(fired, 1);
    });
  });

  group('dynamic mutation', () {
    testWidgets('adding a combination at runtime starts dispatching to it',
        (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      // Before registration — nothing fires.
      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(fired, 0);

      control.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyQ)],
        (_, __) => fired += 1,
      );
      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(fired, 1);
    });

    testWidgets('removing a combination at runtime stops dispatching to it',
        (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.keyQ)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(fired, 1);

      control.removeCombination(key);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(fired, 1);
    });

    testWidgets('callback replacement takes effect immediately',
        (tester) async {
      final key = UniqueKey();
      var firstFired = 0;
      var secondFired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.keyQ)],
        },
        callbacks: {key: (_, __) => firstFired += 1},
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          autofocus: true,
          child: const SizedBox(),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(firstFired, 1);

      control.replaceCallback(key, (_, __) => secondFired += 1);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(firstFired, 1);
      expect(secondFired, 1);
    });
  });

  group('focus loss', () {
    testWidgets('key events are NOT dispatched while another node has focus',
        (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.keyQ)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final other = FocusNode();
      addTearDown(other.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            child: Column(
              children: [
                KeyFlowFocus(
                  control: control,
                  autofocus: true,
                  child: const SizedBox(width: 10, height: 10),
                ),
                Focus(
                  focusNode: other,
                  child: const SizedBox(width: 10, height: 10),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(fired, 1);

      other.requestFocus();
      await tester.pumpAndSettle();
      await simulateKeyDownEvent(LogicalKeyboardKey.keyQ);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyQ);
      expect(fired, 1, reason: 'control no longer has focus → not dispatched');
    });
  });
}
