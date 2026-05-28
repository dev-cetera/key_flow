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

  group('focus node ownership', () {
    testWidgets('creates an owned FocusNode when none is provided',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          child: const SizedBox(),
        ),
      );
      // The control's focusNode pointer is set during build to the
      // internally owned node.
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNotNull);
    });

    testWidgets('uses the externally provided FocusNode', (tester) async {
      final control = KeyFlowControl();
      final external = FocusNode();
      addTearDown(external.dispose);
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          focusNode: external,
          child: const SizedBox(),
        ),
      );
      // ignore: invalid_use_of_protected_member
      expect(identical(control.$focusNode, external), isTrue);
    });

    testWidgets('disposing widget clears control pointer to owned node',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          child: const SizedBox(),
        ),
      );
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNotNull);

      await tester.pumpWidget(const SizedBox());
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNull);
    });

    testWidgets('disposing widget clears pointer to external node',
        (tester) async {
      final control = KeyFlowControl();
      final external = FocusNode();
      addTearDown(external.dispose);
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          focusNode: external,
          child: const SizedBox(),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNull);
    });

    testWidgets('swapping external -> internal -> external preserves usage',
        (tester) async {
      final control = KeyFlowControl();
      final externalA = FocusNode();
      final externalB = FocusNode();
      addTearDown(externalA.dispose);
      addTearDown(externalB.dispose);
      addTearDown(control.dispose);

      Widget build({FocusNode? f}) => KeyFlowFocus(
            control: control,
            focusNode: f,
            child: const SizedBox(),
          );

      await tester.pumpWidget(build(f: externalA));
      // ignore: invalid_use_of_protected_member
      expect(identical(control.$focusNode, externalA), isTrue);

      await tester.pumpWidget(build());
      // Now an internal node was created.
      // ignore: invalid_use_of_protected_member
      expect(identical(control.$focusNode, externalA), isFalse);
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode, isNotNull);

      await tester.pumpWidget(build(f: externalB));
      // ignore: invalid_use_of_protected_member
      expect(identical(control.$focusNode, externalB), isTrue);
    });
  });

  group('autofocus', () {
    testWidgets('autofocus: true focuses the node after first frame',
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
      await tester.pump();
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode?.hasFocus, isTrue);
    });

    testWidgets('autofocus: false does not focus', (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        KeyFlowFocus(
          control: control,
          child: const SizedBox(),
        ),
      );
      await tester.pump();
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode?.hasFocus, isFalse);
    });
  });

  group('onFocusChange', () {
    testWidgets('fires when focus is acquired', (tester) async {
      bool? lastFocus;
      final control = KeyFlowControl(
        onFocusChange: (_, hasFocus) => lastFocus = hasFocus,
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
      expect(lastFocus, isTrue);
    });

    testWidgets('fires when focus is lost', (tester) async {
      bool? lastFocus;
      final control = KeyFlowControl(
        onFocusChange: (_, hasFocus) => lastFocus = hasFocus,
      );
      addTearDown(control.dispose);

      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        Column(
          children: [
            KeyFlowFocus(
              control: control,
              autofocus: true,
              child: const SizedBox(),
            ),
            Focus(focusNode: node, child: const SizedBox()),
          ],
        ),
      );
      await tester.pump();
      expect(lastFocus, isTrue);
      node.requestFocus();
      await tester.pump();
      expect(lastFocus, isFalse);
    });

    testWidgets('not wired when onFocusChange is null', (tester) async {
      // Sanity: the control without onFocusChange should not throw on
      // focus change.
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
      // No assertion needed beyond "did not throw".
    });
  });

  group('null control', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const KeyFlowFocus(
          control: null,
          child: SizedBox(),
        ),
      );
      // No exceptions.
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('key event dispatch', () {
    testWidgets('triggers the mapped callback', (tester) async {
      final key = UniqueKey();
      var firedCount = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.keyZ)],
        },
        callbacks: {
          key: (_, __) => firedCount += 1,
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
      await simulateKeyDownEvent(LogicalKeyboardKey.keyZ);
      expect(firedCount, 1);
    });

    testWidgets('unmapped keys do not fire any callback', (tester) async {
      final key = UniqueKey();
      var firedCount = 0;
      final control = KeyFlowControl(
        mappings: {
          key: const [KeyActivator.logical(LogicalKeyboardKey.keyZ)],
        },
        callbacks: {
          key: (_, __) => firedCount += 1,
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
      await simulateKeyDownEvent(LogicalKeyboardKey.keyA);
      expect(firedCount, 0);
    });
  });
}
