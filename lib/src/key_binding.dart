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

import 'package:flutter/foundation.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What a person presses to reach a command or open a group: one key, such as
/// ⌘K, or several in a row, such as G then I.
///
/// Written as text, the keys are separated by spaces: `'meta+k'`, `'g i'`,
/// `'meta+k meta+d'`. See [KeyActivator] for how one key is written.
@immutable
final class KeyBinding {
  /// The keys, in the order they are pressed. Never empty.
  final List<KeyActivator> steps;

  KeyBinding(Iterable<KeyActivator> steps) : steps = List.unmodifiable(steps) {
    if (this.steps.isEmpty) {
      throw ArgumentError.value(steps, 'steps', 'needs at least one key');
    }
  }

  /// Reads keys written as text, separated by spaces.
  ///
  /// Throws a [FormatException] naming the part it could not read.
  factory KeyBinding.parse(String spec) {
    final trimmed = spec.trim();
    if (trimmed.isEmpty) {
      throw FormatException('A key binding is empty', spec);
    }
    return KeyBinding(trimmed.split(RegExp(r'\s+')).map(KeyActivator.parse));
  }

  /// How a person would write these keys: "⌘K", "G I".
  String describe() => steps.map((step) => step.describe()).join(' ');

  /// These keys written as text that [KeyBinding.parse] reads back.
  String toSpec() => steps.map((step) => step.toSpec()).join(' ');

  /// Whether [strokes] are the first keys of this binding, or all of them.
  bool startsWith(List<KeyStroke> strokes) {
    if (strokes.length > steps.length) return false;
    for (var i = 0; i < strokes.length; i++) {
      if (!steps[i].accepts(strokes[i])) return false;
    }
    return true;
  }

  /// Whether this binding's keys are the first keys of [other], or the same,
  /// so that pressing them would leave it unclear which one was meant.
  bool overlaps(KeyBinding other) {
    final length = steps.length < other.steps.length
        ? steps.length
        : other.steps.length;
    for (var i = 0; i < length; i++) {
      if (steps[i] != other.steps[i]) return false;
    }
    return true;
  }

  /// This binding with [prefix]'s keys in front, as a group's key and a
  /// command's key inside it are pressed one after the other.
  KeyBinding after(KeyBinding prefix) =>
      KeyBinding([...prefix.steps, ...steps]);

  @override
  bool operator ==(Object other) =>
      other is KeyBinding && listEquals(other.steps, steps);

  @override
  int get hashCode => Object.hashAll(steps);

  @override
  String toString() => 'KeyBinding(${toSpec()})';
}
