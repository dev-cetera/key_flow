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

class _NamedKey extends DescriptiveKey {
  const _NamedKey(super.description);
}

void main() {
  group('UniqueActionKey', () {
    test('two instances with the same description are NOT equal', () {
      final a = UniqueActionKey((_) => 'X');
      final b = UniqueActionKey((_) => 'X');
      expect(a == b, isFalse);
    });

    test('is recognized as a DescriptiveKey', () {
      final key = UniqueActionKey((_) => 'X');
      expect(key, isA<DescriptiveKey>());
    });

    test('description callback receives a BuildContext', () {
      BuildContext? captured;
      final key = UniqueActionKey((ctx) {
        captured = ctx;
        return 'hi';
      });
      // Drive the callback through a widget so a real context is available.
      // We assert later via the widget test.
      expect(captured, isNull);
      expect(key.description, isA<String Function(BuildContext)>());
    });

    testWidgets('description() returns its result inside a widget',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              final key = UniqueActionKey((_) => 'INBOX');
              return Text(key.description(context));
            },
          ),
        ),
      );
      expect(find.text('INBOX'), findsOneWidget);
    });
  });

  group('DescriptiveKey (custom subclass)', () {
    test('two instances created with the same description ARE equal', () {
      // DescriptiveKey extends LocalKey, which uses Object identity by
      // default — but since `description` is a function reference, equal
      // function references should make the keys equal. We verify the
      // hashCode/equality behavior is sane for the subclass.
      const a = _NamedKey(_alwaysSameFn);
      const b = _NamedKey(_alwaysSameFn);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('KeyFlowKeyNameBuilder', () {
    testWidgets('uses DescriptiveKey.description() when key implements it',
        (tester) async {
      final key = UniqueActionKey((_) => 'Toggle Theme');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowKeyNameBuilder(
            mappingKey: key,
            builder: (context, name, _) => Text(name),
          ),
        ),
      );
      expect(find.text('Toggle Theme'), findsOneWidget);
    });

    testWidgets('falls back to toString for non-descriptive keys',
        (tester) async {
      const key = ValueKey('plain');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowKeyNameBuilder<ValueKey<String>>(
            mappingKey: key,
            builder: (context, name, _) => Text(name),
          ),
        ),
      );
      expect(find.text(key.toString()), findsOneWidget);
    });

    testWidgets('passes the optional child through to the builder',
        (tester) async {
      final key = UniqueActionKey((_) => 'name');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowKeyNameBuilder(
            mappingKey: key,
            builder: (context, name, child) => Row(
              children: [Text(name), child ?? const SizedBox.shrink()],
            ),
            child: const Text('CHILD'),
          ),
        ),
      );
      expect(find.text('name'), findsOneWidget);
      expect(find.text('CHILD'), findsOneWidget);
    });

    testWidgets('description function is given the same context that builds',
        (tester) async {
      BuildContext? descriptionCtx;
      BuildContext? builderCtx;
      final key = UniqueActionKey((ctx) {
        descriptionCtx = ctx;
        return 'D';
      });
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: KeyFlowKeyNameBuilder(
            mappingKey: key,
            builder: (context, name, _) {
              builderCtx = context;
              return Text(name);
            },
          ),
        ),
      );
      expect(descriptionCtx, isNotNull);
      expect(builderCtx, isNotNull);
      // The contexts are the same Element walker — the builder context is
      // the KeyFlowKeyNameBuilder's element context.
      expect(identical(descriptionCtx, builderCtx), isTrue);
    });
  });
}

String _alwaysSameFn(BuildContext _) => 'X';
