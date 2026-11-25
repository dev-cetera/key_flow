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

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What a [KeyFlow] needs to give a [KeyPlayer].
abstract interface class KeyPlayerHost {
  /// The context of the [KeyFlow].
  BuildContext get context;

  /// Whether the [KeyFlow] is still in the tree.
  bool get mounted;

  /// Its controller.
  KeyFlowController get controller;

  /// Presses [stroke] as if typed, where the person is. False when nothing
  /// here takes it.
  bool pressStroke(KeyStroke stroke);

  /// [step] has played, with [defaultCursor] for a step naming none, out of
  /// the script's [cursors]: for a recording running meanwhile.
  void played(KeyStep step, String defaultCursor, List<KeyCursor> cursors);
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What a playing script shows on top of the app: its cursors, the rings
/// where they press, a caption and the keys being pressed.
final class KeyStage extends ChangeNotifier {
  final _cursors = <String, KeyStageCursor>{};

  /// The cursors, in the order the script gave them.
  Iterable<KeyStageCursor> get cursors => _cursors.values;

  /// The caption, if any.
  String? get caption => _caption;
  String? _caption;

  /// The keys being pressed, if any.
  KeyBinding? get keys => _keys;
  KeyBinding? _keys;

  /// Rings growing where a cursor pressed or pointed.
  List<KeyStageRing> get rings => List.unmodifiable(_rings);
  final _rings = <KeyStageRing>[];

  /// How long a ring lasts.
  static const ringLife = Duration(milliseconds: 650);

  /// Where each cursor was when the last script ended, so the next starts
  /// there.
  final _lastPositions = <String, Offset>{};

  /// Whether a recording is running, which shows as a badge.
  bool get isRecording => _isRecording;
  var _isRecording = false;

  /// Whether anything shows.
  bool get isActive => _cursors.isNotEmpty || _caption != null || _isRecording;

  /// Shows or hides the recording badge.
  void showRecording(bool on) {
    _isRecording = on;
    notifyListeners();
  }

  void _addCursor(KeyCursor cursor, Offset position) {
    _cursors[cursor.id] = KeyStageCursor._(cursor, position);
    notifyListeners();
  }

  KeyStageCursor _cursor(String id) => _cursors[id]!;

  void _update() => notifyListeners();

  void _pressCursor(String id, {required bool pressed}) {
    _cursor(id).pressed = pressed;
    notifyListeners();
  }

  void _setCaption(String? text) {
    _caption = text;
    notifyListeners();
  }

  void _setKeys(KeyBinding? keys) {
    _keys = keys;
    notifyListeners();
  }

  void _ring(Offset center, Color? color, Duration born, {required bool tap}) {
    _rings.add(KeyStageRing._(center, color, born, tap: tap));
    notifyListeners();
  }

  /// Drops rings older than [ringLife] at [now].
  void pruneRings(Duration now) {
    _rings.removeWhere((ring) => now - ring.born > ringLife);
  }

  void _clear() {
    for (final cursor in _cursors.values) {
      _lastPositions[cursor.cursor.id] = cursor.position;
    }
    _cursors.clear();
    _rings.clear();
    _caption = null;
    _keys = null;
    notifyListeners();
  }
}

/// A cursor on the [KeyStage].
final class KeyStageCursor {
  /// The cursor.
  final KeyCursor cursor;

  /// Where its tip is.
  Offset position;

  /// Whether it is pressing.
  bool pressed = false;

  /// How visible it is, from 0 to 1.
  double opacity = 0;

  KeyStageCursor._(this.cursor, this.position);
}

/// A ring where a cursor pressed or pointed.
final class KeyStageRing {
  /// Its centre.
  final Offset center;

  /// Its colour; the accent when null.
  final Color? color;

  /// The frame time it appeared.
  final Duration born;

  /// Whether a press made it (one quick ring) rather than a point (a pulse).
  final bool tap;

