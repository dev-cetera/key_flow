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
// Tests for [KeyRepeatEvent] handling in [KeyFlowControl.handleKeyEvent].
//.title~

import 'package:key_flow/key_flow.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await resetHardwareKeyboard();
  });

  group('handleKeyEvent — repeat behavior', () {
    test('KeyDownEvent (non-repeat) for single-key fires once', () {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.arrowDown)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final result = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyDown(LogicalKeyboardKey.arrowDown),
      );
      expect(result, KeyEventResult.handled);
      expect(fired, 1);
    });

    test('KeyRepeatEvent fires for single-key activators', () {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.arrowDown)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final result = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyRepeat(LogicalKeyboardKey.arrowDown),
      );
      expect(result, KeyEventResult.handled);
      expect(fired, 1);
    });

    test('KeyRepeatEvent does NOT advance a sequence buffer', () {
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

      // Repeat of g must NOT start the sequence buffer.
      final r1 = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyRepeat(LogicalKeyboardKey.keyG),
      );
      expect(r1, KeyEventResult.ignored);
      expect(fired, 0);

      // Following repeat of i — still no fire, since the buffer is empty.
      final r2 = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyRepeat(LogicalKeyboardKey.keyI),
      );
      expect(r2, KeyEventResult.ignored);
      expect(fired, 0);
    });

    test('KeyUpEvent is always ignored', () {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.enter)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final result = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyUp(LogicalKeyboardKey.enter),
      );
      expect(result, KeyEventResult.ignored);
      expect(fired, 0);
    });

    test('No matching mapping returns ignored', () {
      final key = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.enter)],
        },
        callbacks: {key: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final result = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyDown(LogicalKeyboardKey.keyZ),
      );
      expect(result, KeyEventResult.ignored);
      expect(fired, 0);
    });

    test('Partial match (sequence prefix) returns handled', () {
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

      final r = control.handleKeyEvent(
        _DummyContext(),
        FocusNode(),
        syntheticKeyDown(LogicalKeyboardKey.keyG),
      );
      expect(r, KeyEventResult.handled);
      expect(fired, 0);
    });
  });
}

class _DummyContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  void visitAncestorElements(ConditionalElementVisitor visitor) {
    // No ancestors — empty walk.
  }
}
