//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

void _noop(BuildContext context, KeyArgs args) {}

const _params = [
  KeyParam(name: 'text', description: 'What to add'),
  KeyParam(name: 'count', type: KeyParamType.integer, required: false),
  KeyParam(name: 'weight', type: KeyParamType.number, required: false),
  KeyParam(name: 'urgent', type: KeyParamType.boolean, required: false),
  KeyParam(name: 'list', required: false, choices: ['home', 'work']),
];

void main() {
  group('KeyArgs.check', () {
    test('takes values that fit and reads them by type', () {
      final args = KeyArgs.check(_params, {
        'text': 'Milk',
        'count': 2,
        'weight': 1,
        'urgent': true,
        'list': 'home',
      });
      expect(args.string('text'), 'Milk');
      expect(args.maybeInteger('count'), 2);
      expect(args.maybeNumber('weight'), 1.0);
      expect(args.maybeBoolean('urgent'), isTrue);
      expect(args.maybeString('list'), 'home');
      expect(args.has('text'), isTrue);
    });

    test('an optional value left out reads as null', () {
      final args = KeyArgs.check(_params, {'text': 'Milk'});
      expect(args.maybeInteger('count'), isNull);
      expect(args.has('count'), isFalse);
    });

    test('a whole double from a browser is an integer', () {
      final args = KeyArgs.check(_params, {'text': 'x', 'count': 3.0});
      expect(args.maybeInteger('count'), 3);
    });

    test('fails on a missing, unknown, mistyped or unlisted value', () {
      expect(() => KeyArgs.check(_params, {}), throwsArgumentError);
      expect(
        () => KeyArgs.check(_params, {'text': 'x', 'colour': 'red'}),
        throwsArgumentError,
      );
      expect(() => KeyArgs.check(_params, {'text': 3}), throwsArgumentError);
      expect(
        () => KeyArgs.check(_params, {'text': 'x', 'count': 2.5}),
        throwsArgumentError,
      );
      expect(
        () => KeyArgs.check(_params, {'text': 'x', 'list': 'garden'}),
        throwsArgumentError,
      );
    });

    test('reading a name the command lacks, or an optional one as required, '
        'is a mistake', () {
      final args = KeyArgs.check(_params, {'text': 'x'});
      expect(() => args.string('colour'), throwsArgumentError);
      expect(() => args.integer('count'), throwsStateError);
    });
  });

  group('commands with params', () {
    KeyTree tree(KeyCommand command) {
      return KeyTree.merge([
        KeyLayer([command]),
      ]);
    }

    test('give tools a JSON schema of their params', () {
      final tools = tree(
        const KeyCommand(
          id: 'add',
          label: 'Add',
          params: _params,
          onRunWithArgs: _noop,
        ),
      ).toToolList();
      expect(tools.single['parameters'], {
        'type': 'object',
        'properties': {
          'text': {'type': 'string', 'description': 'What to add'},
          'count': {'type': 'integer'},
          'weight': {'type': 'number'},
          'urgent': {'type': 'boolean'},
          'list': {
            'type': 'string',
            'enum': ['home', 'work'],
          },
        },
        'required': ['text'],
      });
    });

    test('a command with no params keeps an empty schema', () {
      final tools = tree(
        KeyCommand(id: 'save', label: 'Save', onRun: (_) {}),
      ).toToolList();
      expect(tools.single['parameters'], {
        'type': 'object',
        'properties': <String, Object?>{},
      });
    });

    test('list their params for agents', () {
      final list = tree(
        const KeyCommand(
          id: 'add',
          label: 'Add',
          params: [KeyParam(name: 'text')],
          onRunWithArgs: _noop,
        ),
      ).toCommandList();
      expect(list.single['params'], [
        {'name': 'text', 'type': 'string', 'required': true},
      ]);
    });

    test('are checked when merged', () {
      expect(
        () => tree(
          KeyCommand(
            id: 'a',
            label: 'A',
            params: const [KeyParam(name: 'x')],
            onRun: (_) {},
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => tree(
          KeyCommand(id: 'a', label: 'A', onRun: (_) {}, onRunWithArgs: _noop),
        ),
        throwsArgumentError,
      );
      expect(
        () => tree(
          const KeyCommand(
            id: 'a',
            label: 'A',
            params: [
              KeyParam(name: 'x'),
              KeyParam(name: 'x'),
            ],
            onRunWithArgs: _noop,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => tree(
          const KeyCommand(
            id: 'a',
            label: 'A',
            params: [KeyParam(name: 'bad name')],
            onRunWithArgs: _noop,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => tree(
          const KeyCommand(
            id: 'a',
            label: 'A',
            params: [
              KeyParam(name: 'n', type: KeyParamType.integer, choices: ['1']),
            ],
            onRunWithArgs: _noop,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