  const KeyStageRing._(this.center, this.color, this.born, {required this.tap});
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _Stopped implements Exception {
  const _Stopped();
}

/// A cursor while a script plays: the pointer device it presses with.
final class _Hand {
  final KeyCursor cursor;
  final int device;
  final int viewId;
  int? pointer;
  Offset position;

  _Hand(this.cursor, this.device, this.viewId, this.position);

  PointerDeviceKind get kind => switch (cursor.kind) {
    KeyCursorKind.mouse => PointerDeviceKind.mouse,
    KeyCursorKind.touch => PointerDeviceKind.touch,
  };

  int get buttons => switch (cursor.kind) {
    KeyCursorKind.mouse => kPrimaryMouseButton,
    KeyCursorKind.touch => kPrimaryButton,
  };
}

/// Plays [KeyScript]s on a [KeyFlow]: moves cursors on its [KeyStage] and
/// sends the app the pointer events a person's presses would.
final class KeyPlayer {
  final KeyPlayerHost host;
  final KeyStage stage;

  KeyPlayer({required this.host, required this.stage});

  /// Pointer and device numbers far from any a platform hands out.
  static var _nextPointer = 0x7A000000;
  static const _firstDevice = 0x7A00;

  final _hands = <String, _Hand>{};
  var _speed = 1.0;
  var _stamp = Duration.zero;
  Completer<void>? _stop;
  ui.PointerDataPacketCallback? _personPackets;

  /// Whether a script is playing.
  bool get isPlaying => _stop != null;

  /// Stops the script playing, if any, at its next frame.
  void stop() {
    final stop = _stop;
    if (stop != null && !stop.isCompleted) stop.complete();
  }

  bool get _stopping => _stop?.isCompleted ?? false;

  void _checkStop() {
    if (_stopping) throw const _Stopped();
  }

  /// Plays [script]; see [KeyFlowController.play].
  Future<KeyPlayEnd> play(
    KeyScript script, {
    required KeyPersonPress personPress,
  }) async {
    if (isPlaying) throw StateError('A script is already playing');
    final cursors = script.cursors.isEmpty
        ? [KeyCursor(id: 'main', kind: KeyCursorKind.forPlatform())]
        : script.cursors;
    final ids = <String>{};
    for (final cursor in cursors) {
      if (!ids.add(cursor.id)) {
        throw ArgumentError.value(cursor.id, 'cursors', 'given twice');
      }
    }
    _checkCursors(script.steps, ids);
    _stop = Completer<void>();
    _speed = script.speed;
    try {
      await _frame();
      _enter(cursors);
      _holdOffPerson(personPress);
      await _fade(to: 1);
      for (final step in script.steps) {
        await _do(step, cursors.first.id);
        host.played(step, cursors.first.id, cursors);
      }
      await _fade(to: 0);
      return KeyPlayEnd.finished;
    } on _Stopped {
      return KeyPlayEnd.stopped;
    } finally {
      _leave();
      _stop = null;
    }
  }

  void _checkCursors(List<KeyStep> steps, Set<String> ids) {
    for (final step in steps) {
      final cursor = step.cursor;
      if (cursor != null && !ids.contains(cursor)) {
        throw ArgumentError.value(cursor, 'cursor', 'not one of the script\'s');
      }
      if (step is KeyTogetherStep) {
        final used = <String?>{};
        for (final inner in step.steps) {
          if (!used.add(inner.cursor)) {
            throw ArgumentError.value(
              inner.cursor ?? '(the first)',
              'cursor',
              'used twice in one "together" step',
            );
          }
        }
        _checkCursors(step.steps, ids);
      }
    }
  }

  // ── Entering and leaving ──────────────────────────────────────────────────

  int get _viewId => View.of(host.context).viewId;

  Size get _viewSize {
    final view = View.of(host.context);
    return view.physicalSize / view.devicePixelRatio;
  }

