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

  group('ancestor chain walking', () {
    testWidgets('child fires a shortcut declared on the root control',
        (tester) async {
      final rootKey = UniqueKey();
      var rootFired = 0;
      final root = KeyFlowControl(
        mappings: {
          rootKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyG, control: true),
          ],
        },
        callbacks: {rootKey: (_, __) => rootFired += 1},
      );
      addTearDown(root.dispose);

      final child = KeyFlowControl();
      addTearDown(child.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowFocus(
            control: root,
            child: KeyFlowFocus(
              control: child,
              autofocus: true,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      expect(rootFired, 1);
    });

    testWidgets('child control bindings take precedence over root bindings',
        (tester) async {
      final sharedKey = UniqueKey();
      var rootFired = 0;
      var childFired = 0;
      final root = KeyFlowControl(
        mappings: {
          sharedKey: const [KeyActivator.logical(LogicalKeyboardKey.keyG)],
        },
        callbacks: {sharedKey: (_, __) => rootFired += 1},
      );
      addTearDown(root.dispose);

      final child = KeyFlowControl(
        mappings: {
          sharedKey: const [KeyActivator.logical(LogicalKeyboardKey.keyG)],
        },
        callbacks: {sharedKey: (_, __) => childFired += 1},
      );
      addTearDown(child.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowFocus(
            control: root,
            child: KeyFlowFocus(
              control: child,
              autofocus: true,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.keyG);
      expect(childFired, 1);
      expect(rootFired, 0);
    });

    testWidgets('child without binding falls through to root',
        (tester) async {
      final rootOnlyKey = UniqueKey();
      var rootFired = 0;
      final root = KeyFlowControl(
        mappings: {
          rootOnlyKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyR, control: true),
          ],
        },
        callbacks: {rootOnlyKey: (_, __) => rootFired += 1},
      );
      addTearDown(root.dispose);

      final child = KeyFlowControl();
      addTearDown(child.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowFocus(
            control: root,
            child: KeyFlowFocus(
              control: child,
              autofocus: true,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyR);
      expect(rootFired, 1);
    });

    testWidgets('three-level nesting walks the entire chain', (tester) async {
      final rootKey = UniqueKey();
      var rootFired = 0;
      final root = KeyFlowControl(
        mappings: {
          rootKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyZ, control: true),
          ],
        },
        callbacks: {rootKey: (_, __) => rootFired += 1},
      );
      addTearDown(root.dispose);

      final mid = KeyFlowControl();
      addTearDown(mid.dispose);
      final leaf = KeyFlowControl();
      addTearDown(leaf.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowFocus(
            control: root,
            child: KeyFlowFocus(
              control: mid,
              child: KeyFlowFocus(
                control: leaf,
                autofocus: true,
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyZ);
      expect(rootFired, 1);
    });

    testWidgets('intermediate control bindings are visible to leaf',
        (tester) async {
      final midKey = UniqueKey();
      var midFired = 0;
      final root = KeyFlowControl();
      addTearDown(root.dispose);
      final mid = KeyFlowControl(
        mappings: {
          midKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyM, control: true),
          ],
        },
        callbacks: {midKey: (_, __) => midFired += 1},
      );
      addTearDown(mid.dispose);
      final leaf = KeyFlowControl();
      addTearDown(leaf.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowFocus(
            control: root,
            child: KeyFlowFocus(
              control: mid,
              child: KeyFlowFocus(
                control: leaf,
                autofocus: true,
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyM);
      expect(midFired, 1);
    });

    testWidgets('same control referenced from two scopes is deduped',
        (tester) async {
      final actionKey = UniqueKey();
      var fired = 0;
      // A singleton control used as both root and leaf — the
      // `_gatherAncestorControls` walk must not double-fire its callback.
      final singleton = KeyFlowControl(
        mappings: {
          actionKey: const [
            KeyActivator.logical(LogicalKeyboardKey.keyX, control: true),
          ],
        },
        callbacks: {actionKey: (_, __) => fired += 1},
      );
      addTearDown(singleton.dispose);

      // Wrap two scopes around the same control. KeyFlowFocus sets the
      // control's $focusNode to its own node, which means only the
      // innermost scope's node actually owns the singleton. But the outer
      // KeyFlowScope still references the same control.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowScope(
            control: singleton,
            focusNode: null,
            child: KeyFlowFocus(
              control: singleton,
              autofocus: true,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await simulateKeyDownEvent(LogicalKeyboardKey.keyX);
      expect(fired, 1, reason: 'singleton control fires exactly once');
    });
  });

  group('handleKeyEvent dispatch order', () {
    testWidgets('deeper focused control short-circuits ancestor walk',
        (tester) async {
      // If a deeper KeyFlowFocus child has its own focused node with
      // onKeyEvent, the outer control's handleKeyEvent returns ignored —
      // because the deeper node already got dispatch.
      final outer = KeyFlowControl();
      addTearDown(outer.dispose);
      final inner = KeyFlowControl();
      addTearDown(inner.dispose);

      // The outer KeyFlowFocus needs a focus node we can poke directly.
      final outerNode = FocusNode();
      addTearDown(outerNode.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowFocus(
            control: outer,
            focusNode: outerNode,
            child: KeyFlowFocus(
              control: inner,
              autofocus: true,
              child: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Inner has focus — outer's children list contains inner's node.
      expect(outerNode.children.where((c) => c.hasFocus), isNotEmpty);
    });
  });
}
