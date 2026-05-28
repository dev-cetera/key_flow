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

/// A single trigger in a key mapping: one key plus the modifiers required.
///
/// Prefer the dedicated subclasses [LogicalKeyActivator] (layout-correct —
/// recommended for letters, symbols, Enter, Escape) and [PhysicalKeyActivator]
/// (position-based — for home-row navigation like `j`/`k`/`h`/`l`). The
/// [KeyActivator.logical] / [KeyActivator.physical] named constructors
/// continue to work and produce the same activators — pick whichever style
/// you prefer.
///
/// The [meta] flag is the canonical "command modifier" — it resolves to ⌘
/// on macOS/iOS and Ctrl on Windows/Linux/web. Use [control] only when you
/// specifically want the Ctrl key on every platform.
///
/// A `List<KeyActivator>` of length 1 is a single key/chord; a list of
/// length >1 is a Superhuman-style sequence (e.g. `g` then `i` to
/// "go to inbox").
@immutable
class KeyActivator {
  /// The logical key that must match. Null if matching by [physical].
  final LogicalKeyboardKey? logical;

  /// The physical key that must match. Null if matching by [logical].
  final PhysicalKeyboardKey? physical;

  /// Platform-aware "command" modifier. Cmd on macOS/iOS, Ctrl elsewhere.
  final bool meta;

  /// Literal Ctrl on every platform. Prefer [meta] unless you specifically
  /// need this.
  final bool control;

  /// Shift modifier.
  final bool shift;

  /// Alt/Option modifier.
  final bool alt;

  const KeyActivator._({
    this.logical,
    this.physical,
    this.meta = false,
    this.control = false,
    this.shift = false,
    this.alt = false,
  }) : assert(
          (logical == null) != (physical == null),
          'KeyActivator needs exactly one of logical or physical',
        );

  /// Match by logical key (layout-correct — recommended for letters, Enter,
  /// Escape, and most named keys).
  const KeyActivator.logical(
    LogicalKeyboardKey key, {
    bool meta = false,
    bool control = false,
    bool shift = false,
    bool alt = false,
  }) : this._(
          logical: key,
          meta: meta,
          control: control,
          shift: shift,
          alt: alt,
        );

  /// Match by physical key position. Use for home-row navigation that
  /// should stay in the same spot regardless of keyboard layout.
  const KeyActivator.physical(
    PhysicalKeyboardKey key, {
    bool meta = false,
    bool control = false,
    bool shift = false,
    bool alt = false,
  }) : this._(
          physical: key,
          meta: meta,
          control: control,
          shift: shift,
          alt: alt,
        );

  /// Whether the current platform treats [meta] as the Cmd key (macOS-style)
  /// rather than mapping it to Ctrl.
  static bool get isAppleHost {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _wantsCtrl => control || (meta && !isAppleHost);
  bool get _wantsMeta => meta && isAppleHost;

  /// True if this activator carries no modifiers — a bare key.
  bool get isBare => !meta && !control && !shift && !alt;

  /// Test whether this activator fires for the given [event] under the
  /// current modifier state on [HardwareKeyboard.instance].
  ///
  /// Fires on [KeyDownEvent] and [KeyRepeatEvent] (so holding a
  /// navigation key like arrow-down auto-repeats). [KeyUpEvent] never
  /// fires. Modifier-key events (pressing Cmd/Ctrl/Shift/Alt by
  /// themselves) never fire — they're tracked but don't trigger.
  bool matches(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    if (isModifierKey(event.logicalKey)) return false;

    final keyMatch = logical != null
        ? event.logicalKey == logical
        : event.physicalKey == physical;
    if (!keyMatch) return false;

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed != _wantsMeta) return false;
    if (keyboard.isControlPressed != _wantsCtrl) return false;
    if (keyboard.isShiftPressed != shift) return false;
    if (keyboard.isAltPressed != alt) return false;
    return true;
  }