  void _enter(List<KeyCursor> cursors) {
    final size = _viewSize;
    for (var i = 0; i < cursors.length; i++) {
      final cursor = cursors[i];
      final start =
          stage._lastPositions[cursor.id] ??
          Offset(
            size.width * (i + 1) / (cursors.length + 1),
            size.height * 0.85,
          );
      final hand = _Hand(cursor, _firstDevice + i, _viewId, start);
      _hands[cursor.id] = hand;
      stage._addCursor(cursor, start);
      if (hand.kind == PointerDeviceKind.mouse) {
        _send(
          PointerAddedEvent(
            viewId: hand.viewId,
            timeStamp: _stamp,
            kind: hand.kind,
            device: hand.device,
            position: start,
          ),
        );
      }
    }
  }

  void _leave() {
    for (final hand in _hands.values) {
      final pointer = hand.pointer;
      if (pointer != null) {
        _send(
          PointerCancelEvent(
            viewId: hand.viewId,
            timeStamp: _stamp,
            pointer: pointer,
            kind: hand.kind,
            device: hand.device,
            position: hand.position,
          ),
        );
        hand.pointer = null;
      }
      if (hand.kind == PointerDeviceKind.mouse) {
        _send(
          PointerRemovedEvent(
            viewId: hand.viewId,
            timeStamp: _stamp,
            kind: hand.kind,
            device: hand.device,
            position: hand.position,
          ),
        );
      }
    }
    _hands.clear();
    _letPersonBack();
    // A KeyFlow taken away mid-script has stopped it and disposed its stage.
    if (host.mounted) stage._clear();
  }

  /// Keeps the person's own pointer away from the app while the script
  /// plays, so a stray press cannot change what the script acts on.
  void _holdOffPerson(KeyPersonPress personPress) {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    _personPackets = dispatcher.onPointerDataPacket;
    dispatcher.onPointerDataPacket = (packet) {
      final pressed = packet.data.any(
        (data) => data.change == ui.PointerChange.down,
      );
      switch (personPress) {
        case KeyPersonPress.stops:
          if (pressed) stop();
        case KeyPersonPress.ignored:
          break;
      }
    };
  }

  void _letPersonBack() {
    final personPackets = _personPackets;
    if (personPackets == null) return;
    WidgetsBinding.instance.platformDispatcher.onPointerDataPacket =
        personPackets;
    _personPackets = null;
  }

