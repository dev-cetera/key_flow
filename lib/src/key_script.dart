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

import 'package:flutter/foundation.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What a [KeyCursor] looks like and which pointer it presses with.
enum KeyCursorKind {
  /// An arrow, pressing as a mouse: hover effects show as it moves.
  mouse('mouse'),

  /// A fingertip, pressing as a touch.
  touch('touch');

  /// Its name in a script's JSON.
  final String jsonName;

  const KeyCursorKind(this.jsonName);

  /// The kind people use on this platform: touch on phones and tablets, a
  /// mouse elsewhere.
  static KeyCursorKind forPlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => KeyCursorKind.touch,
      TargetPlatform.macOS ||
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => KeyCursorKind.mouse,
    };
  }

  static KeyCursorKind _fromJson(String name) {
    for (final kind in values) {
      if (kind.jsonName == name) return kind;
    }
    throw FormatException(
      'A cursor kind is ${values.map((kind) => kind.jsonName).join(' or ')}',
      name,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// One of the pointers a [KeyScript] moves on screen. A script with two
/// shows two people at work at once.
@immutable
final class KeyCursor {
  /// Its name, which each step's `cursor` refers to.
  final String id;

  /// What it looks like and how it presses.
  final KeyCursorKind kind;

  /// A name shown beside it, such as a person's; none when null.
  final String? label;

  /// Its colour; the accent of [KeyFlowStyle] when null.
  final Color? color;

  const KeyCursor({
    required this.id,
    required this.kind,
    this.label,
    this.color,
  });

  /// Reads a cursor from plain data:
  /// `{"id": "ana", "kind": "touch", "label": "Ana", "color": "#E91E63"}`.
  factory KeyCursor.fromJson(Map<String, Object?> json) {
    final fields = _Fields(json, 'cursor');
    final color = fields.maybeString('color');
    final cursor = KeyCursor(
      id: fields.string('id'),
      kind: KeyCursorKind._fromJson(fields.string('kind')),
      label: fields.maybeString('label'),
      color: color == null ? null : _parseColor(color),
    );
    fields.done();
    return cursor;
  }

  /// It as plain data.
  Map<String, Object?> toJson() {
    final color = this.color;
    return {
      'id': id,
      'kind': kind.jsonName,
      'label': ?label,
      if (color != null)
        'color':
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
    };
  }

  static Color _parseColor(String text) {
    final hex = text.startsWith('#') ? text.substring(1) : text;
    final value = int.tryParse(hex, radix: 16);
    if (value == null || (hex.length != 6 && hex.length != 8)) {
      throw FormatException('A colour is #RRGGBB or #AARRGGBB', text);
    }
    return Color(hex.length == 6 ? 0xFF000000 | value : value);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Shows how something is done: cursors move over the app, press its
/// controls for real and type into its fields, with captions, while people
/// watch. Played by [KeyFlowController.play].
///
/// ```dart
/// KeyFlow.of(context).play(KeyScript(steps: [
///   KeyStep.caption('Add something to the list'),
///   KeyStep.tap('add'),
///   KeyStep.type('Milk', at: 'new-item', submit: true),
///   KeyStep.keys('g i'),
/// ]));
/// ```
///
/// Steps name what they act on by [KeyPlace]: the id of a [KeyAnchor], or of
/// the command a [KeyTarget] or [KeyHint] is for.
@immutable
final class KeyScript {
  /// The cursors, in the order they appear. Each step uses the one its
  /// `cursor` names, or the first. One of [KeyCursorKind.forPlatform] when
  /// empty.
  final List<KeyCursor> cursors;

  /// What happens, in order.
  final List<KeyStep> steps;

  /// How fast it plays: 2 is twice as fast.
  final double speed;

  const KeyScript({
    this.cursors = const [],
    required this.steps,
    this.speed = 1,
  });

  /// Reads a script from plain data, as an agent or a browser sends it:
  ///
  /// ```json
  /// {
  ///   "cursors": [{"id": "me", "kind": "mouse"}],
  ///   "speed": 1,
  ///   "steps": [
  ///     {"do": "caption", "text": "Add something to the list"},
  ///     {"do": "tap", "at": "add"},
  ///     {"do": "type", "at": "new-item", "text": "Milk", "submit": true}
  ///   ]
  /// }
  /// ```
  ///
  /// Throws a [FormatException] naming what it could not read.
  factory KeyScript.fromJson(Map<String, Object?> json) {
    final fields = _Fields(json, 'script');
    final script = KeyScript(
      cursors: [
        for (final cursor in fields.maybeList('cursors') ?? const <Object?>[])
          KeyCursor.fromJson(_asMap(cursor, 'a cursor')),
      ],
      steps: [
        for (final step in fields.list('steps'))
          KeyStep.fromJson(_asMap(step, 'a step')),
      ],
      speed: fields.maybeNumber('speed') ?? 1,
    );
    fields.done();
    if (script.speed <= 0) {
      throw FormatException('A script plays at a speed above 0', json);
    }
    return script;
  }

  /// Reads a script written as JSON text; see [KeyScript.fromJson].
  factory KeyScript.parse(String text) {
    return KeyScript.fromJson(_asMap(jsonDecode(text), 'a script'));
  }

  /// It as plain data.
  Map<String, Object?> toJson() {
    return {
      if (cursors.isNotEmpty)
        'cursors': [for (final cursor in cursors) cursor.toJson()],
      if (speed != 1) 'speed': speed,
      'steps': [for (final step in steps) step.toJson()],
    };
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// One thing a [KeyScript] does.
@immutable
sealed class KeyStep {
  /// The id of the [KeyCursor] that does it; the script's first when null.
  final String? cursor;

  const KeyStep({this.cursor});

  /// Moves the cursor to [at] and rings it, to draw the eye there.
  const factory KeyStep.point(String at, {String? cursor}) = KeyPointStep;

  /// Moves the cursor to [at] and taps it, scrolling it into view first.
  const factory KeyStep.tap(String at, {String? cursor}) = KeyTapStep;

  /// Moves the cursor to [at] and holds it down for [duration].
  const factory KeyStep.hold(String at, {Duration duration, String? cursor}) =
      KeyHoldStep;

  /// Presses on [at] and drags to the anchor [to], or by [by].
  const factory KeyStep.drag(
    String at, {
    String? to,
    Offset? by,
    Duration hold,
    String? cursor,
  }) = KeyDragStep;

  /// Swipes the list [within] until [at] shows; see [KeyScrollToStep].
  const factory KeyStep.scrollTo(
    String at, {
    required String within,
    String? cursor,
  }) = KeyScrollToStep;

  /// Types [text], a key at a time, into the field [at] (tapped first) or
  /// the focused field; with [submit], then submits it.
  const factory KeyStep.type(
    String text, {
    String? at,
    bool submit,
    String? cursor,
  }) = KeyTypeStep;

  /// Presses [keys], written as for [KeyCommand.keys], showing them on
  /// screen, and does what they do here.
  const factory KeyStep.keys(String keys) = KeyPressStep;

  /// Runs the command [command] with [args]; see [KeyRunStep].
  const factory KeyStep.run(
    String command, {
    Map<String, Object?> args,
    String? cursor,
  }) = KeyRunStep;

  /// Shows [text] as a caption until the next one; empty text hides it.
  const factory KeyStep.caption(String text) = KeyCaptionStep;

  /// Waits for [duration].
  const factory KeyStep.wait(Duration duration) = KeyWaitStep;

  /// Waits until [at] is on screen, for up to [timeout].
  const factory KeyStep.waitFor(String at, {Duration timeout}) = KeyWaitForStep;

  /// Does [steps] at the same time, each with its own cursor.
  const factory KeyStep.together(List<KeyStep> steps) = KeyTogetherStep;

  /// Reads a step from plain data: `{"do": "tap", "at": "save"}`. See each
  /// step's [toJson] for its fields.
  ///
  /// Throws a [FormatException] naming what it could not read.
  factory KeyStep.fromJson(Map<String, Object?> json) {
    final fields = _Fields(json, 'step');
    final cursor = fields.maybeString('cursor');
    final kind = fields.string('do');
    final step = switch (kind) {
      'point' => KeyPointStep(fields.string('at'), cursor: cursor),
      'tap' => KeyTapStep(fields.string('at'), cursor: cursor),
      'hold' => KeyHoldStep(
        fields.string('at'),
        duration: fields.maybeDuration('ms') ?? KeyHoldStep.defaultDuration,
        cursor: cursor,
      ),
      'drag' => KeyDragStep(
        fields.string('at'),
        to: fields.maybeString('to'),
        by: fields.maybeOffset('by'),
        hold: fields.maybeDuration('holdMs') ?? Duration.zero,
        cursor: cursor,
      ),
      'scrollTo' => KeyScrollToStep(
        fields.string('at'),
        within: fields.string('within'),
        cursor: cursor,
      ),
      'type' => KeyTypeStep(
        fields.string('text'),
        at: fields.maybeString('at'),
        submit: fields.maybeBool('submit') ?? false,
        cursor: cursor,
      ),
      'keys' => KeyPressStep(fields.string('keys')),
      'run' => KeyRunStep(
        fields.string('command'),
        args: fields.maybeMap('args') ?? const {},
        cursor: cursor,
      ),
      'caption' => KeyCaptionStep(fields.string('text')),
      'wait' => KeyWaitStep(fields.duration('ms')),
      'waitFor' => KeyWaitForStep(
        fields.string('at'),
        timeout: fields.maybeDuration('ms') ?? KeyWaitForStep.defaultTimeout,
      ),
      'together' => KeyTogetherStep([
        for (final step in fields.list('steps'))
          KeyStep.fromJson(_asMap(step, 'a step')),
      ]),
      _ => throw FormatException(
        'A step does point, tap, hold, drag, scrollTo, type, keys, run, '
        'caption, wait, waitFor or together',
        kind,
      ),
    };
    if (cursor != null && step.cursor == null) {
      throw FormatException('A "$kind" step takes no cursor', json);
    }
    fields.done();
    if (step is KeyDragStep && (step.to == null) == (step.by == null)) {
      throw FormatException('A drag gives "to" or "by", not both', json);
    }
    return step;
  }

  /// It as plain data.
  Map<String, Object?> toJson();

  Map<String, Object?> _json(String kind, Map<String, Object?> fields) {
    return {'do': kind, ...fields, 'cursor': ?cursor};
  }
}

/// Moves the cursor to [at] and rings it, to draw the eye there.
final class KeyPointStep extends KeyStep {
  /// Where; see [KeyPlace].
  final String at;

  const KeyPointStep(this.at, {super.cursor});

  @override
  Map<String, Object?> toJson() => _json('point', {'at': at});
}

/// Moves the cursor to [at] and taps it, scrolling it into view first.
final class KeyTapStep extends KeyStep {
  /// Where; see [KeyPlace].
  final String at;

  const KeyTapStep(this.at, {super.cursor});

  @override
  Map<String, Object?> toJson() => _json('tap', {'at': at});
}

/// Moves the cursor to [at] and holds it down for [duration]: a long press.
final class KeyHoldStep extends KeyStep {
  /// How long a hold lasts when a script does not say.
  static const defaultDuration = Duration(milliseconds: 800);

  /// Where; see [KeyPlace].
  final String at;

  /// How long it is held.
  final Duration duration;

  const KeyHoldStep(this.at, {this.duration = defaultDuration, super.cursor});

  @override
  Map<String, Object?> toJson() {
    return _json('hold', {'at': at, 'ms': duration.inMilliseconds});
  }
}

/// Presses on [at], holds for [hold], and drags to the anchor [to] or by
/// [by] logical pixels.
final class KeyDragStep extends KeyStep {
  /// Where it starts; see [KeyPlace].
  final String at;

  /// The anchor it ends on; or give [by].
  final String? to;

  /// How far it moves; or give [to].
  final Offset? by;

  /// How long to hold before moving, for things that only drag after a long
  /// press.
  final Duration hold;

  const KeyDragStep(
    this.at, {
    this.to,
    this.by,
    this.hold = Duration.zero,
    super.cursor,
  });

  @override
  Map<String, Object?> toJson() {
    final by = this.by;
    return _json('drag', {
      'at': at,
      'to': ?to,
      if (by != null) 'by': [by.dx, by.dy],
      if (hold != Duration.zero) 'holdMs': hold.inMilliseconds,
    });
  }
}

/// Swipes the list [within], as a person does, until [at] shows: down to
/// its end, then up to its start; then fails.
///
/// A list that builds its rows as they scroll into view, such as
/// [ListView.builder], has no anchor yet for a row far off screen, so a tap
/// cannot find it. Scroll to it first.
final class KeyScrollToStep extends KeyStep {
  /// What to bring on screen; see [KeyPlace].
  final String at;

  /// The anchor around the list (or holding it) to swipe.
  final String within;

  const KeyScrollToStep(this.at, {required this.within, super.cursor});

  @override
  Map<String, Object?> toJson() {
    return _json('scrollTo', {'at': at, 'within': within});
  }
}

/// Types [text], a key at a time, into the field [at] (tapped first) or the
/// focused field; with [submit], then submits it as the keyboard's action
/// key would.
final class KeyTypeStep extends KeyStep {
  /// What to type.
  final String text;

  /// The field; the focused one when null. See [KeyPlace].
  final String? at;

  /// Whether to submit the field after typing.
  final bool submit;

  const KeyTypeStep(this.text, {this.at, this.submit = false, super.cursor});

  @override
  Map<String, Object?> toJson() {
    return _json('type', {'text': text, 'at': ?at, if (submit) 'submit': true});
  }
}

/// Presses [keys], written as for [KeyCommand.keys] (`meta+k`, `g i`),
/// showing them on screen, and does what they do in the [KeyFlow] here: runs
/// the command, or opens the group and its panel.
///
/// These reach key_flow's own keys, not a text field: type into one with
/// [KeyTypeStep].
final class KeyPressStep extends KeyStep {
  /// The keys.
  final String keys;

  const KeyPressStep(this.keys);

  @override
  Map<String, Object?> toJson() => _json('keys', {'keys': keys});
}

/// Runs the command [command] (its full id) with [args].
///
/// With no [args] and a control for it on screen, the cursor taps that
/// control, so people see where it lives. Otherwise the cursor presses its
/// control, if any, and the command runs as code: what an agent calling a
/// tool looks like.
final class KeyRunStep extends KeyStep {
  /// The command's full id.
  final String command;

  /// The values it runs with; see [KeyCommand.params].
  final Map<String, Object?> args;

  const KeyRunStep(this.command, {this.args = const {}, super.cursor});

  @override
  Map<String, Object?> toJson() {
    return _json('run', {
      'command': command,
      if (args.isNotEmpty) 'args': args,
    });
  }
}

/// Shows [text] as a caption until the next one; empty text hides it.
final class KeyCaptionStep extends KeyStep {
  /// The words.
  final String text;

  const KeyCaptionStep(this.text);

  @override
  Map<String, Object?> toJson() => _json('caption', {'text': text});
}

/// Waits for [duration].
final class KeyWaitStep extends KeyStep {
  /// How long.
  final Duration duration;

  const KeyWaitStep(this.duration);

  @override
  Map<String, Object?> toJson() {
    return _json('wait', {'ms': duration.inMilliseconds});
  }
}

/// Waits until [at] is on screen, for up to [timeout]; then fails.
final class KeyWaitForStep extends KeyStep {
  /// How long to wait when a script does not say.
  static const defaultTimeout = Duration(seconds: 5);

  /// What to wait for; see [KeyPlace].
  final String at;

  /// How long to wait before failing.
  final Duration timeout;

  const KeyWaitForStep(this.at, {this.timeout = defaultTimeout});

  @override
  Map<String, Object?> toJson() {
    return _json('waitFor', {'at': at, 'ms': timeout.inMilliseconds});
  }
}

/// Does [steps] at the same time; each must use a different cursor.
final class KeyTogetherStep extends KeyStep {
  /// What happens at once.
  final List<KeyStep> steps;

  const KeyTogetherStep(this.steps);

  @override
  Map<String, Object?> toJson() {
    return _json('together', {
      'steps': [for (final step in steps) step.toJson()],
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Map<String, Object?> _asMap(Object? value, String what) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return {for (final MapEntry(:key, :value) in value.entries) '$key': value};
  }
  throw FormatException('Expected $what as an object', value);
}

/// Reads the fields of one object of a script, and fails on any it did not
/// read, so a misspelt field is an error rather than ignored.
final class _Fields {
  final Map<String, Object?> json;
  final String what;
  final _read = <String>{};

  _Fields(this.json, this.what);

  Object? _get(String key) {
    _read.add(key);
    return json[key];
  }

  Never _wrong(String key, String expected) {
    throw FormatException('A $what\'s "$key" should be $expected', json);
  }

  String string(String key) => maybeString(key) ?? _wrong(key, 'given');

  String? maybeString(String key) {
    final value = _get(key);
    if (value == null || value is String) return value as String?;
    _wrong(key, 'text');
  }

  bool? maybeBool(String key) {
    final value = _get(key);
    if (value == null || value is bool) return value as bool?;
    _wrong(key, 'true or false');
  }

  double? maybeNumber(String key) {
    final value = _get(key);
    if (value == null) return null;
    if (value is num) return value.toDouble();
    _wrong(key, 'a number');
  }

  Duration duration(String key) {
    return maybeDuration(key) ?? _wrong(key, 'given, in milliseconds');
  }

  Duration? maybeDuration(String key) {
    final ms = maybeNumber(key);
    if (ms == null) return null;
    if (ms < 0) _wrong(key, '0 or more milliseconds');
    return Duration(milliseconds: ms.round());
  }

  Offset? maybeOffset(String key) {
    final value = _get(key);
    if (value == null) return null;
    if (value is List && value.length == 2 && value.every((n) => n is num)) {
      return Offset((value[0] as num).toDouble(), (value[1] as num).toDouble());
    }
    _wrong(key, '[dx, dy]');
  }

  List<Object?> list(String key) => maybeList(key) ?? _wrong(key, 'given');

  List<Object?>? maybeList(String key) {
    final value = _get(key);
    if (value == null || value is List) return (value as List?)?.cast();
    _wrong(key, 'a list');
  }

  Map<String, Object?>? maybeMap(String key) {
    final value = _get(key);
    if (value == null) return null;
    return _asMap(value, '"$key"');
  }

  /// Fails on any field not read.
  void done() {
    final unread = json.keys.where((key) => !_read.contains(key)).toList();
    if (unread.isNotEmpty) {
      throw FormatException(
        'A $what has no field ${unread.map((key) => '"$key"').join(', ')}',
        json,
      );
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// How a [KeyScript] ended.
enum KeyPlayEnd {
  /// Every step ran.
  finished,

  /// [KeyFlowController.stopPlaying], Escape or the person's own press
  /// stopped it.
  stopped,
}

/// What happens when the person presses the screen while a script plays.
enum KeyPersonPress {
  /// Their press stops the script, and goes no further: a viewer taps to
  /// take over.
  stops,

  /// Their press is dropped and the script plays on: for recording.
  ignored,
}
