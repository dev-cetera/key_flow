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

import '../helpers.dart';

KeyStroke stroke(
  LogicalKeyboardKey key, {
  String? character,
  bool meta = false,
  bool control = false,
  bool shift = false,
  bool alt = false,
}) {
  return KeyStroke(
    logical: key,
    physical: PhysicalKeyboardKey.keyA,
    character: character,
    meta: meta,
    control: control,
    shift: shift,
    alt: alt,
  );
}

void main() {
  group('KeyActivator.parse', () {
    test('reads modifiers in any order and case', () {
      final a = KeyActivator.parse('Shift+META+k');
      expect(a.logical, LogicalKeyboardKey.keyK);
      expect(a.meta, isTrue);
      expect(a.shift, isTrue);
      expect(a.control, isFalse);
      expect(a.alt, isFalse);
    });

    test('reads the symbols describe() prints', () {
      final a = KeyActivator.parse('⌘⇧K');
      expect(a, KeyActivator.parse('meta+shift+k'));
      expect(KeyActivator.parse('↩'), KeyActivator.parse('enter'));
      expect(KeyActivator.parse('⌥↑'), KeyActivator.parse('alt+up'));
    });

    test('reads named keys and aliases', () {
      expect(KeyActivator.parse('esc').logical, LogicalKeyboardKey.escape);
      expect(KeyActivator.parse('Return').logical, LogicalKeyboardKey.enter);
      expect(KeyActivator.parse('f5').logical, LogicalKeyboardKey.f5);
      expect(KeyActivator.parse('pgdn').logical, LogicalKeyboardKey.pageDown);
      expect(KeyActivator.parse('space').logical, LogicalKeyboardKey.space);
    });

    test('a symbol on its own matches what it types', () {
      final a = KeyActivator.parse('?');
      expect(a.character, '?');
      expect(
        a.accepts(
          stroke(LogicalKeyboardKey.slash, character: '?', shift: true),
        ),
        isTrue,
      );
      expect(
        a.accepts(stroke(LogicalKeyboardKey.slash, character: '/')),
        isFalse,
      );
    });

    test('a symbol with a modifier matches its key', () {
      final a = KeyActivator.parse('meta+/');
      expect(a.logical, LogicalKeyboardKey.slash);
      expect(a.character, isNull);
    });

    test('the plus key can be written', () {
      expect(KeyActivator.parse('meta++').logical, LogicalKeyboardKey.add);
      expect(KeyActivator.parse('ctrl+plus').logical, LogicalKeyboardKey.add);
    });

    test('throws a FormatException naming what it could not read', () {
      expect(() => KeyActivator.parse(''), throwsFormatException);
      expect(() => KeyActivator.parse('hyper+k'), throwsFormatException);
      expect(() => KeyActivator.parse('meta+'), throwsFormatException);
      expect(() => KeyActivator.parse('banana'), throwsFormatException);
    });
  });

  group('toSpec round trip', () {
    for (final spec in [
      'meta+k',
      'meta+shift+k',
      'ctrl+alt+delete',
      'g',
      '?',
      'f12',
      'shift+tab',
      'escape',
      'up',
      'meta+/',
      'plus',
      'meta+1',
    ]) {
      test(spec, () {
        expect(KeyActivator.parse(spec).toSpec(), spec);
        expect(
          KeyActivator.parse(KeyActivator.parse(spec).toSpec()),
          KeyActivator.parse(spec),
        );
      });
    }

    test('describe() reads back on macOS and elsewhere', () {
      for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
        withPlatform(platform, () {
          for (final spec in ['meta+shift+k', 'alt+enter', 'g', 'f5', 'up']) {
            final a = KeyActivator.parse(spec);
            expect(
              KeyActivator.parse(a.describe()).accepts(_strokeFor(a)),
              isTrue,
              reason: '$spec on $platform described as ${a.describe()}',
            );
          }
        });
      }
    });
  });

  group('KeyBinding', () {
    test('parses keys separated by spaces', () {
      final b = KeyBinding.parse('g  p   s');
      expect(b.steps, hasLength(3));
      expect(b.toSpec(), 'g p s');
    });

    test('describe() shows each key', () {
      withPlatform(TargetPlatform.macOS, () {
        expect(KeyBinding.parse('meta+k meta+d').describe(), '⌘K ⌘D');
        expect(KeyBinding.parse('g i').describe(), 'G I');
      });
      withPlatform(TargetPlatform.linux, () {
        expect(KeyBinding.parse('meta+shift+p').describe(), 'Ctrl+Shift+P');
      });
    });

    test('startsWith matches strokes as they were pressed', () {
      withPlatform(TargetPlatform.macOS, () {
        final b = KeyBinding.parse('meta+k d');
        final k = stroke(LogicalKeyboardKey.keyK, meta: true);
        final d = stroke(LogicalKeyboardKey.keyD);
        expect(b.startsWith([k]), isTrue);
        expect(b.startsWith([k, d]), isTrue);
        // ⌘ held for D as well is a different key.
        expect(
          b.startsWith([k, stroke(LogicalKeyboardKey.keyD, meta: true)]),
          isFalse,
        );
        expect(b.startsWith([k, d, d]), isFalse);
      });
    });

    test('overlaps finds keys that are the start of others', () {
      expect(KeyBinding.parse('g').overlaps(KeyBinding.parse('g i')), isTrue);
      expect(KeyBinding.parse('g i').overlaps(KeyBinding.parse('g')), isTrue);
      expect(
        KeyBinding.parse('g i').overlaps(KeyBinding.parse('g j')),
        isFalse,
      );
      expect(
        KeyBinding.parse('meta+k').overlaps(KeyBinding.parse('k')),
        isFalse,
      );
    });

    test('an empty binding is refused', () {
      expect(() => KeyBinding.parse('  '), throwsFormatException);
      expect(() => KeyBinding(const []), throwsArgumentError);
    });

    test('equal when the keys are equal', () {
      expect(KeyBinding.parse('meta+k'), KeyBinding.parse('cmd+K'));
      expect(
        KeyBinding.parse('g i').hashCode,
        KeyBinding.parse('g i').hashCode,
      );
    });
  });
}

/// The stroke that would press [activator] on the current platform.
KeyStroke _strokeFor(KeyActivator activator) {
  final apple = KeyActivator.isAppleHost;
  return KeyStroke(
    logical: activator.logical!,
    physical: PhysicalKeyboardKey.keyA,
    meta: activator.meta && apple,
    control: activator.control || (activator.meta && !apple),
    shift: activator.shift,
    alt: activator.alt,
  );
}