  Future<void> _fade({required double to}) async {
    final from = stage.cursors.firstOrNull?.opacity ?? 0;
    await _animate(const Duration(milliseconds: 200), (t) {
      for (final cursor in stage.cursors) {
        cursor.opacity = from + (to - from) * t;
      }
      stage._update();
    });
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  Duration _scaled(Duration duration) => duration * (1 / _speed);

  Duration get _settle => _scaled(const Duration(milliseconds: 450));

  Future<void> _do(KeyStep step, String first) async {
    _checkStop();
    final hand = _hands[step.cursor ?? first]!;
    switch (step) {
      case KeyPointStep(:final at):
        final spot = await _reach(hand, at, mustReach: false);
        stage._ring(spot.rect.center, hand.cursor.color, _stamp, tap: false);
        await _sleep(_scaled(const Duration(milliseconds: 700)));
      case KeyTapStep(:final at):
        await _tap(hand, at);
        await _sleep(_settle);
      case KeyHoldStep(:final at, :final duration):
        await _reach(hand, at, mustReach: true);
        _down(hand);
        await _sleep(duration);
        _up(hand);
        await _sleep(_settle);
      case KeyDragStep(:final at, :final to, :final by, :final hold):
        await _drag(hand, at, to: to, by: by, hold: hold);
        await _sleep(_settle);
      case KeyScrollToStep(:final at, :final within):
        await _scrollTo(hand, at, within);
        await _sleep(_settle);
      case KeyTypeStep(:final text, :final at, :final submit):
        if (at != null) {
          await _tap(hand, at);
          // Let the field take the focus, as a person waits to see the caret.
          await _frame();
          await _sleep(_scaled(const Duration(milliseconds: 250)));
        }
        await _type(text, submit: submit);
        await _sleep(_settle);
      case KeyPressStep(:final keys):
        await _press(keys);
        await _sleep(_settle);
      case KeyRunStep(:final command, :final args):
        await _run(hand, command, args);
        await _sleep(_settle);
      case KeyCaptionStep(:final text):
        stage._setCaption(text.isEmpty ? null : text);
      case KeyWaitStep(:final duration):
        await _sleep(_scaled(duration));
      case KeyWaitForStep(:final at, :final timeout):
        await _waitFor(at, timeout);
      case KeyTogetherStep(:final steps):
        await Future.wait([for (final inner in steps) _do(inner, first)]);
    }
  }

  /// The spot [at] names, scrolled into view.
  ///
  /// With [mustReach], throws a [StateError] when something is drawn over
  /// it, as a press there would reach that instead.
  Future<KeySpot> _ready(
    String at,
    _Hand hand, {
    required bool mustReach,
  }) async {
    var spot = await _settled(at);
    final view = Offset.zero & _viewSize;
    if (!_contains(view, spot.rect)) {
      await Scrollable.ensureVisible(
        spot.context,
        alignment: 0.5,
        duration: _scaled(const Duration(milliseconds: 400)),
        curve: Curves.easeInOutCubic,
      );
      spot = await _settled(at);
    }
    if (!view.contains(spot.rect.center)) {
      throw StateError('"$at" is off screen and could not be scrolled to');
    }
    if (mustReach && !spot.reachable) {
      throw StateError(
        '"$at" is covered by something drawn over it, which a press there '
        'would reach instead',
      );
    }
    return spot;
  }

  /// The spot [at] names once it stays put from one frame to the next, as
  /// a person waits for a sheet to slide up or a page to slide in. Something
  /// that never stops moving is taken where it is after [_settleLimit].
  Future<KeySpot> _settled(String at) async {
    var spot = host.controller.findSpot(at);
    for (var i = 0; i < _settleLimit; i++) {
      await _frame();
      final next = host.controller.findSpot(at);
      if (next.rect == spot.rect) return next;
      spot = next;
    }
    return spot;
  }

  static const _settleLimit = 90;

  /// Moves [hand] onto the spot [at] names, following it if it moved while
  /// the cursor travelled, and returns it.
  Future<KeySpot> _reach(
    _Hand hand,
    String at, {
    required bool mustReach,
  }) async {
    var spot = await _ready(at, hand, mustReach: mustReach);
    for (var i = 0; i < 3; i++) {
      await _move(hand, spot.rect.center);
      final now = host.controller.findSpot(at);
      if ((now.rect.center - spot.rect.center).distance < 1) return now;
      spot = await _ready(at, hand, mustReach: mustReach);
    }
    return spot;
  }

  static bool _contains(Rect outer, Rect inner) {
    return outer.contains(inner.topLeft) &&
        outer.contains(inner.bottomRight - const Offset(0.5, 0.5));
  }

  Future<void> _tap(_Hand hand, String at) async {
    await _reach(hand, at, mustReach: true);
    _down(hand);
    // Long enough to see, short enough to stay a tap.
    await _sleep(const Duration(milliseconds: 90));
    _up(hand);
    stage._ring(hand.position, hand.cursor.color, _stamp, tap: true);
  }

  Future<void> _drag(
    _Hand hand,
    String at, {
    required String? to,
    required Offset? by,
    required Duration hold,
  }) async {
    final spot = await _reach(hand, at, mustReach: true);
    final start = spot.rect.center;
    final end = to != null ? host.controller.findSpot(to).rect.center : null;
    _down(hand);
    await _sleep(hold == Duration.zero ? _scaled(_pressPause) : hold);
    final target = end ?? start + by!;
    final distance = (target - start).distance;
    await _animate(_scaled(_travelTime(distance) * 1.4), (t) {
      final next = Offset.lerp(start, target, Curves.easeInOut.transform(t))!;
      _moveDown(hand, next);
    });
    await _sleep(_scaled(_pressPause));
    _up(hand);
  }

  static const _pressPause = Duration(milliseconds: 150);

  /// Swipes the list [within] until [at] shows: towards its end, then back
  /// towards its start.
  Future<void> _scrollTo(_Hand hand, String at, String within) async {
    final wanted = KeyPlace.parse(at);
    bool showing() {
      final count = host.controller.spots.where(wanted.matches).length;
      return count > (wanted.index ?? 0);
    }

    var towardsEnd = true;
    for (var swipes = 0; swipes < _swipeLimit; swipes++) {
      if (showing()) {
        await _ready(at, hand, mustReach: false);
        return;
      }
      final list = host.controller.findSpot(within);
      final scrollable = _scrollableIn(list.context);
      if (scrollable == null) {
        throw StateError('"$within" holds nothing that scrolls');
      }
      final position = scrollable.position;
      final atEdge = towardsEnd
          ? position.pixels >= position.maxScrollExtent
          : position.pixels <= position.minScrollExtent;
      if (atEdge) {
        if (!towardsEnd) break;
        towardsEnd = false;
        continue;
      }
      final vertical =
          axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical;
      final length = (vertical ? list.rect.height : list.rect.width) * 0.6;
      // A finger moves against the way the content scrolls.
      var sign = towardsEnd ? -1.0 : 1.0;
      if (axisDirectionIsReversed(scrollable.axisDirection)) sign = -sign;
      await _drag(
        hand,
        within,
        to: null,
        by: vertical ? Offset(0, sign * length) : Offset(sign * length, 0),
        hold: Duration.zero,
      );
      await _sleep(_scaled(const Duration(milliseconds: 200)));
    }
    throw StateError('"$at" did not show while scrolling "$within" through');
  }

  static const _swipeLimit = 60;

  /// The first [Scrollable] at or under [context].
  static ScrollableState? _scrollableIn(BuildContext context) {
    ScrollableState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        found = element.state as ScrollableState;
        return;
      }
      element.visitChildElements(visit);
    }

