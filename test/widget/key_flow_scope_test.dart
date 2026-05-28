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
  group('KeyFlowScope.of', () {
    testWidgets('returns the nearest ancestor scope', (tester) async {
      final control = KeyFlowControl();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(control.dispose);

      KeyFlowScope? captured;
      await tester.pumpWidget(
        KeyFlowScope(
          control: control,
          focusNode: focusNode,
          child: Builder(
            builder: (context) {
              captured = KeyFlowScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, isNotNull);
      expect(captured!.control, same(control));
      expect(captured!.focusNode, same(focusNode));
    });

    testWidgets('returns null when no scope is present', (tester) async {
      KeyFlowScope? captured;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            captured = KeyFlowScope.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(captured, isNull);
    });

    testWidgets('nested scopes — inner scope is returned to inner consumers',
        (tester) async {
      final outer = KeyFlowControl();
      final inner = KeyFlowControl();
      addTearDown(outer.dispose);
      addTearDown(inner.dispose);

      KeyFlowScope? captured;
      await tester.pumpWidget(
        KeyFlowScope(
          control: outer,
          focusNode: null,
          child: KeyFlowScope(
            control: inner,
            focusNode: null,
            child: Builder(
              builder: (context) {
                captured = KeyFlowScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(captured!.control, same(inner));
    });
  });

  group('updateShouldNotify', () {
    testWidgets('triggers a rebuild when control changes', (tester) async {
      final controlA = KeyFlowControl();
      final controlB = KeyFlowControl();
      addTearDown(controlA.dispose);
      addTearDown(controlB.dispose);

      var rebuilds = 0;
      KeyFlowControl? lastControl;

      KeyFlowScope buildWith(KeyFlowControl c) => KeyFlowScope(
            control: c,
            focusNode: null,
            child: Builder(
              builder: (context) {
                rebuilds += 1;
                lastControl = KeyFlowScope.of(context)?.control;
                return const SizedBox();
              },
            ),
          );

      await tester.pumpWidget(buildWith(controlA));
      expect(lastControl, same(controlA));
      final initialBuilds = rebuilds;

      await tester.pumpWidget(buildWith(controlB));
      expect(lastControl, same(controlB));
      expect(rebuilds, greaterThan(initialBuilds));
    });

    testWidgets('updateShouldNotify returns false when control is the same',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);
      final focusA = FocusNode();
      final focusB = FocusNode();
      addTearDown(focusA.dispose);
      addTearDown(focusB.dispose);

      final scopeA = KeyFlowScope(
        control: control,
        focusNode: focusA,
        child: const SizedBox(),
      );
      final scopeB = KeyFlowScope(
        control: control,
        focusNode: focusB,
        child: const SizedBox(),
      );
      // Direct call to updateShouldNotify — focusNode-only change must not
      // notify dependents.
      expect(scopeB.updateShouldNotify(scopeA), isFalse);
    });

    testWidgets('updateShouldNotify returns true when control changes',
        (tester) async {
      final controlA = KeyFlowControl();
      final controlB = KeyFlowControl();
      addTearDown(controlA.dispose);
      addTearDown(controlB.dispose);

      final scopeA = KeyFlowScope(
        control: controlA,
        focusNode: null,
        child: const SizedBox(),
      );
      final scopeB = KeyFlowScope(
        control: controlB,
        focusNode: null,
        child: const SizedBox(),
      );
      expect(scopeB.updateShouldNotify(scopeA), isTrue);
    });
  });

  group('KeyFlowScopeBuilder', () {
    testWidgets('builds with the resolved scope', (tester) async {
      final control = KeyFlowControl();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(control.dispose);

      KeyFlowScope? scopeReceived;
      await tester.pumpWidget(
        KeyFlowScope(
          control: control,
          focusNode: focusNode,
          child: KeyFlowScopeBuilder(
            builder: (context, scope, _) {
              scopeReceived = scope;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(scopeReceived, isNotNull);
      expect(scopeReceived!.control, same(control));
    });

    testWidgets('asserts when no scope is above it', (tester) async {
      // The builder asserts in debug mode; the assertion is caught by the
      // framework and re-surfaced via `takeException`.
      await tester.pumpWidget(
        KeyFlowScopeBuilder(
          builder: (context, scope, _) => const SizedBox(),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('passes the optional child to the builder', (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);
      Widget? receivedChild;
      await tester.pumpWidget(
        KeyFlowScope(
          control: control,
          focusNode: null,
          child: KeyFlowScopeBuilder(
            builder: (context, scope, child) {
              receivedChild = child;
              return child!;
            },
            child: const Text(
              'CHILD',
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      );
      expect(receivedChild, isNotNull);
      expect(find.text('CHILD'), findsOneWidget);
    });
  });
}
