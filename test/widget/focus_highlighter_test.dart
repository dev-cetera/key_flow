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

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FocusHighlighter', () {
    testWidgets(
        'applies the default unfocused decoration (null) when not focused',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Focus(
            child: FocusHighlighter(
              child: Text('hello'),
            ),
          ),
        ),
      );
      // A Container is rendered with null decoration.
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers, isNotEmpty);
      // At least one should have a null decoration (the not-focused branch).
      expect(containers.any((c) => c.decoration == null), isTrue);
    });

    testWidgets('applies the focus decoration when focused', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Focus(
            focusNode: node,
            autofocus: true,
            child: const FocusHighlighter(
              child: Text('hi'),
            ),
          ),
        ),
      );
      await tester.pump();
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(
        containers.any(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration! as BoxDecoration).color != null,
        ),
        isTrue,
      );
    });

    testWidgets('applies custom hasFocusDecoration', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      const custom = BoxDecoration(color: Color(0xFF112233));
      await tester.pumpWidget(
        MaterialApp(
          home: Focus(
            focusNode: node,
            autofocus: true,
            child: const FocusHighlighter(
              hasFocusDecoration: custom,
              child: Text('hi'),
            ),
          ),
        ),
      );
      await tester.pump();
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(
        containers.any((c) => c.decoration == custom),
        isTrue,
      );
    });

    testWidgets('applies custom hasNoFocusDecoration', (tester) async {
      const custom = BoxDecoration(color: Color(0xFFAA0000));
      await tester.pumpWidget(
        const MaterialApp(
          home: Focus(
            child: FocusHighlighter(
              hasNoFocusDecoration: custom,
              child: Text('hi'),
            ),
          ),
        ),
      );
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(
        containers.any((c) => c.decoration == custom),
        isTrue,
      );
    });

    testWidgets('tapping the child requests focus on the scope\'s node',
        (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: KeyFlowFocus(
            control: control,
            child: const FocusHighlighter(
              child: Center(
                child: SizedBox(
                  key: ValueKey('tap-target'),
                  width: 80,
                  height: 80,
                  child: ColoredBox(color: Color(0xFF112233)),
                ),
              ),
            ),
          ),
        ),
      );
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode?.hasFocus, isFalse);

      await tester.tap(find.byKey(const ValueKey('tap-target')));
      await tester.pump();
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode?.hasFocus, isTrue);
    });

    testWidgets('renders without child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Focus(
            child: FocusHighlighter(),
          ),
        ),
      );
      expect(find.byType(FocusHighlighter), findsOneWidget);
    });
  });
}