    visit(context as Element);
    return found;
  }

  Future<void> _type(String text, {required bool submit}) async {
    final field = _focusedField();
    if (field == null) {
      throw StateError('No text field has the focus to type into');
    }
    var i = 0;
    for (final character in text.characters) {
      _checkStop();
      final value = field.textEditingValue;
      final selection = value.selection.isValid
          ? value.selection
          : TextSelection.collapsed(offset: value.text.length);
      field.userUpdateTextEditingValue(
        value.replaced(selection, character),
        SelectionChangedCause.keyboard,
      );
      // An uneven rhythm reads as a person typing.
      final ms = 55 + (i * 37) % 50 + (character == ' ' ? 40 : 0);
      await _sleep(_scaled(Duration(milliseconds: ms)));
      i++;
    }
    if (submit) {
      final action = field.widget.textInputAction;
      field.performAction(
        action == null || action == TextInputAction.newline
            ? TextInputAction.done
            : action,
      );
    }
  }

  static EditableTextState? _focusedField() {
    final focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) return null;
    return focused.findAncestorStateOfType<EditableTextState>();
  }

  Future<void> _press(String keys) async {
    final binding = KeyBinding.parse(keys);
    stage._setKeys(binding);
    try {
      await _sleep(_scaled(const Duration(milliseconds: 350)));
      for (final step in binding.steps) {
        _checkStop();
        if (!host.pressStroke(step.toStroke())) {
          throw StateError('"$keys" does nothing here');
        }
        await _frame();
        await _sleep(_scaled(const Duration(milliseconds: 300)));
      }
      await _sleep(_scaled(const Duration(milliseconds: 500)));
    } finally {
      stage._setKeys(null);
    }
  }

