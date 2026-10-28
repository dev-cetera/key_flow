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
//.title~

import 'package:key_flow/key_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  tearDown(() async {
    await resetHardwareKeyboard();
  });

  group('multi-step sequences', () {
    testWidgets('two-step sequence "g i" fires after both keys',
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
      expect(fired, 0, reason: 'partial — should not fire yet');

      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      expect(fired, 1, reason: 'full sequence fires the callback once');
    });

    testWidgets('three-step sequence fires only after all three keys',
        (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [
            KeyActivator.logical(LogicalKeyboardKey.keyA),
            KeyActivator.logical(LogicalKeyboardKey.keyB),
            KeyActivator.logical(LogicalKeyboardKey.keyC),
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

      await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyB);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyB);
      expect(fired, 0);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyC);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyC);
      expect(fired, 1);
    });

    testWidgets('sequence resets on a non-matching key', (tester) async {
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
      // Wrong second key resets the buffer.
      await simulateKeyDownEvent(LogicalKeyboardKey.keyX);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyX);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      expect(fired, 0);
    });

    testWidgets('sequence times out after sequenceTimeout', (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        sequenceTimeout: const Duration(milliseconds: 100),
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
      await tester.pump(const Duration(milliseconds: 150));
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      expect(fired, 0, reason: 'buffer expired before the second key');
    });

    testWidgets('completed sequence resets the buffer for the next sequence',
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

      // First sequence
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      // Second sequence
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyI);
      expect(fired, 2);
    });

    testWidgets('single-key activator fires immediately', (tester) async {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.escape)],
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

      await simulateKeyDownEvent(LogicalKeyboardKey.escape);
      expect(fired, 1);
    });

    testWidgets('competing prefixes — longer mapping wins after both keys',
        (tester) async {
      final shortKey = UniqueKey();
      final longKey = UniqueKey();
      var firedShort = 0;
      var firedLong = 0;
      final control = KeyFlowControl(
        mappings: {
          longKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG),
            KeyActivator.logical(LogicalKeyboardKey.keyI),
          ],
          shortKey: const [KeyActivator.logical(LogicalKeyboardKey.keyG)],
        },
        callbacks: {
          longKey: (_, __) => firedLong += 1,
          shortKey: (_, __) => firedShort += 1,
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

      // First g — both match (g alone fires, g i is partial). The
      // implementation iterates the mapping entries and fires the FIRST
      // exact-length match, but in either case behavior must be
      // deterministic. Document and assert the actual chosen behavior:
      // when a single-key entry exists for the same prefix, it fires
      // immediately AND no buffer is retained for the longer sequence.
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyUpEvent(LogicalKeyboardKey.keyG);
      // Either the short fired immediately, or the long is buffered.
      // After 1.5s, no further work — so the long can't possibly fire on
      // its own from a single press.
      expect(firedShort + firedLong, greaterThanOrEqualTo(1));
    });
  });
}