  /// Human-readable description for help overlays: "⌘⇧Enter" on Mac,
  /// "Ctrl+Shift+Enter" elsewhere.
  String describe() {
    final mac = isAppleHost;
    final parts = <String>[];
    if (meta) parts.add(mac ? '⌘' : 'Ctrl');
    if (control && !meta) parts.add(mac ? '⌃' : 'Ctrl');
    if (alt) parts.add(mac ? '⌥' : 'Alt');
    if (shift) parts.add(mac ? '⇧' : 'Shift');
    parts.add(_describeTrigger());
    return mac ? parts.join('') : parts.join('+');
  }

  String _describeTrigger() {
    final src = logical?.keyLabel ?? '';
    if (src.isNotEmpty && src.length == 1) {
      return src.toUpperCase();
    }
    if (logical != null) {
      return extractDebugName(logical!);
    }
    return extractDebugName(physical!);
  }

  @override
  bool operator ==(Object other) {
    return other is KeyActivator &&
        other.logical == logical &&
        other.physical == physical &&
        other.meta == meta &&
        other.control == control &&
        other.shift == shift &&
        other.alt == alt;
  }

  @override
  int get hashCode => Object.hash(logical, physical, meta, control, shift, alt);

  @override
  String toString() => 'KeyActivator(${describe()})';
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The four canonical, side-agnostic modifier keys. Side-specific
/// variants (e.g. [LogicalKeyboardKey.controlLeft]) collapse to one of
/// these via [LogicalKeyboardKey.collapseSynonyms].
final _kModifierSynonyms = <LogicalKeyboardKey>{
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.meta,
};

/// True if [key] is a modifier (Shift/Ctrl/Alt/Meta), including any
/// side-specific variant like [LogicalKeyboardKey.controlLeft].
bool isModifierKey(LogicalKeyboardKey key) {
  if (_kModifierSynonyms.contains(key)) return true;
  return LogicalKeyboardKey.collapseSynonyms({key}).any(
    _kModifierSynonyms.contains,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension DescribeOnKeyActivatorX on KeyActivator {
  /// Convenience alias for [KeyActivator.describe], matching the
  /// `debugName` pattern used elsewhere in the package.
  String get debugName => describe();
}

extension DescribeOnIterableKeyActivatorX on Iterable<KeyActivator> {
  /// Joined description of the activator sequence — e.g. `"⌘G"` for a
  /// single chord or `"g i"` for a Superhuman-style two-step sequence.
  String get debugName => map((e) => e.describe()).join(' ');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Convenience builders for common Superhuman-style actions.
extension KeyActivatorShorthandX on LogicalKeyboardKey {
  /// Bare key, no modifiers. Equivalent to `LogicalKeyActivator(this)`.
  KeyActivator get bare => LogicalKeyActivator(this);

  /// `meta` (Cmd on macOS/iOS, Ctrl elsewhere) + this key.
  KeyActivator get meta => LogicalKeyActivator(this, meta: true);

  /// Shift + this key.
  KeyActivator get shifted => LogicalKeyActivator(this, shift: true);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Layout-correct activator — matches by [LogicalKeyboardKey].
///
/// Equivalent to [KeyActivator.logical] but exposed as a dedicated class so
/// it reads naturally alongside [PhysicalKeyActivator] at call sites.
class LogicalKeyActivator extends KeyActivator {
  const LogicalKeyActivator(
    LogicalKeyboardKey key, {
    super.meta,
    super.control,
    super.shift,
    super.alt,
  }) : super._(logical: key);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Position-based activator — matches by [PhysicalKeyboardKey].
///
/// Equivalent to [KeyActivator.physical]. Use for home-row navigation that
/// should stay in the same spot regardless of keyboard layout.
class PhysicalKeyActivator extends KeyActivator {
  const PhysicalKeyActivator(
    PhysicalKeyboardKey key, {
    super.meta,
    super.control,
    super.shift,
    super.alt,
  }) : super._(physical: key);
}
