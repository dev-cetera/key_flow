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

import 'package:meta/meta.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What kind of value a [KeyParam] takes.
enum KeyParamType {
  /// Text.
  string('string'),

  /// A whole number.
  integer('integer'),

  /// Any number.
  number('number'),

  /// True or false.
  boolean('boolean');

  /// Its name in a JSON schema.
  final String jsonName;

  const KeyParamType(this.jsonName);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A value a command takes when code or an agent runs it: the name of a list
/// to add to, the text of a new item.
///
/// A command run from its keys, a menu, the palette or a linked control is
/// given no values, so give such a command no required params, or hide it
/// from those surfaces with [KeyCommand.hiddenFrom].
@immutable
final class KeyParam {
  /// Its name: letters, digits and `_`.
  final String name;

  /// What kind of value it takes.
  final KeyParamType type;

  /// What it is for, for agents.
  final String? description;

  /// Whether a value must be given.
  final bool required;

  /// For a [KeyParamType.string], the only values it accepts; empty for any.
  final List<String> choices;

  const KeyParam({
    required this.name,
    this.type = KeyParamType.string,
    this.description,
    this.required = true,
    this.choices = const [],
  });

  /// It as a JSON-schema property, for [KeyTree.toToolList].
  Map<String, Object?> toJsonSchema() {
    return {
      'type': type.jsonName,
      'description': ?description,
      if (choices.isNotEmpty) 'enum': choices,
    };
  }

  /// It as plain data, for [KeyTree.toCommandList].
  Map<String, Object?> toJson() {
    return {
      'name': name,
      'type': type.jsonName,
      'description': ?description,
      'required': required,
      if (choices.isNotEmpty) 'choices': choices,
    };
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The values a command was run with, checked against its [KeyParam]s.
///
/// Read each with the getter for its type. Reading a name the command does
/// not declare, or a required one as optional, is a mistake in the command
/// and throws.
@immutable
final class KeyArgs {
  final List<KeyParam> _params;
  final Map<String, Object?> _values;

  const KeyArgs._(this._params, this._values);

  /// No values, for a command with no params.
  static const none = KeyArgs._([], {});

  /// Checks [values] against [params].
  ///
  /// Throws an [ArgumentError] for a name not among [params], a required one
  /// left out, a value of the wrong type or one not among a param's choices.
  factory KeyArgs.check(List<KeyParam> params, Map<String, Object?> values) {
    final byName = {for (final param in params) param.name: param};
    for (final name in values.keys) {
      if (!byName.containsKey(name)) {
        throw ArgumentError.value(
          name,
          'args',
          'not a param; it takes ${byName.keys.join(', ')}',
        );
      }
    }
    final checked = <String, Object?>{};
    for (final param in params) {
      final value = values[param.name];
      if (value == null) {
        if (param.required) {
          throw ArgumentError.value(values, 'args', '"${param.name}" missing');
        }
        continue;
      }
      checked[param.name] = _coerce(param, value);
    }
    return KeyArgs._(List.unmodifiable(params), Map.unmodifiable(checked));
  }

  static Object _coerce(KeyParam param, Object value) {
    Never wrong() {
      throw ArgumentError.value(
        value,
        param.name,
        'should be a ${param.type.jsonName}',
      );
    }

    switch (param.type) {
      case KeyParamType.string:
        if (value is! String) wrong();
        if (param.choices.isNotEmpty && !param.choices.contains(value)) {
          throw ArgumentError.value(
            value,
            param.name,
            'should be one of ${param.choices.join(', ')}',
          );
        }
        return value;
      case KeyParamType.integer:
        if (value is int) return value;
        // JSON from a browser gives every number as a double.
        if (value is double && value == value.truncateToDouble()) {
          return value.toInt();
        }
        wrong();
      case KeyParamType.number:
        if (value is! num) wrong();
        return value.toDouble();
      case KeyParamType.boolean:
        if (value is! bool) wrong();
        return value;
    }
  }

  /// Whether a value was given for [name].
  bool has(String name) {
    _param(name);
    return _values.containsKey(name);
  }

  /// The text given for the required param [name].
  String string(String name) => _required<String>(name);

  /// The text given for the optional param [name], if any.
  String? maybeString(String name) => _optional<String>(name);

  /// The whole number given for the required param [name].
  int integer(String name) => _required<int>(name);

  /// The whole number given for the optional param [name], if any.
  int? maybeInteger(String name) => _optional<int>(name);

  /// The number given for the required param [name].
  double number(String name) => _required<double>(name);

  /// The number given for the optional param [name], if any.
  double? maybeNumber(String name) => _optional<double>(name);

  /// The value given for the required param [name].
  bool boolean(String name) => _required<bool>(name);

  /// The value given for the optional param [name], if any.
  bool? maybeBoolean(String name) => _optional<bool>(name);

  /// The values as plain data.
  Map<String, Object?> toJson() => _values;

  KeyParam _param(String name) {
    for (final param in _params) {
      if (param.name == name) return param;
    }
    throw ArgumentError.value(name, 'name', 'the command has no such param');
  }

  T _required<T extends Object>(String name) {
    final param = _param(name);
    if (!param.required) {
      throw StateError('"$name" is optional: read it with a maybe getter');
    }
    return _values[name]! as T;
  }

  T? _optional<T extends Object>(String name) {
    _param(name);
    return _values[name] as T?;
  }

  @override
  String toString() => 'KeyArgs($_values)';
}
