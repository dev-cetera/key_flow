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

import '../helpers.dart';

Widget _wrap(Widget child) => MaterialApp(home: Material(child: child));

void main() {
  tearDown(() async {
    await resetHardwareKeyboard();
  });

  group('text field suppression — default (suppressBareKeysInTextFields: true)',
      () {
    testWidgets('bare key DOES NOT fire when text field has focus',
        (tester) async {
      final actionKey = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          actionKey: const [KeyActivator.logical(LogicalKeyboardKey.keyG)],
        },
        callbacks: {actionKey: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final textFocus = FocusNode();
      addTearDown(textFocus.dispose);

      await tester.pumpWidget(
        _wrap(
          KeyFlowFocus(
            control: control,
            autofocus: true,
            child: TextField(focusNode: textFocus),
          ),
        ),
      );
      await tester.pump();
      textFocus.requestFocus();
      await tester.pumpAndSettle();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      expect(fired, 0, reason: 'bare key suppressed in text field');
    });

    testWidgets('modifier-bearing chord DOES fire in text field',
        (tester) async {
      // Use `control: true` (literal Ctrl on every platform) to avoid the
      // meta-vs-ctrl ambiguity that depends on defaultTargetPlatform.
      final actionKey = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          actionKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG, control: true),
          ],
        },
        callbacks: {actionKey: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final textFocus = FocusNode();
      addTearDown(textFocus.dispose);

      await tester.pumpWidget(
        _wrap(
          KeyFlowFocus(
            control: control,
            autofocus: true,
            child: TextField(focusNode: textFocus),
          ),
        ),
      );
      await tester.pump();
      textFocus.requestFocus();
      await tester.pumpAndSettle();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      expect(fired, 1);
    });

    testWidgets(
        'multi-step bare-key sequence is suppressed in a text field — even '
        'the prefix is blocked', (tester) async {
      final actionKey = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          actionKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG),
            KeyActivator.logical(LogicalKeyboardKey.keyI),
          ],
        },
        callbacks: {actionKey: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final textFocus = FocusNode();
      addTearDown(textFocus.dispose);

      await tester.pumpWidget(
        _wrap(
          KeyFlowFocus(
            control: control,
            autofocus: true,
            child: TextField(focusNode: textFocus),
          ),
        ),
      );
      await tester.pump();
      textFocus.requestFocus();
      await tester.pumpAndSettle();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyI);
      expect(fired, 0, reason: 'sequence cannot start in a text field');
    });
  });

  group('text field suppression — disabled (suppressBareKeysInTextFields: false)',
      () {
    testWidgets('bare key fires even when text field is focused',
        (tester) async {
      final actionKey = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        suppressBareKeysInTextFields: false,
        mappings: {
          actionKey: const [KeyActivator.logical(LogicalKeyboardKey.keyG)],
        },
        callbacks: {actionKey: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      final textFocus = FocusNode();
      addTearDown(textFocus.dispose);

      await tester.pumpWidget(
        _wrap(
          KeyFlowFocus(
            control: control,
            autofocus: true,
            child: TextField(focusNode: textFocus),
          ),
        ),
      );
      await tester.pump();
      textFocus.requestFocus();
      await tester.pumpAndSettle();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      expect(fired, 1);
    });
  });

  group('text field suppression — no text field focused', () {
    testWidgets('bare key fires normally outside text fields',
        (tester) async {
      final actionKey = UniqueKey();
      var fired = 0;
      final control = KeyFlowControl(
        mappings: {
          actionKey: const [KeyActivator.logical(LogicalKeyboardKey.keyG)],
        },
        callbacks: {actionKey: (_, __) => fired += 1},
      );
      addTearDown(control.dispose);

      await tester.pumpWidget(
        _wrap(
          KeyFlowFocus(
            control: control,
            autofocus: true,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      expect(fired, 1);
    });
  });
}
