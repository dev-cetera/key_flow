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
  group('FocusBuilder', () {
    testWidgets('renders hasNoFocusBuilder when not focused', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(
            child: FocusBuilder(
              hasFocusBuilder: (_, __) => const Text('FOCUS'),
              hasNoFocusBuilder: (_, __) => const Text('NO_FOCUS'),
            ),
          ),
        ),
      );
      expect(find.text('NO_FOCUS'), findsOneWidget);
      expect(find.text('FOCUS'), findsNothing);
    });

    testWidgets('renders hasFocusBuilder when focused', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(
            focusNode: node,
            autofocus: true,
            child: FocusBuilder(
              hasFocusBuilder: (_, __) => const Text('FOCUS'),
              hasNoFocusBuilder: (_, __) => const Text('NO_FOCUS'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('FOCUS'), findsOneWidget);
      expect(find.text('NO_FOCUS'), findsNothing);
    });

    testWidgets('updates when focus moves to a sibling', (tester) async {
      final nodeA = FocusNode(debugLabel: 'A');
      final nodeB = FocusNode(debugLabel: 'B');
      addTearDown(nodeA.dispose);
      addTearDown(nodeB.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            child: Column(
              children: [
                Focus(
                  focusNode: nodeA,
                  autofocus: true,
                  child: FocusBuilder(
                    hasFocusBuilder: (_, __) => const Text('A_FOCUS'),
                    hasNoFocusBuilder: (_, __) => const Text('A_NO'),
                  ),
                ),
                Focus(
                  focusNode: nodeB,
                  child: const SizedBox(width: 1, height: 1),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A_FOCUS'), findsOneWidget);
      nodeB.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('A_NO'), findsOneWidget);
    });

    testWidgets('child is passed through to both builders', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(
            child: FocusBuilder(
              hasFocusBuilder: (_, c) => c!,
              hasNoFocusBuilder: (_, c) => c!,
              child: const Text('SHARED_CHILD'),
            ),
          ),
        ),
      );
      expect(find.text('SHARED_CHILD'), findsOneWidget);
    });
  });
}
