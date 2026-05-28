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

// Internal AlwaysTappable is not exported; we reach it indirectly via
// FocusHighlighter, which uses it for its tap-to-focus behavior. The
// FocusHighlighter tests cover the user-visible "child still tappable"
// contract.

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FocusHighlighter tap propagation (AlwaysTappable)', () {
    testWidgets('child onPressed still fires when wrapped', (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      var childTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: KeyFlowFocus(
            control: control,
            child: FocusHighlighter(
              child: ElevatedButton(
                onPressed: () => childTapCount += 1,
                child: const Text('tap me'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tap me'));
      await tester.pump();
      // Both the inner button and the AlwaysTappable wrapper see the tap.
      expect(childTapCount, 1);
      // ignore: invalid_use_of_protected_member
      expect(control.$focusNode?.hasFocus, isTrue);
    });

    testWidgets('multiple taps each fire the child callback', (tester) async {
      final control = KeyFlowControl();
      addTearDown(control.dispose);

      var childTapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: KeyFlowFocus(
            control: control,
            child: FocusHighlighter(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => childTapCount += 1,
                child: const SizedBox(width: 50, height: 50),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(childTapCount, 2);
    });
  });
}
