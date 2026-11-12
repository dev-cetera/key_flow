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

/// One key press and the modifiers held for it, such as ⌘K, G or `?`.
///
/// A [KeyBinding] is one or more of these in a row. Most code writes them as
/// text, which [KeyActivator.parse] reads and [toSpec] writes:
///
/// - `'meta+k'`: ⌘K on macOS and iOS, Ctrl+K elsewhere.
/// - `'ctrl+k'`: Ctrl+K on every platform.
/// - `'alt+shift+enter'`, `'f5'`, `'escape'`, `'up'`.
/// - `'g'`: the G key alone.
/// - `'?'`: whatever key types a question mark on the person's layout.
/// - `'⌘⇧K'`: the same symbols [describe] prints, so a shortcut read off the
///   screen can be passed back as it is.
@immutable
class KeyActivator {
  /// The logical key that must match, or null when matching by [physical] or
  /// [character].
  final LogicalKeyboardKey? logical;

  /// The physical key that must match, or null when matching by [logical] or
  /// [character].
  final PhysicalKeyboardKey? physical;

  /// The character that must be typed, or null when matching by a key. Shift
  /// is part of the character, so it is not checked separately.
  final String? character;

  /// Platform-aware "command" modifier: Cmd on macOS and iOS, Ctrl elsewhere.
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
    this.character,
    this.meta = false,
    this.control = false,
    this.shift = false,
    this.alt = false,
  }) : assert(
         (logical != null ? 1 : 0) +
                 (physical != null ? 1 : 0) +
                 (character != null ? 1 : 0) ==
             1,
         'KeyActivator needs exactly one of logical, physical or character',
       );

  /// Match by logical key (layout-correct: recommended for letters, Enter,
  /// Escape and most named keys).
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

  /// Match by physical key position. Use for home-row navigation that should
  /// stay in the same spot regardless of keyboard layout.
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

  /// Match by the character typed, such as `?` or `/`, whichever key types it
  /// on the person's layout.
  const KeyActivator.character(
    String character, {
    bool meta = false,
    bool control = false,
    bool alt = false,
  }) : this._(character: character, meta: meta, control: control, alt: alt);

  /// Reads one key press written as text; see [KeyActivator] for the forms.
  ///
  /// Throws a [FormatException] naming what it could not read.
  factory KeyActivator.parse(String spec) {
    var rest = spec.trim();
    if (rest.isEmpty) {
      throw FormatException('A key is empty', spec);
    }
    var meta = false, control = false, shift = false, alt = false;
    void hold(_Modifier modifier) {
      switch (modifier) {
        case _Modifier.meta:
          meta = true;
        case _Modifier.control:
          control = true;
        case _Modifier.alt:
          alt = true;
        case _Modifier.shift:
          shift = true;
      }
    }

    // Leading symbols, as describe() prints them on Apple platforms: ⌘⇧K.
    while (rest.length > 1 && _modifierSymbols.containsKey(rest[0])) {
      hold(_modifierSymbols[rest[0]]!);
      rest = rest.substring(1);
    }
    // "+" joins modifiers to the key, so the plus key itself is written last
    // ("meta++") or by name ("plus").
    final String keyName;
    final List<String> modifierNames;
    if (rest == '+') {
      keyName = '+';
      modifierNames = const [];
    } else if (rest.endsWith('++')) {
      keyName = '+';
      modifierNames = rest.substring(0, rest.length - 2).split('+');
    } else {
      final parts = rest.split('+');
      keyName = parts.last;
      modifierNames = parts.sublist(0, parts.length - 1);
    }
    for (final name in modifierNames) {
      final modifier = _modifierWords[name.trim().toLowerCase()];
      if (modifier == null) {
        throw FormatException('Unknown modifier "$name"', spec);
      }
      hold(modifier);
    }
    final key = keyName.trim();
    if (key.isEmpty) {
      throw FormatException('No key after the modifiers', spec);
    }
    final lower = key.toLowerCase();
    if (lower.startsWith('phys:0x')) {
      final code = int.tryParse(lower.substring(7), radix: 16);
      final physical = code == null
          ? null
          : PhysicalKeyboardKey.findKeyByCode(code);
      if (physical == null) {
        throw FormatException('Unknown physical key "$key"', spec);
      }
      return KeyActivator.physical(
        physical,
        meta: meta,
        control: control,
        shift: shift,
        alt: alt,
      );
    }
    if (lower.startsWith('key:0x')) {
      final id = int.tryParse(lower.substring(6), radix: 16);
      if (id == null) {
        throw FormatException('Unknown key "$key"', spec);
      }
      return KeyActivator.logical(
        LogicalKeyboardKey.findKeyByKeyId(id) ?? LogicalKeyboardKey(id),
        meta: meta,
        control: control,
        shift: shift,
        alt: alt,
      );
    }
    final named = _namedKeys[lower];
    if (named != null) {
      return KeyActivator.logical(
        named,
        meta: meta,
        control: control,
        shift: shift,
        alt: alt,
      );
    }
    if (key.runes.length != 1) {
      throw FormatException('Unknown key "$key"', spec);
    }
    final rune = lower.runes.single;
    final isLetterOrDigit =
        (rune >= 0x61 && rune <= 0x7a) || (rune >= 0x30 && rune <= 0x39);
    // A symbol on its own is matched by what it types, so `?` works on every
    // layout. With a modifier it is matched by its key, since modifiers
    // change what a key types.
    if (!isLetterOrDigit && !meta && !control && !alt && !shift) {
      return KeyActivator.character(key);
    }
    return KeyActivator.logical(
      LogicalKeyboardKey.findKeyByKeyId(rune) ?? LogicalKeyboardKey(rune),
      meta: meta,
      control: control,
      shift: shift,
      alt: alt,
    );
  }

  /// Whether the current platform treats [meta] as the Cmd key (macOS-style)
  /// rather than mapping it to Ctrl.
  static bool get isAppleHost {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _wantsCtrl => control || (meta && !isAppleHost);
  bool get _wantsMeta => meta && isAppleHost;

  /// True if this activator carries no modifiers: a bare key.
  bool get isBare => !meta && !control && !shift && !alt;

  /// Whether pressing this in a text field would type something there, so a
  /// shortcut on it waits while a person types.
  bool get typesText => !meta && !control;

  /// Whether [event] fires this activator, under the modifiers held now on
  /// [HardwareKeyboard.instance].
  ///
  /// Fires on [KeyDownEvent] and [KeyRepeatEvent] (so holding a navigation
  /// key like arrow-down auto-repeats). [KeyUpEvent] never fires, and nor
  /// does pressing a modifier on its own.
  bool matches(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    return accepts(KeyStroke.fromEvent(event));
  }

  /// Whether [stroke], a key pressed with the modifiers held at that moment,
  /// fires this activator.
  bool accepts(KeyStroke stroke) {
    if (stroke.isModifier) return false;
    if (stroke.meta != _wantsMeta) return false;
    if (stroke.control != _wantsCtrl) return false;
    if (stroke.alt != alt) return false;
    final character = this.character;
    if (character != null) {
      final typed =
          stroke.character ??
          (stroke.shift ? null : stroke.logical.keyLabel.toLowerCase());
      return typed == character;
    }
    if (stroke.shift != shift) return false;
    final logical = this.logical;
    return logical != null
        ? stroke.logical == logical
        : stroke.physical == physical;
  }

  /// How a person would write this key: "⌘⇧↩" on Apple platforms,
  /// "Ctrl+Shift+Enter" elsewhere.
  String describe() {
    final apple = isAppleHost;
    final parts = <String>[
      if (apple && meta) '⌘',
      if (apple && control) '⌃',
      if (!apple && (meta || control)) 'Ctrl',
      if (alt) apple ? '⌥' : 'Alt',
      if (shift) apple ? '⇧' : 'Shift',
      _displayName(apple),
    ];
    return apple ? parts.join() : parts.join('+');
  }

  /// This key written as text that [KeyActivator.parse] reads back: modifiers
  /// in a fixed order, then the key, such as `meta+shift+k`.
  String toSpec() {
    final parts = <String>[
      if (meta) 'meta',
      if (control) 'ctrl',
      if (alt) 'alt',
      if (shift) 'shift',
      _specName(),
    ];
    return parts.join('+');
  }

  String _specName() {
    final character = this.character;
    if (character != null) {
      return switch (character) {
        '+' => 'plus',
        ' ' => 'space',
        _ => character,
      };
    }
    final logical = this.logical;
    if (logical != null) {
      final name = _specNames[logical];
      if (name != null) return name;
      final label = logical.keyLabel;
      if (label.runes.length == 1 && label != ' ') {
        return label == '+' ? 'plus' : label.toLowerCase();
      }
      return 'key:0x${logical.keyId.toRadixString(16)}';
    }
    return 'phys:0x${physical!.usbHidUsage.toRadixString(16)}';
  }

  String _displayName(bool apple) {
    final character = this.character;
    if (character != null) return character == ' ' ? 'Space' : character;
    final logical = this.logical;
    if (logical != null) {
      final names = _displayNames[logical];
      if (names != null) return apple ? names.$1 : names.$2;
      final label = logical.keyLabel;
      if (label.isNotEmpty) return label.toUpperCase();
      return 'Key 0x${logical.keyId.toRadixString(16)}';
    }
    // Letters and digits have fixed USB codes; anything else keeps its code.
    final usage = physical!.usbHidUsage;
    if (usage >= 0x00070004 && usage <= 0x0007001d) {
      return String.fromCharCode(0x41 + usage - 0x00070004);
    }
    if (usage >= 0x0007001e && usage <= 0x00070026) {
      return String.fromCharCode(0x31 + usage - 0x0007001e);
    }
    if (usage == 0x00070027) return '0';
    return 'Key 0x${usage.toRadixString(16)}';
  }

  @override
  bool operator ==(Object other) {
    return other is KeyActivator &&
        other.logical == logical &&
        other.physical == physical &&
        other.character == character &&
        other.meta == meta &&
        other.control == control &&
        other.shift == shift &&
        other.alt == alt;
  }

  @override
  int get hashCode =>
      Object.hash(logical, physical, character, meta, control, shift, alt);

  @override
  String toString() => 'KeyActivator(${toSpec()})';
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// One key as it was pressed: the key, what it typed and the modifiers held
/// at that moment.
///
/// A sequence such as `meta+k d` is matched against the strokes as they
/// happened, so letting go of ⌘ before D still counts.
@immutable
final class KeyStroke {
  /// The logical key pressed.
  final LogicalKeyboardKey logical;

  /// The physical key pressed.
  final PhysicalKeyboardKey physical;

  /// What the key typed, if anything.
  final String? character;

  /// Whether the Meta key (⌘ on Apple platforms) was held.
  final bool meta;

  /// Whether Ctrl was held.
  final bool control;

  /// Whether Shift was held.
  final bool shift;

  /// Whether Alt/Option was held.
  final bool alt;

  const KeyStroke({
    required this.logical,
    required this.physical,
    this.character,
    this.meta = false,
    this.control = false,
    this.shift = false,
    this.alt = false,
  });

  /// The stroke [event] makes, with the modifiers [keyboard] holds now.
  factory KeyStroke.fromEvent(KeyEvent event, {HardwareKeyboard? keyboard}) {
    final held = keyboard ?? HardwareKeyboard.instance;
    return KeyStroke(
      logical: event.logicalKey,
      physical: event.physicalKey,
      character: event.character,
      meta: held.isMetaPressed,
      control: held.isControlPressed,
      shift: held.isShiftPressed,
      alt: held.isAltPressed,
    );
  }

  /// Whether this is a modifier pressed on its own.
  bool get isModifier => isModifierKey(logical);

  /// Whether this is a key a text field uses to edit or move through text,
  /// which a shortcut must not take from it.
  bool get editsText {
    if (_textEditingKeys.contains(logical)) return true;
    return (meta || control) && _textCommandKeys.contains(logical);
  }

  /// Whether this is [key] pressed with no modifiers.
  bool isBare(LogicalKeyboardKey key) {
    return logical == key && !meta && !control && !alt && !shift;
  }

  @override
  String toString() {
    final parts = [
      if (meta) 'meta',
      if (control) 'ctrl',
      if (alt) 'alt',
      if (shift) 'shift',
      logical.keyLabel,
    ];
    return 'KeyStroke(${parts.join('+')})';
  }
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
  return LogicalKeyboardKey.collapseSynonyms({
    key,
  }).any(_kModifierSynonyms.contains);
}

enum _Modifier { meta, control, alt, shift }

const _modifierSymbols = <String, _Modifier>{
  '⌘': _Modifier.meta,
  '⌃': _Modifier.control,
  '⌥': _Modifier.alt,
  '⇧': _Modifier.shift,
};

const _modifierWords = <String, _Modifier>{
  'meta': _Modifier.meta,
  'cmd': _Modifier.meta,
  'command': _Modifier.meta,
  '⌘': _Modifier.meta,
  'ctrl': _Modifier.control,
  'control': _Modifier.control,
  '⌃': _Modifier.control,
  'alt': _Modifier.alt,
  'opt': _Modifier.alt,
  'option': _Modifier.alt,
  '⌥': _Modifier.alt,
  'shift': _Modifier.shift,
  '⇧': _Modifier.shift,
};

/// Names [KeyActivator.parse] reads for keys that type nothing, in lower
/// case, with the symbols [KeyActivator.describe] prints for some of them.
const _namedKeys = <String, LogicalKeyboardKey>{
  'enter': LogicalKeyboardKey.enter,
  'return': LogicalKeyboardKey.enter,
  '↩': LogicalKeyboardKey.enter,
  'escape': LogicalKeyboardKey.escape,
  'esc': LogicalKeyboardKey.escape,
  '⎋': LogicalKeyboardKey.escape,
  'tab': LogicalKeyboardKey.tab,
  '⇥': LogicalKeyboardKey.tab,
  'space': LogicalKeyboardKey.space,
  'backspace': LogicalKeyboardKey.backspace,
  '⌫': LogicalKeyboardKey.backspace,
  'delete': LogicalKeyboardKey.delete,
  'del': LogicalKeyboardKey.delete,
  '⌦': LogicalKeyboardKey.delete,
  'up': LogicalKeyboardKey.arrowUp,
  'arrowup': LogicalKeyboardKey.arrowUp,
  '↑': LogicalKeyboardKey.arrowUp,
  'down': LogicalKeyboardKey.arrowDown,
  'arrowdown': LogicalKeyboardKey.arrowDown,
  '↓': LogicalKeyboardKey.arrowDown,
  'left': LogicalKeyboardKey.arrowLeft,
  'arrowleft': LogicalKeyboardKey.arrowLeft,
  '←': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight,
  'arrowright': LogicalKeyboardKey.arrowRight,
  '→': LogicalKeyboardKey.arrowRight,
  'home': LogicalKeyboardKey.home,
  'end': LogicalKeyboardKey.end,
  'pageup': LogicalKeyboardKey.pageUp,
  'pgup': LogicalKeyboardKey.pageUp,
  'pagedown': LogicalKeyboardKey.pageDown,
  'pgdn': LogicalKeyboardKey.pageDown,
  'insert': LogicalKeyboardKey.insert,
  'plus': LogicalKeyboardKey.add,
  'f1': LogicalKeyboardKey.f1,
  'f2': LogicalKeyboardKey.f2,
  'f3': LogicalKeyboardKey.f3,
  'f4': LogicalKeyboardKey.f4,
  'f5': LogicalKeyboardKey.f5,
  'f6': LogicalKeyboardKey.f6,
  'f7': LogicalKeyboardKey.f7,
  'f8': LogicalKeyboardKey.f8,
  'f9': LogicalKeyboardKey.f9,
  'f10': LogicalKeyboardKey.f10,
  'f11': LogicalKeyboardKey.f11,
  'f12': LogicalKeyboardKey.f12,
  'f13': LogicalKeyboardKey.f13,
  'f14': LogicalKeyboardKey.f14,
  'f15': LogicalKeyboardKey.f15,
  'f16': LogicalKeyboardKey.f16,
  'f17': LogicalKeyboardKey.f17,
  'f18': LogicalKeyboardKey.f18,
  'f19': LogicalKeyboardKey.f19,
  'f20': LogicalKeyboardKey.f20,
};

/// The name [KeyActivator.toSpec] writes for each named key: the first name
/// [_namedKeys] lists for it.
final _specNames = <LogicalKeyboardKey, String>{
  for (final entry in _namedKeys.entries.toList().reversed)
    entry.value: entry.key,
};

/// How each named key is shown: (Apple platforms, elsewhere).
final _displayNames = <LogicalKeyboardKey, (String, String)>{
  LogicalKeyboardKey.enter: ('↩', 'Enter'),
  LogicalKeyboardKey.escape: ('Esc', 'Esc'),
  LogicalKeyboardKey.tab: ('⇥', 'Tab'),
  LogicalKeyboardKey.space: ('Space', 'Space'),
  LogicalKeyboardKey.backspace: ('⌫', 'Backspace'),
  LogicalKeyboardKey.delete: ('⌦', 'Delete'),
  LogicalKeyboardKey.arrowUp: ('↑', '↑'),
  LogicalKeyboardKey.arrowDown: ('↓', '↓'),
  LogicalKeyboardKey.arrowLeft: ('←', '←'),
  LogicalKeyboardKey.arrowRight: ('→', '→'),
  LogicalKeyboardKey.home: ('Home', 'Home'),
  LogicalKeyboardKey.end: ('End', 'End'),
  LogicalKeyboardKey.pageUp: ('PgUp', 'PgUp'),
  LogicalKeyboardKey.pageDown: ('PgDn', 'PgDn'),
  LogicalKeyboardKey.insert: ('Insert', 'Insert'),
  LogicalKeyboardKey.add: ('+', '+'),
  LogicalKeyboardKey.f1: ('F1', 'F1'),
  LogicalKeyboardKey.f2: ('F2', 'F2'),
  LogicalKeyboardKey.f3: ('F3', 'F3'),
  LogicalKeyboardKey.f4: ('F4', 'F4'),
  LogicalKeyboardKey.f5: ('F5', 'F5'),
  LogicalKeyboardKey.f6: ('F6', 'F6'),
  LogicalKeyboardKey.f7: ('F7', 'F7'),
  LogicalKeyboardKey.f8: ('F8', 'F8'),
  LogicalKeyboardKey.f9: ('F9', 'F9'),
  LogicalKeyboardKey.f10: ('F10', 'F10'),
  LogicalKeyboardKey.f11: ('F11', 'F11'),
  LogicalKeyboardKey.f12: ('F12', 'F12'),
};

/// Keys a text field always uses, whatever the modifiers.
final _textEditingKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.home,
  LogicalKeyboardKey.end,
  LogicalKeyboardKey.pageUp,
  LogicalKeyboardKey.pageDown,
  LogicalKeyboardKey.backspace,
  LogicalKeyboardKey.delete,
  LogicalKeyboardKey.enter,
};

