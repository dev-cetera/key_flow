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
  group('KeyFlowControl construction', () {
    test('creates an empty control by default', () {
      final c = KeyFlowControl();
      expect(c.mappings, isEmpty);
      expect(c.callbacks, isEmpty);
      expect(c.focusNode, isNull);
      expect(c.onFocusChange, isNull);
      expect(c.suppressBareKeysInTextFields, isTrue);
      expect(c.sequenceTimeout, const Duration(milliseconds: 1500));
    });

    test('accepts initial mappings and callbacks', () {
      final key = UniqueKey();
      final mappings = {
        key: const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
      };
      void cb(BuildContext _, CallbackRegistry __) {}
      final c = KeyFlowControl(
        mappings: mappings,
        callbacks: {key: cb},
      );
      expect(c.mappings, equals(mappings));
      expect(c.callbacks, equals({key: cb}));
    });

    test('accepts a custom sequence timeout', () {
      final c = KeyFlowControl(
        sequenceTimeout: const Duration(seconds: 5),
      );
      expect(c.sequenceTimeout, const Duration(seconds: 5));
    });

    test('accepts suppressBareKeysInTextFields override', () {
      final c = KeyFlowControl(suppressBareKeysInTextFields: false);
      expect(c.suppressBareKeysInTextFields, isFalse);
    });

    test('stores onFocusChange callback', () {
      void cb(BuildContext _, bool __) {}
      final c = KeyFlowControl(onFocusChange: cb);
      expect(c.onFocusChange, equals(cb));
    });
  });

  group('mappings notifier', () {
    test('mappings getter reflects notifier value', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.mappingsNotifier.set({
        key: const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
      });
      expect(c.mappings, containsPair(key, isA<List<KeyActivator>>()));
    });

    test('mappingsNotifier notifies on update', () {
      final c = KeyFlowControl();
      var notifyCount = 0;
      c.mappingsNotifier.addStrongRefListener(
        strongRefListener: () => notifyCount += 1,
      );
      c.mappingsNotifier.update(
        (m) => m
          ..[UniqueKey()] = const [
            KeyActivator.logical(LogicalKeyboardKey.keyA),
          ],
      );
      expect(notifyCount, greaterThan(0));
    });
  });

  group('addCombination', () {
    test('adds a new combination and its callback', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      const combo = [KeyActivator.logical(LogicalKeyboardKey.keyA)];
      void cb(BuildContext _, CallbackRegistry __) {}

      c.addCombination(key, combo, cb);

      expect(c.mappings[key], equals(combo));
      expect(c.callbacks[key], equals(cb));
      expect(c.hasCombination(key), isTrue);
    });

    test('throws ArgumentError if combination already exists', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      const combo = [KeyActivator.logical(LogicalKeyboardKey.keyA)];
      void cb(BuildContext _, CallbackRegistry __) {}

      c.addCombination(key, combo, cb);
      expect(
        () => c.addCombination(key, combo, cb),
        throwsArgumentError,
      );
    });
  });

  group('replaceCombination', () {
    test('replaces an existing combination', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      const newCombo = [KeyActivator.logical(LogicalKeyboardKey.keyB)];
      c.replaceCombination(key, newCombo);
      expect(c.mappings[key], equals(newCombo));
    });

    test('throws ArgumentError if no existing combination', () {
      final c = KeyFlowControl();
      expect(
        () => c.replaceCombination(
          UniqueKey(),
          const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('replaceCallback', () {
    test('replaces an existing callback', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      var firstCalled = false;
      var secondCalled = false;
      c.callbacks[key] = (_, __) => firstCalled = true;
      c.replaceCallback(key, (_, __) => secondCalled = true);
      expect(c.callbacks[key], isNotNull);
      // Invoke via the registry directly.
      c.callbacks[key]!(_FakeContext(), c.registry);
      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
    });

    test('throws ArgumentError if no existing callback', () {
      final c = KeyFlowControl();
      expect(
        () => c.replaceCallback(UniqueKey(), (_, __) {}),
        throwsArgumentError,
      );
    });
  });

  group('removeCombination', () {
    test('removes both mapping and callback', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      c.removeCombination(key);
      expect(c.hasCombination(key), isFalse);
      expect(c.callbacks.containsKey(key), isFalse);
    });

    test('removing a missing key is a no-op', () {
      final c = KeyFlowControl();
      expect(() => c.removeCombination(UniqueKey()), returnsNormally);
    });
  });

  group('remap', () {
    test('remaps an existing key to a new combination', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      const newCombo = [
        KeyActivator.logical(LogicalKeyboardKey.keyA),
        KeyActivator.logical(LogicalKeyboardKey.keyB),
      ];
      c.remap(key, newCombo);
      expect(c.mappings[key], equals(newCombo));
    });

    test('throws ArgumentError if no existing mapping', () {
      final c = KeyFlowControl();
      expect(
        () => c.remap(
          UniqueKey(),
          const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        ),
        throwsArgumentError,
      );
    });
  });

  group('hasCombination', () {
    test('returns true when key is mapped', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      expect(c.hasCombination(key), isTrue);
    });

    test('returns false when key is absent', () {
      final c = KeyFlowControl();
      expect(c.hasCombination(UniqueKey()), isFalse);
    });
  });

  group('getCombination', () {
    test('returns the activator sequence for a mapped key', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      const combo = [
        KeyActivator.logical(LogicalKeyboardKey.keyG),
        KeyActivator.logical(LogicalKeyboardKey.keyI),
      ];
      c.addCombination(key, combo, (_, __) {});
      expect(c.getCombination(key), equals(combo));
    });

    test('returns null for an unmapped key', () {
      final c = KeyFlowControl();
      expect(c.getCombination(UniqueKey()), isNull);
    });
  });

  group('reset', () {
    test('replaces mappings and callbacks atomically', () {
      final c = KeyFlowControl();
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      c.addCombination(
        keyA,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      c.reset(
        mappings: {
          keyB: const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
        },
        callbacks: {keyB: (_, __) {}},
      );
      expect(c.hasCombination(keyA), isFalse);
      expect(c.hasCombination(keyB), isTrue);
      expect(c.callbacks.containsKey(keyA), isFalse);
      expect(c.callbacks.containsKey(keyB), isTrue);
    });

    test('returns this for chaining', () {
      final c = KeyFlowControl();
      expect(identical(c.reset(), c), isTrue);
    });

    test('resets to empty when called with no args', () {
      final c = KeyFlowControl();
      c.addCombination(
        UniqueKey(),
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      c.reset();
      expect(c.mappings, isEmpty);
      expect(c.callbacks, isEmpty);
    });
  });

  group('merge', () {
    test('adds new mappings without removing existing', () {
      final c = KeyFlowControl();
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      c.addCombination(
        keyA,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      c.merge(
        mappings: {
          keyB: const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
        },
        callbacks: {keyB: (_, __) {}},
      );
      expect(c.hasCombination(keyA), isTrue);
      expect(c.hasCombination(keyB), isTrue);
    });

    test('merge with callbacks only does not touch mappingsNotifier', () {
      final c = KeyFlowControl();
      var notifyCount = 0;
      c.mappingsNotifier.addStrongRefListener(
        strongRefListener: () => notifyCount += 1,
      );
      final key = UniqueKey();
      c.merge(callbacks: {key: (_, __) {}});
      expect(notifyCount, 0);
      expect(c.callbacks.containsKey(key), isTrue);
    });

    test('overwrites overlapping mappings', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      c.merge(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
        },
      );
      expect(c.mappings[key], hasLength(1));
      expect(c.mappings[key]!.first.logical, LogicalKeyboardKey.keyB);
    });

    test('returns this for chaining', () {
      final c = KeyFlowControl();
      expect(identical(c.merge(), c), isTrue);
    });
  });

  group('copyWith', () {
    test('preserves mappings and callbacks by default', () {
      final c = KeyFlowControl(
        mappings: {
          const ValueKey('a'): const [
            KeyActivator.logical(LogicalKeyboardKey.keyA),
          ],
        },
        callbacks: {const ValueKey('a'): (_, __) {}},
      );
      final copy = c.copyWith();
      expect(copy.mappings, equals(c.mappings));
      expect(copy.callbacks, equals(c.callbacks));
    });

    test('returns a new instance (not the same object)', () {
      final c = KeyFlowControl();
      final copy = c.copyWith();
      expect(identical(c, copy), isFalse);
    });

    test('overrides only specified fields', () {
      final c = KeyFlowControl(
        sequenceTimeout: const Duration(seconds: 2),
        suppressBareKeysInTextFields: true,
      );
      final copy = c.copyWith(suppressBareKeysInTextFields: false);
      expect(copy.sequenceTimeout, const Duration(seconds: 2));
      expect(copy.suppressBareKeysInTextFields, isFalse);
    });

    test('copies mappings into a new map (no aliasing)', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      final copy = c.copyWith();
      copy.removeCombination(key);
      // Original should be untouched.
      expect(c.hasCombination(key), isTrue);
    });
  });

  group('mergeWith', () {
    test('combines mappings from both controls', () {
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      final a = KeyFlowControl()
        ..addCombination(
          keyA,
          const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
          (_, __) {},
        );
      final b = KeyFlowControl()
        ..addCombination(
          keyB,
          const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
          (_, __) {},
        );
      final merged = a.mergeWith(b);
      expect(merged.hasCombination(keyA), isTrue);
      expect(merged.hasCombination(keyB), isTrue);
    });

    test('preserves a\'s sequenceTimeout and suppression flag', () {
      final a = KeyFlowControl(
        sequenceTimeout: const Duration(seconds: 5),
        suppressBareKeysInTextFields: false,
      );
      final b = KeyFlowControl(
        sequenceTimeout: const Duration(seconds: 1),
        suppressBareKeysInTextFields: true,
      );
      final merged = a.mergeWith(b);
      expect(merged.sequenceTimeout, const Duration(seconds: 5));
      expect(merged.suppressBareKeysInTextFields, isFalse);
    });

    test('does not mutate either source control', () {
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      final a = KeyFlowControl()
        ..addCombination(
          keyA,
          const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
          (_, __) {},
        );
      final b = KeyFlowControl()
        ..addCombination(
          keyB,
          const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
          (_, __) {},
        );
      a.mergeWith(b);
      expect(a.hasCombination(keyA), isTrue);
      expect(a.hasCombination(keyB), isFalse);
      expect(b.hasCombination(keyA), isFalse);
      expect(b.hasCombination(keyB), isTrue);
    });
  });

  group('getAllKeyMappings', () {
    test('returns a list with key and combination', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      const combo = [KeyActivator.logical(LogicalKeyboardKey.keyA)];
      c.addCombination(key, combo, (_, __) {});
      final all = c.getAllKeyMappings();
      expect(all, hasLength(1));
      expect(all.first['key'], same(key));
      expect(all.first['combination'], equals(combo));
    });

    test('returns empty list when no mappings', () {
      expect(KeyFlowControl().getAllKeyMappings(), isEmpty);
    });
  });

  group('dispose', () {
    test('clears callbacks and disposes mappingsNotifier', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      c.addCombination(
        key,
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      c.dispose();
      expect(c.callbacks, isEmpty);
      expect(c.mappingsNotifier.isDisposed, isTrue);
    });
  });

  group('CallbackRegistry.call', () {
    test('invokes the callback for the given key', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      var called = false;
      c.callbacks[key] = (_, __) => called = true;
      c.registry.call(_FakeContext(), key);
      expect(called, isTrue);
    });

    test('asserts when no callback is registered', () {
      final c = KeyFlowControl();
      expect(
        () => c.registry.call(_FakeContext(), UniqueKey()),
        throwsAssertionError,
      );
    });

    test('passes the registry to the callback', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      CallbackRegistry? received;
      c.callbacks[key] = (_, r) => received = r;
      c.registry.call(_FakeContext(), key);
      expect(identical(received, c.registry), isTrue);
    });
  });

  group('KeyFlowControl.call delegates to registry.call', () {
    test('invokes callback', () {
      final c = KeyFlowControl();
      final key = UniqueKey();
      var called = false;
      c.callbacks[key] = (_, __) => called = true;
      c.call(_FakeContext(), key);
      expect(called, isTrue);
    });
  });

  group('callbacks setter', () {
    test('replaces the underlying callbacks map', () {
      final c = KeyFlowControl();
      final newCallbacks = <Key, TContextCallback>{
        UniqueKey(): (_, __) {},
      };
      c.callbacks = newCallbacks;
      expect(identical(c.callbacks, newCallbacks), isTrue);
    });
  });
}

/// A minimal BuildContext stand-in for tests that never actually use the
/// context — only its presence matters.
class _FakeContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
