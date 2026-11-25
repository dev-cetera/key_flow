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

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:meta/meta.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What happened in the app while it was recording, as a [KeyScript] to
/// play back later; see [KeyFlowController.startRecording].
///
/// Listeners hear every step and miss as it is added.
final class KeyRecording extends ChangeNotifier {
  final _steps = <KeyStep>[];
  final _misses = <KeyRecordingMiss>[];
  final _cursors = <KeyCursor>[];
  var _isRecording = true;

  /// Starts an empty recording; [KeyFlowController.startRecording] makes
  /// the one it fills.
  @internal
  KeyRecording();

  /// The steps so far, in order.
  List<KeyStep> get steps => List.unmodifiable(_steps);

  /// What happened that no step could replay, such as a press on something
  /// inside no [KeyAnchor].
  List<KeyRecordingMiss> get misses => List.unmodifiable(_misses);

  /// Whether it is still recording.
  bool get isRecording => _isRecording;

  /// Adds a caption step: what the next steps show, for the people who will
  /// watch it.
  void note(String text) => add(KeyCaptionStep(text));

  /// The steps as a script, with the cursors they use.
  KeyScript toScript() {
    return KeyScript(cursors: List.unmodifiable(_cursors), steps: steps);
  }

  /// The script and the misses, as plain data.
  Map<String, Object?> toJson() {
    return {
      'script': toScript().toJson(),
      'misses': [for (final miss in _misses) miss.toJson()],
    };
  }

  /// Adds [step].
  @internal
  void add(KeyStep step) {
    _checkRecording();
    _steps.add(step);
    notifyListeners();
  }

  /// Notes what could not be recorded.
  @internal
  void miss(KeyRecordingMiss miss) {
    _checkRecording();
    _misses.add(miss);
    notifyListeners();
  }

  /// Adds [cursor] unless one with its id is in already. Notes a miss when
  /// that one looks different, as the script keeps the first.
  @internal
  void addCursor(KeyCursor cursor) {
    for (final known in _cursors) {
      if (known.id != cursor.id) continue;
      if (!mapEquals(known.toJson(), cursor.toJson())) {
        miss(
          KeyRecordingMiss(
            'Two cursors are called "${cursor.id}"; the script keeps the '
            'first',
          ),
        );
      }
      return;
    }
    _cursors.add(cursor);
    notifyListeners();
  }

  /// Takes back the steps and misses after the first [steps] and [misses].
  @internal
  void truncate({required int steps, required int misses}) {
    _steps.removeRange(steps, _steps.length);
    _misses.removeRange(misses, _misses.length);
    notifyListeners();
  }

  /// Stops it taking steps.
  @internal
  void end() {
    _isRecording = false;
    notifyListeners();
  }

  void _checkRecording() {
    if (!_isRecording) throw StateError('This recording has ended');
  }

  @override
  String toString() {
    return 'KeyRecording(${_steps.length} steps, ${_misses.length} misses)';
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Something that happened while recording that no step could replay.
@immutable
final class KeyRecordingMiss {
  /// What happened, and what would let it record.
  final String reason;

  /// Where on screen, in logical pixels of its window, if it was a press.
  final Offset? position;

  const KeyRecordingMiss(this.reason, {this.position});

  /// It as plain data.
  Map<String, Object?> toJson() {
    final position = this.position;
    return {
      'reason': reason,
      if (position != null)
        'at': [position.dx.roundToDouble(), position.dy.roundToDouble()],
    };
  }

  @override
  String toString() => 'KeyRecordingMiss($reason)';
}
