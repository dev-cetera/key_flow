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
  group('ControlMappingsBuilder', () {
    testWidgets('initially shows nothing when no control has focus',
        (tester) async {
      final keyA = UniqueKey();
      final control = KeyFlowControl(
        mappings: {
          keyA: const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        },
      );
      addTearDown(control.dispose);

      Map<Key, List<KeyActivator>>? received;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ControlMappingsBuilder(
            controls: [control],
            builder: (context, m, _) {
              received = m;
              return Text('n=${m.length}');
            },
          ),
        ),
      );
      // No KeyFlowFocus mounts the control's focus node, so hasFocus is
      // false and the builder reports no mappings.
      expect(received, isNotNull);
      expect(received, isEmpty);
      expect(find.text('n=0'), findsOneWidget);
    });

    testWidgets('shows mappings only for focused controls', (tester) async {
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      final controlA = KeyFlowControl(
        mappings: {
          keyA: const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        },
      );
      final controlB = KeyFlowControl(
        mappings: {
          keyB: const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
        },
      );
      addTearDown(controlA.dispose);
      addTearDown(controlB.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              KeyFlowFocus(
                control: controlA,
                autofocus: true,
                child: const SizedBox(width: 10, height: 10),
              ),
              KeyFlowFocus(
                control: controlB,
                child: const SizedBox(width: 10, height: 10),
              ),
              Expanded(
                child: ControlMappingsBuilder(
                  controls: [controlA, controlB],
                  builder: (context, m, _) => Text('n=${m.length}'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      // Only controlA has focus → only one mapping is exposed.
      expect(find.text('n=1'), findsOneWidget);
    });

    testWidgets('rebuilds when focus changes', (tester) async {
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      final controlA = KeyFlowControl(
        mappings: {
          keyA: const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        },
      );
      final controlB = KeyFlowControl(
        mappings: {
          keyB: const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
        },
      );
      addTearDown(controlA.dispose);
      addTearDown(controlB.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              KeyFlowFocus(
                control: controlA,
                autofocus: true,
                child: const SizedBox(width: 10, height: 10),
              ),
              KeyFlowFocus(
                control: controlB,
                child: const SizedBox(width: 10, height: 10),
              ),
              Expanded(
                child: ControlMappingsBuilder(
                  controls: [controlA, controlB],
                  builder: (context, m, _) => Text('n=${m.length}'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('n=1'), findsOneWidget);

      // ignore: invalid_use_of_protected_member
      controlB.$focusNode?.requestFocus();
      await tester.pump();
      // Now only controlB has focus → still only one mapping (but different).
      expect(find.text('n=1'), findsOneWidget);
    });

    testWidgets('combines mappings when multiple focused controls share scope',
        (tester) async {
      // A single focusNode reused across two scopes — both controls
      // become "focused" simultaneously via the same node.
      final shared = FocusNode();
      addTearDown(shared.dispose);
      final keyA = UniqueKey();
      final keyB = UniqueKey();
      final controlA = KeyFlowControl(
        mappings: {
          keyA: const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        },
      );
      final controlB = KeyFlowControl(
        mappings: {
          keyB: const [KeyActivator.logical(LogicalKeyboardKey.keyB)],
        },
      );
      // Both controls point to the same shared focus node — this models
      // the case where two nested KeyFlowFocus widgets coincidentally
      // share a node (e.g. via custom logic).
      // ignore: invalid_use_of_protected_member
      controlA.$focusNode = shared;
      // ignore: invalid_use_of_protected_member
      controlB.$focusNode = shared;
      addTearDown(controlA.dispose);
      addTearDown(controlB.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Focus(
                focusNode: shared,
                autofocus: true,
                child: const SizedBox(width: 10, height: 10),
              ),
              Expanded(
                child: ControlMappingsBuilder(
                  controls: [controlA, controlB],
                  builder: (context, m, _) => Text('n=${m.length}'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('n=2'), findsOneWidget);
    });

    testWidgets('updates when a focused control adds a mapping',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              KeyFlowFocus(
                control: control,
                autofocus: true,
                child: const SizedBox(width: 10, height: 10),
              ),
              Expanded(
                child: ControlMappingsBuilder(
                  controls: [control],
                  builder: (context, m, _) => Text('n=${m.length}'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('n=0'), findsOneWidget);

      control.addCombination(
        UniqueKey(),
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      await tester.pump();
      expect(find.text('n=1'), findsOneWidget);
    });

    testWidgets('passes child through to the builder', (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ControlMappingsBuilder(
            controls: [control],
            builder: (context, m, child) => child!,
            child: const Text('PASSED'),
          ),
        ),
      );
      expect(find.text('PASSED'), findsOneWidget);
    });
  });
}
