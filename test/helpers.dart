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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Synthesize a [KeyDownEvent] without going through [HardwareKeyboard]'s
/// dispatch path. Useful for testing [KeyActivator.matches] in isolation.
KeyDownEvent syntheticKeyDown(
  LogicalKeyboardKey logical, {
  PhysicalKeyboardKey? physical,
}) {
  return KeyDownEvent(
    physicalKey: physical ?? PhysicalKeyboardKey.keyA,
    logicalKey: logical,
    timeStamp: Duration.zero,
  );
}

KeyUpEvent syntheticKeyUp(
  LogicalKeyboardKey logical, {
  PhysicalKeyboardKey? physical,
}) {
  return KeyUpEvent(
    physicalKey: physical ?? PhysicalKeyboardKey.keyA,
    logicalKey: logical,
    timeStamp: Duration.zero,
  );
}

KeyRepeatEvent syntheticKeyRepeat(
  LogicalKeyboardKey logical, {
  PhysicalKeyboardKey? physical,
}) {
  return KeyRepeatEvent(
    physicalKey: physical ?? PhysicalKeyboardKey.keyA,
    logicalKey: logical,
    timeStamp: Duration.zero,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Clear all pressed keys from [HardwareKeyboard.instance]. Required between
/// tests that simulate modifier presses — leaked modifier state breaks
/// otherwise-unrelated tests.
Future<void> resetHardwareKeyboard() async {
  for (final key in HardwareKeyboard.instance.logicalKeysPressed.toList()) {
    await simulateKeyUpEvent(key);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Set [debugDefaultTargetPlatformOverride] for the duration of [body], then
/// reset it. `addTearDown` runs AFTER the binding's invariant check, so we
/// can't rely on it — the reset must happen inside the test body.
T withPlatform<T>(TargetPlatform platform, T Function() body) {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<T> withPlatformAsync<T>(
  TargetPlatform platform,
  Future<T> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}
