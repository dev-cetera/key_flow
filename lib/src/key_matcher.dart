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

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Where a person is in a [KeyTree]: at the top, or inside a group they
/// opened, with the keys of a longer binding pressed so far.
@immutable
final class KeyPosition {
  /// The group open now, or null at the top.
  final KeyGroupEntry? group;

  /// Keys pressed so far toward a binding of more than one key.
  final List<KeyStroke> pending;

  const KeyPosition._(this.group, this.pending);

  /// At the top of the tree, with nothing pressed.
  static const top = KeyPosition._(null, []);

  /// Whether a group is open or keys are pending, so the next key continues
  /// from here instead of starting over.
  bool get isOpen => group != null || pending.isNotEmpty;

  /// What can be pressed next from here in [tree], with the keys still to
  /// press for each.
  List<KeyNext> nextIn(KeyTree tree) {
    final level = group ?? tree.root;
    return [
      for (final item in level.reachable)
        for (final binding in item.bindings)
          if (binding.steps.length > pending.length &&
              binding.startsWith(pending))
            KeyNext._(item, KeyBinding(binding.steps.skip(pending.length))),
    ];
  }

  /// The labels of the open groups, outermost first: "Go to › Projects".
  List<String> get path => group?.path ?? const [];
}

/// One thing that can be pressed next, and the keys still to press for it.
@immutable
final class KeyNext {
  /// The command or group these keys lead to.
  final KeyItemEntry item;

  /// The keys still to press.
  final KeyBinding remaining;

  const KeyNext._(this.item, this.remaining);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What one key did.
sealed class KeyMatch {
  const KeyMatch();

  /// Whether key_flow used the key, so nothing else should.
  bool get handled => this is! KeyMatchIgnored;
}

/// The key is not a shortcut here; it goes on to the rest of the app.
final class KeyMatchIgnored extends KeyMatch {
  const KeyMatchIgnored();
}

/// The key moved the position (keys pending, a group left with Backspace) or
/// was taken while a group is open.
final class KeyMatchWaiting extends KeyMatch {
  const KeyMatchWaiting();
}

/// The key opened a group.
final class KeyMatchOpened extends KeyMatch {
  /// The group now open.
  final KeyGroupEntry group;

  const KeyMatchOpened(this.group);
}

/// The key finished a command's keys: run it.
final class KeyMatchRun extends KeyMatch {
  /// The command to run.
  final KeyCommandEntry command;

  const KeyMatchRun(this.command);
}

/// The key (Escape) closed what was open.
final class KeyMatchClosed extends KeyMatch {
  const KeyMatchClosed();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Follows keys through a [KeyTree], one at a time, and says what each did.
///
/// It holds no timers and runs nothing: [KeyFlow] does that with what it
/// returns. A group stays open until a command runs, Escape closes it or
/// Backspace leaves it, so no one has to be quick, an agent included.
final class KeyMatcher {
  /// Where the person is now.
  KeyPosition get position => _position;
  KeyPosition _position = KeyPosition.top;

  /// Goes back to the top.
  void close() => _position = KeyPosition.top;

  /// Opens [group], as if its keys had been pressed.
  void open(KeyGroupEntry group) => _position = KeyPosition._(group, const []);

  /// Follows [stroke] from the current position in [tree].
  ///
  /// [isRepeat] is true for a key held down: it repeats a one-key command
  /// (holding ↓ keeps moving) and does nothing else. [inTextField] is true
  /// while the person is typing in a text field: keys that type or edit text
  /// are left to it unless a group is open.
  KeyMatch handle(
    KeyStroke stroke,
    KeyTree tree, {
    bool isRepeat = false,
    bool inTextField = false,
  }) {
    if (stroke.isModifier) return const KeyMatchIgnored();
    final wasOpen = _position.isOpen;
    final level = _position.group ?? tree.root;

    if (wasOpen && stroke.isBare(LogicalKeyboardKey.escape)) {
      close();
      return const KeyMatchClosed();
    }
    if (wasOpen && stroke.isBare(LogicalKeyboardKey.backspace)) {
      return _back();
    }

    final typing = !wasOpen && inTextField;
    if (typing && stroke.editsText) return const KeyMatchIgnored();

    if (isRepeat) {
      if (wasOpen) return const KeyMatchWaiting();
      for (final item in level.reachable) {
        if (item is! KeyCommandEntry || !item.enabled) continue;
        for (final binding in item.bindings) {
          if (binding.steps.length != 1) continue;
          if (typing && binding.steps.first.typesText) continue;
          if (binding.steps.first.accepts(stroke)) return KeyMatchRun(item);
        }
      }
      return const KeyMatchIgnored();
    }

    final pressed = [..._position.pending, stroke];
    KeyItemEntry? exact;
    var partial = false;
    for (final item in level.reachable) {
      for (final binding in item.bindings) {
        if (typing && binding.steps.first.typesText) continue;
        if (!binding.startsWith(pressed)) continue;
        if (binding.steps.length == pressed.length) {
          // The nearer scope wins; within one scope, the first listed.
          if (exact == null || item.layer > exact.layer) exact = item;
        } else {
          partial = true;
        }
      }
    }

    switch (exact) {
      case KeyGroupEntry():
        open(exact);
        return KeyMatchOpened(exact);
      case KeyCommandEntry() when exact.enabled:
        close();
        return KeyMatchRun(exact);
      case KeyCommandEntry():
        // A disabled command's keys do nothing, and stay out of the app's way
        // when nothing is open.
        return wasOpen ? const KeyMatchWaiting() : const KeyMatchIgnored();
      case null:
        break;
    }
    if (partial) {
      _position = KeyPosition._(_position.group, List.unmodifiable(pressed));
      return const KeyMatchWaiting();
    }
    // An unknown key while a group is open is taken, and the group stays
    // open: a slip should not type into the app or close the panel.
    return wasOpen ? const KeyMatchWaiting() : const KeyMatchIgnored();
  }

  /// Backspace: drops the last pending key, else leaves the open group for
  /// the one it is in.
  KeyMatch _back() {
    final pending = _position.pending;
    if (pending.isNotEmpty) {
      _position = KeyPosition._(
        _position.group,
        List.unmodifiable(pending.sublist(0, pending.length - 1)),
      );
      return const KeyMatchWaiting();
    }
    var group = _position.group?.parent;
    while (group != null && !group.isRoot && group.bindings.isEmpty) {
      group = group.parent;
    }
    if (group == null || group.isRoot) {
      close();
      return const KeyMatchClosed();
    }
    open(group);
    return const KeyMatchWaiting();
  }
}