/// Keys a text field uses with ⌘ or Ctrl: select all, copy, cut, paste, undo
/// and redo.
final _textCommandKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyC,
  LogicalKeyboardKey.keyX,
  LogicalKeyboardKey.keyV,
  LogicalKeyboardKey.keyZ,
  LogicalKeyboardKey.keyY,
};

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension DescribeOnKeyActivatorX on KeyActivator {
  /// Convenience alias for [KeyActivator.describe], matching the
  /// `debugName` pattern used elsewhere in the package.
  String get debugName => describe();
}

extension DescribeOnIterableKeyActivatorX on Iterable<KeyActivator> {
  /// Joined description of the activator sequence: e.g. `"⌘G"` for a
  /// single chord or `"G I"` for a two-step sequence.
  String get debugName => map((e) => e.describe()).join(' ');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Shorthand for activators. Prefer the text form ([KeyActivator.parse]).
extension KeyActivatorShorthandX on LogicalKeyboardKey {
  /// Bare key, no modifiers.
  KeyActivator get bare => LogicalKeyActivator(this);

  /// `meta` (Cmd on macOS/iOS, Ctrl elsewhere) + this key.
  KeyActivator get meta => LogicalKeyActivator(this, meta: true);

  /// Shift + this key.
  KeyActivator get shifted => LogicalKeyActivator(this, shift: true);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A logical-key activator. Same as [KeyActivator.logical].
class LogicalKeyActivator extends KeyActivator {
  const LogicalKeyActivator(
    LogicalKeyboardKey key, {
    super.meta,
    super.control,
    super.shift,
    super.alt,
  }) : super._(logical: key);
}

/// A physical-key activator. Same as [KeyActivator.physical].
class PhysicalKeyActivator extends KeyActivator {
  const PhysicalKeyActivator(
    PhysicalKeyboardKey key, {
    super.meta,
    super.control,
    super.shift,
    super.alt,
  }) : super._(physical: key);
}
