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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

void main() {
  group('KeyScript JSON', () {
    test('reads every step and writes it back the same', () {
      final json = {
        'cursors': [
          {'id': 'ana', 'kind': 'touch', 'label': 'Ana', 'color': '#FFE91E63'},
          {'id': 'ben', 'kind': 'mouse'},
        ],
        'speed': 2.0,
        'steps': [
          {'do': 'caption', 'text': 'Hello'},
          {'do': 'point', 'at': 'list', 'cursor': 'ben'},
          {'do': 'tap', 'at': 'row-2/tick'},
          {'do': 'hold', 'at': 'tick[1]', 'ms': 900},
          {'do': 'drag', 'at': 'card', 'to': 'done'},
          {
            'do': 'drag',
            'at': 'card',
            'by': [0.0, 120.0],
            'holdMs': 500,
          },
          {'do': 'type', 'text': 'Milk', 'at': 'field', 'submit': true},
          {'do': 'keys', 'keys': 'meta+k'},
          {
            'do': 'run',
            'command': 'add',
            'args': {'text': 'Milk'},
          },
          {'do': 'scrollTo', 'at': 'row-80', 'within': 'rows'},
          {'do': 'wait', 'ms': 300},
          {'do': 'waitFor', 'at': 'saved', 'ms': 2000},
          {
            'do': 'together',
            'steps': [
              {'do': 'tap', 'at': 'a', 'cursor': 'ana'},
              {'do': 'tap', 'at': 'b', 'cursor': 'ben'},
            ],
          },
        ],
      };
      final script = KeyScript.fromJson(json);
      expect(script.cursors, hasLength(2));
      expect(script.cursors.first.kind, KeyCursorKind.touch);
      expect(script.speed, 2);
      expect(script.steps[2], isA<KeyTapStep>());
      expect((script.steps[3] as KeyHoldStep).duration.inMilliseconds, 900);
      expect(script.toJson(), json);
    });

    test('reads JSON text', () {
      final script = KeyScript.parse(
        jsonEncode({
          'steps': [
            {'do': 'tap', 'at': 'x'},
          ],
        }),
      );
      expect((script.steps.single as KeyTapStep).at, 'x');
    });

    test('fails loudly on anything it does not know', () {
      Map<String, Object?> one(Map<String, Object?> step) => {
        'steps': [step],
      };
      for (final bad in <Map<String, Object?>>[
        one({'do': 'click', 'at': 'x'}),
        one({'do': 'tap'}),
        one({'do': 'tap', 'at': 'x', 'colour': 'red'}),
        one({'do': 'caption', 'text': 'x', 'cursor': 'ana'}),
        one({
          'do': 'drag',
          'at': 'x',
          'to': 'y',
          'by': [1, 2],
        }),
        one({'do': 'drag', 'at': 'x'}),
        one({'do': 'wait', 'ms': -1}),
        {'steps': <Object?>[], 'speed': 0},
        {
          'steps': <Object?>[],
          'cursors': [
            {'id': 'a', 'kind': 'pen'},
          ],
        },
        {'steps': <Object?>[], 'extra': true},
      ]) {
        expect(
          () => KeyScript.fromJson(bad),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
  });

  group('KeyPlace', () {
    test('reads an id, the anchors around it and a count', () {
      final place = KeyPlace.parse('list/row-2/tick[1]');
      expect(place.id, 'tick');
      expect(place.within, ['list', 'row-2']);
      expect(place.index, 1);
      expect(place.toString(), 'list/row-2/tick[1]');
    });

    test('takes a command id with dots as it is', () {
      final place = KeyPlace.parse('go.inbox');
      expect(place.id, 'go.inbox');
      expect(place.within, isEmpty);
      expect(place.index, isNull);
    });

    test('fails on an empty part', () {
      expect(() => KeyPlace.parse('a//b'), throwsFormatException);
      expect(() => KeyPlace.parse(''), throwsFormatException);
    });
  });

  group('KeyActivator.toStroke', () {
    test('makes a press the activator accepts', () {
      for (final spec in ['meta+k', 'g', '?', 'shift+enter', 'alt+f6']) {
        final activator = KeyActivator.parse(spec);
        expect(activator.accepts(activator.toStroke()), isTrue, reason: spec);
      }
    });
  });
}