  Future<void> _run(
    _Hand hand,
    String command,
    Map<String, Object?> args,
  ) async {
    final spot = _controlOf(command);
    if (spot != null && spot.reachable && args.isEmpty) {
      await _tap(hand, spot.place);
      return;
    }
    if (spot != null) {
      await _move(hand, spot.rect.center);
      stage._pressCursor(hand.cursor.id, pressed: true);
      await _sleep(const Duration(milliseconds: 90));
      stage._pressCursor(hand.cursor.id, pressed: false);
      stage._ring(hand.position, hand.cursor.color, _stamp, tap: true);
    }
    await host.controller.run(command, args: args);
  }

  /// The one control of [command] on screen, if exactly one shows.
  KeySpot? _controlOf(String command) {
    final controls = [
      for (final spot in host.controller.spots)
        if (spot.id == command) spot,
    ];
    return controls.length == 1 ? controls.single : null;
  }

  Future<void> _waitFor(String at, Duration timeout) async {
    final wanted = KeyPlace.parse(at);
    final deadline = DateTime.now().add(timeout);
    var waited = Duration.zero;
    const poll = Duration(milliseconds: 100);
    while (true) {
      _checkStop();
      final showing = host.controller.spots.where(wanted.matches).length;
      if (showing > (wanted.index ?? 0)) return;
      // Counts both ways, so it times out under a test's fake clock too.
      if (waited >= timeout || DateTime.now().isAfter(deadline)) {
        throw StateError(
          '"$at" did not show within ${timeout.inMilliseconds} ms',
        );
      }
      await _sleep(poll);
      waited += poll;
    }
  }

  // ── Moving and pressing ───────────────────────────────────────────────────

  static Duration _travelTime(double distance) {
    final ms = (260 + distance * 0.55).clamp(260, 1000).round();
    return Duration(milliseconds: ms);
  }

  /// Moves [hand] to [target] along a gentle arc, as a hand moves.
  Future<void> _move(_Hand hand, Offset target) async {
    final start = hand.position;
    final distance = (target - start).distance;
    if (distance < 1) return;
    final direction = (target - start) / distance;
    final bend = math.min(distance * 0.12, 40.0);
    final control =
        Offset.lerp(start, target, 0.5)! +
        Offset(-direction.dy, direction.dx) * bend;
    await _animate(_scaled(_travelTime(distance)), (t) {
      final u = Curves.easeInOutCubic.transform(t);
      final a = Offset.lerp(start, control, u)!;
      final b = Offset.lerp(control, target, u)!;
      final next = Offset.lerp(a, b, u)!;
      if (hand.pointer != null) {
        _moveDown(hand, next);
      } else {
        _hover(hand, next);
      }
    });
  }

  void _hover(_Hand hand, Offset to) {
    final from = hand.position;
    hand.position = to;
    stage._cursor(hand.cursor.id).position = to;
    stage._update();
    if (hand.kind != PointerDeviceKind.mouse) return;
    _send(
      PointerHoverEvent(
        viewId: hand.viewId,
        timeStamp: _stamp,
        kind: hand.kind,
        device: hand.device,
        position: to,
        delta: to - from,
      ),
    );
  }

  void _down(_Hand hand) {
    final pointer = _nextPointer++;
    hand.pointer = pointer;
    stage._pressCursor(hand.cursor.id, pressed: true);
    _send(
      PointerDownEvent(
        viewId: hand.viewId,
        timeStamp: _stamp,
        pointer: pointer,
        kind: hand.kind,
        device: hand.device,
        position: hand.position,
        buttons: hand.buttons,
      ),
    );
  }

  void _moveDown(_Hand hand, Offset to) {
    final from = hand.position;
    hand.position = to;
    stage._cursor(hand.cursor.id).position = to;
    stage._update();
    _send(
      PointerMoveEvent(
        viewId: hand.viewId,
        timeStamp: _stamp,
        pointer: hand.pointer!,
        kind: hand.kind,
        device: hand.device,
        position: to,
        delta: to - from,
        buttons: hand.buttons,
      ),
    );
  }

