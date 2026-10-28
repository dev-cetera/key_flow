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

  group('KeyActivator construction', () {
    test('logical-only activator has no physical', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.enter);
      expect(a.logical, LogicalKeyboardKey.enter);
      expect(a.physical, isNull);
    });

    test('physical-only activator has no logical', () {
      const a = KeyActivator.physical(PhysicalKeyboardKey.keyJ);
      expect(a.physical, PhysicalKeyboardKey.keyJ);
      expect(a.logical, isNull);
    });

    test('LogicalKeyActivator subclass produces a logical-style activator', () {
      const a = LogicalKeyActivator(LogicalKeyboardKey.escape, shift: true);
      expect(a.logical, LogicalKeyboardKey.escape);
      expect(a.physical, isNull);
      expect(a.shift, isTrue);
    });

    test('PhysicalKeyActivator subclass produces a physical-style activator',
        () {
      const a = PhysicalKeyActivator(PhysicalKeyboardKey.keyK, alt: true);
      expect(a.physical, PhysicalKeyboardKey.keyK);
      expect(a.logical, isNull);
      expect(a.alt, isTrue);
    });

    test('default modifier flags are all false', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.space);
      expect(a.meta, isFalse);
      expect(a.control, isFalse);
      expect(a.shift, isFalse);
      expect(a.alt, isFalse);
    });
  });

  group('isBare', () {
    test('returns true when no modifiers are set', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.isBare, isTrue);
    });

    test('returns false when meta is set', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
      expect(a.isBare, isFalse);
    });

    test('returns false when control is set', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, control: true);
      expect(a.isBare, isFalse);
    });

    test('returns false when shift is set', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, shift: true);
      expect(a.isBare, isFalse);
    });

    test('returns false when alt is set', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, alt: true);
      expect(a.isBare, isFalse);
    });

    test('returns false when multiple modifiers are set', () {
      const a = KeyActivator.logical(
        LogicalKeyboardKey.keyA,
        meta: true,
        shift: true,
      );
      expect(a.isBare, isFalse);
    });
  });

  group('equality and hashCode', () {
    test('identical logical activators are equal', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.enter);
      const b = KeyActivator.logical(LogicalKeyboardKey.enter);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different logical keys are not equal', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.enter);
      const b = KeyActivator.logical(LogicalKeyboardKey.escape);
      expect(a, isNot(equals(b)));
    });

    test('different modifier flags produce inequality', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.enter, meta: true);
      const b = KeyActivator.logical(LogicalKeyboardKey.enter);
      expect(a, isNot(equals(b)));
    });

    test('logical vs physical activators on equivalent keys are not equal', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      const b = KeyActivator.physical(PhysicalKeyboardKey.keyA);
      expect(a, isNot(equals(b)));
    });

    test('LogicalKeyActivator equals KeyActivator.logical with same args', () {
      const a = LogicalKeyActivator(LogicalKeyboardKey.keyA);
      const b = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('PhysicalKeyActivator equals KeyActivator.physical with same args',
        () {
      const a = PhysicalKeyActivator(PhysicalKeyboardKey.keyA);
      const b = KeyActivator.physical(PhysicalKeyboardKey.keyA);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality is not true against other types', () {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      // ignore: unrelated_type_equality_checks
      expect(a == 'not an activator', isFalse);
    });

    test('distinct activators are pairwise non-equal', () {
      final activators = <KeyActivator>[
        const KeyActivator.logical(LogicalKeyboardKey.keyA),
        const KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true),
        const KeyActivator.logical(LogicalKeyboardKey.keyA, control: true),
        const KeyActivator.logical(LogicalKeyboardKey.keyA, shift: true),
        const KeyActivator.logical(LogicalKeyboardKey.keyA, alt: true),
        const KeyActivator.logical(
          LogicalKeyboardKey.keyA,
          meta: true,
          shift: true,
        ),
      ];
      for (var i = 0; i < activators.length; i++) {
        for (var j = i + 1; j < activators.length; j++) {
          expect(activators[i], isNot(equals(activators[j])));
        }
      }
      expect(activators.map((e) => e.hashCode).toSet().length, greaterThan(1));
    });
  });

  group('matches() — event kind gating', () {
    testWidgets('does not match KeyUpEvent', (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyUp(LogicalKeyboardKey.keyA)), isFalse);
    });

    testWidgets('matches KeyDownEvent for the same logical key',
        (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
    });

    testWidgets('matches KeyRepeatEvent for the same logical key',
        (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyRepeat(LogicalKeyboardKey.keyA)), isTrue);
    });

    testWidgets('does not match a modifier key event itself', (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.shift);
      expect(
        a.matches(syntheticKeyDown(LogicalKeyboardKey.shiftLeft)),
        isFalse,
      );
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.shift)), isFalse);
    });
  });

  group('matches() — logical key matching with modifiers', () {
    testWidgets('bare activator matches event with no modifiers pressed',
        (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
    });

    testWidgets('bare activator does NOT match event with shift pressed',
        (tester) async {
      await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isFalse);
    });

    testWidgets('shift activator matches event with shift pressed',
        (tester) async {
      await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, shift: true);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
    });

    testWidgets('shift activator does NOT match event without shift',
        (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, shift: true);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isFalse);
    });

    testWidgets('control activator requires control on every platform',
        (tester) async {
      await withPlatformAsync(TargetPlatform.macOS, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, control: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
      });
    });

    testWidgets('alt activator matches event with alt pressed', (tester) async {
      await simulateKeyDownEvent(LogicalKeyboardKey.altLeft);
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA, alt: true);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
    });

    testWidgets('does not match a different logical key', (tester) async {
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyB)), isFalse);
    });

    testWidgets('rejects when a non-required modifier is pressed',
        (tester) async {
      await simulateKeyDownEvent(LogicalKeyboardKey.altLeft);
      const a = KeyActivator.logical(LogicalKeyboardKey.keyA);
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isFalse);
    });

    testWidgets('multi-modifier activator requires all modifiers',
        (tester) async {
      await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.altLeft);
      const a = KeyActivator.logical(
        LogicalKeyboardKey.keyA,
        shift: true,
        alt: true,
      );
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
    });

    testWidgets('multi-modifier activator rejects partial modifiers',
        (tester) async {
      await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      const a = KeyActivator.logical(
        LogicalKeyboardKey.keyA,
        shift: true,
        alt: true,
      );
      expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isFalse);
    });
  });

  group('matches() — meta/cmd platform behavior', () {
    testWidgets('on macOS, meta activator matches when meta is pressed',
        (tester) async {
      await withPlatformAsync(TargetPlatform.macOS, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.metaLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
      });
    });

    testWidgets('on macOS, meta activator does NOT match when ctrl pressed',
        (tester) async {
      await withPlatformAsync(TargetPlatform.macOS, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isFalse);
      });
    });

    testWidgets('on iOS, meta activator matches when meta is pressed',
        (tester) async {
      await withPlatformAsync(TargetPlatform.iOS, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.metaLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
      });
    });

    testWidgets('on Windows, meta activator matches when ctrl is pressed',
        (tester) async {
      await withPlatformAsync(TargetPlatform.windows, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
      });
    });

    testWidgets('on Linux, meta activator matches when ctrl is pressed',
        (tester) async {
      await withPlatformAsync(TargetPlatform.linux, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isTrue);
      });
    });

    testWidgets('on Windows, meta activator does NOT match when only meta',
        (tester) async {
      await withPlatformAsync(TargetPlatform.windows, () async {
        await simulateKeyDownEvent(LogicalKeyboardKey.metaLeft);
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, meta: true);
        expect(a.matches(syntheticKeyDown(LogicalKeyboardKey.keyA)), isFalse);
      });
    });
  });

  group('matches() — physical key matching', () {
    testWidgets('matches by physical key position', (tester) async {
      const a = KeyActivator.physical(PhysicalKeyboardKey.keyJ);
      expect(
        a.matches(
          syntheticKeyDown(
            LogicalKeyboardKey.keyJ,
            physical: PhysicalKeyboardKey.keyJ,
          ),
        ),
        isTrue,
      );
    });

    testWidgets('does NOT match a different physical key', (tester) async {
      const a = KeyActivator.physical(PhysicalKeyboardKey.keyJ);
      expect(
        a.matches(
          syntheticKeyDown(
            LogicalKeyboardKey.keyK,
            physical: PhysicalKeyboardKey.keyK,
          ),
        ),
        isFalse,
      );
    });

    testWidgets('physical key match is layout-agnostic', (tester) async {
      const a = KeyActivator.physical(PhysicalKeyboardKey.keyQ);
      expect(
        a.matches(
          syntheticKeyDown(
            LogicalKeyboardKey.keyA,
            physical: PhysicalKeyboardKey.keyQ,
          ),
        ),
        isTrue,
      );
    });
  });

  group('isAppleHost', () {
    test('returns true on macOS', () {
      withPlatform(TargetPlatform.macOS, () {
        expect(KeyActivator.isAppleHost, isTrue);
      });
    });

    test('returns true on iOS', () {
      withPlatform(TargetPlatform.iOS, () {
        expect(KeyActivator.isAppleHost, isTrue);
      });
    });

    test('returns false on Windows', () {
      withPlatform(TargetPlatform.windows, () {
        expect(KeyActivator.isAppleHost, isFalse);
      });
    });

    test('returns false on Linux', () {
      withPlatform(TargetPlatform.linux, () {
        expect(KeyActivator.isAppleHost, isFalse);
      });
    });

    test('returns false on Android', () {
      withPlatform(TargetPlatform.android, () {
        expect(KeyActivator.isAppleHost, isFalse);
      });
    });

    test('returns false on Fuchsia', () {
      withPlatform(TargetPlatform.fuchsia, () {
        expect(KeyActivator.isAppleHost, isFalse);
      });
    });
  });

  group('describe()', () {
    test('on macOS uses ⌘ symbol for meta', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.enter, meta: true);
        expect(a.describe(), contains('⌘'));
      });
    });

    test('on Windows uses "Ctrl" for meta', () {
      withPlatform(TargetPlatform.windows, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.enter, meta: true);
        expect(a.describe(), contains('Ctrl'));
        expect(a.describe(), contains('+'));
      });
    });

    test('on macOS, shift+meta+Enter is "⌘⇧Enter"', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(
          LogicalKeyboardKey.enter,
          meta: true,
          shift: true,
        );
        expect(a.describe(), '⌘⇧Enter');
      });
    });

    test('on Windows, shift+meta+Enter is "Ctrl+Shift+Enter"', () {
      withPlatform(TargetPlatform.windows, () {
        const a = KeyActivator.logical(
          LogicalKeyboardKey.enter,
          meta: true,
          shift: true,
        );
        expect(a.describe(), 'Ctrl+Shift+Enter');
      });
    });

    test('on macOS, control without meta uses ⌃', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, control: true);
        expect(a.describe(), startsWith('⌃'));
      });
    });

    test('on macOS, alt uses ⌥', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, alt: true);
        expect(a.describe(), startsWith('⌥'));
      });
    });

    test('on Windows, alt uses "Alt"', () {
      withPlatform(TargetPlatform.windows, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.keyA, alt: true);
        expect(a.describe(), contains('Alt'));
      });
    });

    test('single-letter logical key is uppercased', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.keyG, meta: true);
        expect(a.describe(), endsWith('G'));
      });
    });

    test('physical-only activator renders via its debug name', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.physical(PhysicalKeyboardKey.keyJ);
        final desc = a.describe();
        expect(desc, isNotEmpty);
      });
    });

    test('toString delegates to describe()', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.enter, meta: true);
        expect(a.toString(), 'KeyActivator(${a.describe()})');
      });
    });
  });

  group('debugName extensions', () {
    test('KeyActivator.debugName equals describe()', () {
      withPlatform(TargetPlatform.macOS, () {
        const a = KeyActivator.logical(LogicalKeyboardKey.enter, meta: true);
        expect(a.debugName, a.describe());
      });
    });

    test('Iterable<KeyActivator>.debugName joins with spaces', () {
      withPlatform(TargetPlatform.macOS, () {
        const seq = [
          KeyActivator.logical(LogicalKeyboardKey.keyG),
          KeyActivator.logical(LogicalKeyboardKey.keyI),
        ];
        expect(seq.debugName, 'G I');
      });
    });

    test('empty iterable produces empty string', () {
      const seq = <KeyActivator>[];
      expect(seq.debugName, '');
    });
  });

  group('shorthand extensions on LogicalKeyboardKey', () {
    test('.bare produces an unmodified logical activator', () {
      final a = LogicalKeyboardKey.escape.bare;
      expect(a, isA<LogicalKeyActivator>());
      expect(a.logical, LogicalKeyboardKey.escape);
      expect(a.isBare, isTrue);
    });

    test('.meta produces a meta-modified logical activator', () {
      final a = LogicalKeyboardKey.keyG.meta;
      expect(a.meta, isTrue);
      expect(a.logical, LogicalKeyboardKey.keyG);
    });

    test('.shifted produces a shift-modified logical activator', () {
      final a = LogicalKeyboardKey.keyA.shifted;
      expect(a.shift, isTrue);
      expect(a.logical, LogicalKeyboardKey.keyA);
    });
  });

  group('isModifierKey', () {
    test('returns true for canonical modifier keys', () {
      for (final key in [
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.alt,
        LogicalKeyboardKey.meta,
      ]) {
        expect(isModifierKey(key), isTrue, reason: '$key should be modifier');
      }
    });

    test('returns true for side-specific modifier variants', () {
      for (final key in [
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.controlRight,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.altRight,
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.metaRight,
      ]) {
        expect(isModifierKey(key), isTrue, reason: '$key should be modifier');
      }
    });

    test('returns false for letter keys', () {
      expect(isModifierKey(LogicalKeyboardKey.keyA), isFalse);
      expect(isModifierKey(LogicalKeyboardKey.keyZ), isFalse);
    });

    test('returns false for named non-modifier keys', () {
      for (final key in [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.escape,
        LogicalKeyboardKey.space,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.f1,
      ]) {
        expect(isModifierKey(key), isFalse, reason: '$key is not a modifier');
      }
    });
  });
}
