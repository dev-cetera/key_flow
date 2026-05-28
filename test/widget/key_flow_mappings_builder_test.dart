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
  group('KeyFlowMappingsBuilder — explicit control', () {
    testWidgets('builds with the given control', (tester) async {
      final control = KeyFlowControl(
        mappings: {
          const ValueKey('x'): const [
            KeyActivator.logical(LogicalKeyboardKey.keyA),
          ],
        },
      );
      addTearDown(control.dispose);

      KeyFlowControl? received;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowMappingsBuilder(
            control: control,
            builder: (context, c, _) {
              received = c;
              return Text('count=${c.mappings.length}');
            },
          ),
        ),
      );
      expect(received, same(control));
      expect(find.text('count=1'), findsOneWidget);
    });

    testWidgets('rebuilds when mappings change on the explicit control',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowMappingsBuilder(
            control: control,
            builder: (context, c, _) => Text('count=${c.mappings.length}'),
          ),
        ),
      );
      expect(find.text('count=0'), findsOneWidget);

      control.addCombination(
        const ValueKey('x'),
        const [KeyActivator.logical(LogicalKeyboardKey.keyA)],
        (_, __) {},
      );
      await tester.pump();
      expect(find.text('count=1'), findsOneWidget);
    });
  });

  group('KeyFlowMappingsBuilder — control via KeyFlowScope', () {
    testWidgets('falls back to KeyFlowScope.of when no control is given',
        (tester) async {
      final control = KeyFlowControl(
        mappings: {
          const ValueKey('y'): const [
            KeyActivator.logical(LogicalKeyboardKey.keyB),
          ],
        },
      );
      addTearDown(control.dispose);

      KeyFlowControl? received;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowScope(
            control: control,
            focusNode: null,
            child: KeyFlowMappingsBuilder(
              builder: (context, c, _) {
                received = c;
                return Text('n=${c.mappings.length}');
              },
            ),
          ),
        ),
      );
      expect(received, same(control));
      expect(find.text('n=1'), findsOneWidget);
    });

    testWidgets('asserts when no scope and no control', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowMappingsBuilder(
            builder: (context, c, _) => const SizedBox(),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('child passthrough', () {
    testWidgets('passes child argument to the builder', (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      Widget? receivedChild;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowMappingsBuilder(
            control: control,
            builder: (context, c, child) {
              receivedChild = child;
              return child!;
            },
            child: const Text('SENTINEL'),
          ),
        ),
      );
      expect(receivedChild, isNotNull);
      expect(find.text('SENTINEL'), findsOneWidget);
    });
  });
}