  void _up(_Hand hand) {
    final pointer = hand.pointer!;
    hand.pointer = null;
    stage._pressCursor(hand.cursor.id, pressed: false);
    _send(
      PointerUpEvent(
        viewId: hand.viewId,
        timeStamp: _stamp,
        pointer: pointer,
        kind: hand.kind,
        device: hand.device,
        position: hand.position,
      ),
    );
  }

  static void _send(PointerEvent event) {
    GestureBinding.instance.handlePointerEvent(event);
  }

  // ── Time ──────────────────────────────────────────────────────────────────

  /// Waits for the next frame, and notes its time. Throws [_Stopped] when
  /// the script was stopped meanwhile.
  Future<void> _frame() async {
    final drawn = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _stamp = timeStamp;
      drawn.complete();
    }, debugLabel: 'KeyPlayer.frame');
    SchedulerBinding.instance.ensureVisualUpdate();
    await drawn.future;
    _checkStop();
  }

  /// Calls [onTick] once a frame with how far through [duration] it is, from
  /// just above 0 to 1.
  Future<void> _animate(
    Duration duration,
    void Function(double t) onTick,
  ) async {
    await _frame();
    final start = _stamp;
    while (true) {
      _checkStop();
      await _frame();
      final elapsed = _stamp - start;
      final t = duration == Duration.zero
          ? 1.0
          : (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
      onTick(t);
      if (t >= 1) return;
    }
  }

  Future<void> _sleep(Duration duration) async {
    _checkStop();
    final stop = _stop!;
    final timer = Completer<void>();
    final waiting = Timer(duration, timer.complete);
    await Future.any([timer.future, stop.future]);
    waiting.cancel();
    _checkStop();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Draws a [KeyStage] over the app. Takes no pointer events and is hidden
/// from screen readers.
class KeyStageLayer extends StatefulWidget {
  final KeyStage stage;

  const KeyStageLayer({super.key, required this.stage});

  @override
  State<KeyStageLayer> createState() => _KeyStageLayerState();
}

class _KeyStageLayerState extends State<KeyStageLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _tick());

  @override
  void initState() {
    super.initState();
    widget.stage.addListener(_changed);
  }

  @override
  void didUpdateWidget(KeyStageLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.stage, widget.stage)) {
      oldWidget.stage.removeListener(_changed);
      widget.stage.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.stage.removeListener(_changed);
    _ticker.dispose();
    super.dispose();
  }

  void _changed() {
    if (widget.stage.rings.isNotEmpty && !_ticker.isActive) _ticker.start();
    setState(() {});
  }

  /// Keeps the rings growing between the player's own frames.
  void _tick() {
    final stage = widget.stage;
    stage.pruneRings(SchedulerBinding.instance.currentFrameTimeStamp);
    if (stage.rings.isEmpty) _ticker.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage;
    if (!stage.isActive && stage.rings.isEmpty) return const SizedBox.shrink();
    final style = KeyFlowStyle.of(context);
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    final keys = stage.keys;
    final caption = stage.caption;
    final bottom = MediaQuery.maybePaddingOf(context)?.bottom ?? 0;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _RingPainter(stage.rings, now, style.accent)),
            if (keys != null || caption != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: bottom + 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (keys != null) _KeysCard(keys: keys, style: style),
                    if (keys != null && caption != null)
                      const SizedBox(height: 12),
                    if (caption != null)
                      _CaptionCard(text: caption, style: style),
                  ],
                ),
              ),
            if (stage.isRecording)
              Positioned(
                top: (MediaQuery.maybePaddingOf(context)?.top ?? 0) + 8,
                left: 0,
                right: 0,
                child: Center(
                  child: _RecordingBadge(
                    text: KeyFlow.of(context).strings.recording,
                    style: style,
                  ),
                ),
              ),
            for (final cursor in stage.cursors) ..._cursor(cursor, style),
          ],
        ),
      ),
    );
  }

  List<Widget> _cursor(KeyStageCursor stageCursor, KeyFlowStyle style) {
    final cursor = stageCursor.cursor;
    final color = cursor.color ?? style.accent;
    final at = stageCursor.position;
    final label = cursor.label;
    return [
      switch (cursor.kind) {
        KeyCursorKind.mouse => Positioned(
          left: at.dx - 2,
          top: at.dy - 2,
          child: Opacity(
            opacity: stageCursor.opacity,
            child: CustomPaint(
              size: const Size(26, 32),
              painter: _ArrowPainter(
                color: color,
                pressed: stageCursor.pressed,
              ),
            ),
          ),
        ),
        KeyCursorKind.touch => Positioned(
          left: at.dx - 22,
          top: at.dy - 22,
          child: Opacity(
            opacity: stageCursor.opacity,
            child: CustomPaint(
              size: const Size(44, 44),
              painter: _FingerPainter(
                color: color,
                pressed: stageCursor.pressed,
              ),
            ),
          ),
        ),
      },
      if (label != null)
        Positioned(
          left: at.dx + (cursor.kind == KeyCursorKind.mouse ? 16 : 20),
          top: at.dy + (cursor.kind == KeyCursorKind.mouse ? 24 : 18),
          child: Opacity(
            opacity: stageCursor.opacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(blurRadius: 6, color: Color(0x33000000)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  label,
                  style: style.textStyle.copyWith(
                    color: _onColor(color),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  static Color _onColor(Color color) {
    return color.computeLuminance() > 0.5
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
  }
}

class _RecordingBadge extends StatelessWidget {
  final String text;
  final KeyFlowStyle style;

  const _RecordingBadge({required this.text, required this.style});

  static const _red = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _red),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: _red, shape: BoxShape.circle),
              child: SizedBox.square(dimension: 10),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: style.textStyle.copyWith(
                color: style.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  final String text;
  final KeyFlowStyle style;

  const _CaptionCard({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.surface,
          borderRadius: BorderRadius.circular(style.radius + 4),
          border: Border.all(color: style.border),
          boxShadow: const [
            BoxShadow(blurRadius: 18, color: Color(0x33000000)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: style.textStyle.copyWith(
              color: style.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeysCard extends StatelessWidget {
  final KeyBinding keys;
  final KeyFlowStyle style;

  const _KeysCard({required this.keys, required this.style});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(style.radius),
        border: Border.all(color: style.border),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x33000000))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: KeyCaps(binding: keys),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _RingPainter extends CustomPainter {
  final List<KeyStageRing> rings;
  final Duration now;
  final Color accent;

  const _RingPainter(this.rings, this.now, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    for (final ring in rings) {
      final age =
          (now - ring.born).inMicroseconds / KeyStage.ringLife.inMicroseconds;
      if (age < 0 || age > 1) continue;
      final color = ring.color ?? accent;
      final grown = Curves.easeOutCubic.transform(age);
      final radius = ring.tap ? 10 + 26 * grown : 18 + 34 * grown;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.tap ? 3 : 4
        ..color = color.withValues(alpha: (1 - age) * 0.9);
      canvas.drawCircle(ring.center, radius, paint);
      if (ring.tap) {
        canvas.drawCircle(
          ring.center,
          radius * 0.8,
          Paint()..color = color.withValues(alpha: (1 - age) * 0.18),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => true;
}

/// An arrow pointer with its tip at (2, 2).
class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pressed;

  const _ArrowPainter({required this.color, required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(2, 2);
    if (pressed) canvas.scale(0.88);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 21)
      ..lineTo(5.2, 16)
      ..lineTo(8.8, 24.2)
      ..lineTo(12.2, 22.7)
      ..lineTo(8.7, 14.8)
      ..lineTo(15.6, 14.8)
      ..close();
    canvas.drawShadow(path, const Color(0xFF000000), 3, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pressed != pressed;
  }
}

/// A fingertip centred in its box.
class _FingerPainter extends CustomPainter {
  final Color color;
  final bool pressed;

  const _FingerPainter({required this.color, required this.pressed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = pressed ? 14.0 : 17.0;
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: pressed ? 0.75 : 0.45),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_FingerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pressed != pressed;
  }
}
