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

void main() {
  group('extractDebugName', () {
    test('returns the debugName for a named logical key', () {
      final name = extractDebugName(LogicalKeyboardKey.enter);
      expect(name, isNotEmpty);
      expect(name, contains('Enter'));
    });

    test('returns the debugName for a named physical key', () {
      final name = extractDebugName(PhysicalKeyboardKey.escape);
      expect(name, isNotEmpty);
      expect(name, contains('Escape'));
    });

    test('returns the debugName for a letter logical key', () {
      final name = extractDebugName(LogicalKeyboardKey.keyA);
      expect(name, isNotEmpty);
    });

    test('returns a non-empty result for unknown but valid key ids', () {
      // A logical key id within Unicode range that is not in the known map
      // — extractDebugName must still return *something* via the toString
      // fallback rather than throwing.
      const key = LogicalKeyboardKey(0x10FFFD);
      expect(extractDebugName(key), isNotEmpty);
    });

    test('extension `.debugName` on a key delegates to extractDebugName', () {
      expect(
        LogicalKeyboardKey.enter.debugName,
        extractDebugName(LogicalKeyboardKey.enter),
      );
    });
  });

  group('extractDebugNames', () {
    test('returns names for each key', () {
      final names = extractDebugNames([
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.escape,
      ]).toList();
      expect(names, hasLength(2));
      expect(names.every((e) => e.isNotEmpty), isTrue);
    });

    test('empty input produces empty output', () {
      expect(extractDebugNames(const []), isEmpty);
    });
  });

  group('extensions on Iterable<KeyboardKey>', () {
    test('.debugName joins all names with " - "', () {
      final joined = [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.escape,
      ].debugName;
      expect(joined, contains('-'));
      expect(joined.split(' - ').length, 2);
    });

    test('.debugName for empty iterable is empty string', () {
      expect(<KeyboardKey>[].debugName, isEmpty);
    });

    test('.debugNames returns each name separately', () {
      final names = [
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.escape,
      ].debugNames.toList();
      expect(names, hasLength(2));
    });
  });
}
