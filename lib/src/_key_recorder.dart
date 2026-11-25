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

import 'package:flutter/gestures.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What a [KeyRecorder] needs from the [KeyFlow] it records.
abstract interface class KeyRecorderHost {
  /// The controller, for the anchors on screen.
  KeyFlowController get controller;

  /// Whether a script is playing: its steps are recorded as they are, and
  /// the presses and keys it makes are not.
  bool get isPlaying;

  /// Whether one of key_flow's panels shows, whose search field is not the
  /// app's.
  bool get isPanelShowing;
}

/// Watches a person (or an agent pressing for real) use the app and writes
/// it into a [KeyRecording] as steps: presses on anchors, the keys key_flow
/// handles, text typed into fields, commands run, and the steps of scripts
/// played meanwhile.
final class KeyRecorder {
  /// The id of the cursor the person's presses play back with.
  static const personCursor = 'you';

  final KeyRecorderHost host;
  final KeyRecording recording;

  KeyRecorder({required this.host, required this.recording});

  final _presses = <int, _Press>{};
  final _keys = <String>[];
  final _offsets = <ScrollableState, double>{};

  /// True while a press or a key just recorded is still being handled, so
  /// the command it runs is not recorded again.
  var _quiet = false;

  /// True while the press, key or run that started at [_markSteps] and
  /// [_markMisses] is still being handled: if it stops the recording, what
  /// it added is taken back.
  var _inEvent = false;
  var _markSteps = 0;
  var _markMisses = 0;

  EditableTextState? _field;
  TextEditingController? _text;
  var _base = '';
  var _typed = '';
  var _enter = false;

  /// Starts watching.
  void start() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    FocusManager.instance.addListener(_onFocus);
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    _onFocus();
  }

  /// Writes down what is still pending, stops watching and ends the
  /// recording. The press or keys that stopped it, if any, are left out.
  void stop() {
    if (_inEvent) {
      _keys.clear();
      recording.truncate(steps: _markSteps, misses: _markMisses);
    }
    _flush();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    FocusManager.instance.removeListener(_onFocus);
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _unwatchField();
    for (final press in _presses.values) {
      press.dispose();
    }
    _presses.clear();
    _offsets.clear();
    recording.end();
  }

  // ── What the KeyFlow reports ──────────────────────────────────────────────

  /// A script played [step], its default cursor being [defaultCursor].
  void played(KeyStep step, String defaultCursor, List<KeyCursor> cursors) {
    _flush();
    for (final cursor in cursors) {
      recording.addCursor(cursor);
    }
    recording.add(_withCursor(step, defaultCursor));
  }

  /// key_flow handled [stroke]; [done] when it ran a command or closed what
  /// was open, ending a sequence such as `g p 1`.
  void stroke(KeyStroke stroke, {required bool done}) {
    if (host.isPlaying) return;
    _flushTyping();
    _begin();
    _hush();
    final spec = _specOf(stroke);
    if (spec == null) {
      _flushKeys();
      recording.miss(
        KeyRecordingMiss('The key $stroke has no written form to press'),
      );
      return;
    }
    _keys.add(spec);
    if (done) _flushKeys();
  }

  /// The command or group [id] ran with [args], from code, an agent, a menu
  /// or a panel.
  void ran(String id, Map<String, Object?> args) {
    if (host.isPlaying || _quiet) return;
    _flush();
    _begin();
    recording.add(KeyRunStep(id, args: Map.unmodifiable(args)));
  }

  // ── Presses ───────────────────────────────────────────────────────────────

  void _onPointer(PointerEvent event) {
    if (host.isPlaying) {
      for (final press in _presses.values) {
        press.dispose();
      }
      _presses.clear();
      return;
    }
    if (event is PointerDownEvent) {
      // A right click or a second button is not a press a step makes.
      if (event.buttons != kPrimaryButton) return;
      _presses[event.pointer] = _Press(event, _aimAt(event));
    } else if (event is PointerMoveEvent) {
      _presses[event.pointer]?.moveTo(event);
    } else if (event is PointerUpEvent) {
      final press = _presses.remove(event.pointer);
      if (press != null) _pressed(press, event);
    } else if (event is PointerCancelEvent) {
      _presses.remove(event.pointer)?.dispose();
    }
  }

  void _pressed(_Press press, PointerUpEvent up) {
    press.dispose();
    final aim = press.aim;
    _flush();
    _begin();
    if (aim.spot == null) {
      // The command it ran, if any, is recorded by [ran].
      recording.miss(
        KeyRecordingMiss(
          'A press on ${aim.hit} is inside no KeyAnchor; wrap what it '
          'pressed in one to record it',
          position: press.start,
        ),
      );
      return;
    }
    recording.addCursor(
      KeyCursor(
        id: personCursor,
        kind:
            press.kind == PointerDeviceKind.touch ||
                press.kind == PointerDeviceKind.stylus
            ? KeyCursorKind.touch
            : KeyCursorKind.mouse,
      ),
    );
    if (aim.scrolledUnnamed) {
      recording.miss(
        KeyRecordingMiss(
          'The list around "${aim.place}" was scrolled, but no KeyAnchor '
          'holds it to scroll by; wrap the list in one so a replay finds it',
          position: press.start,
        ),
      );
    }
    final list = aim.list;
    if (list != null) {
      recording.add(
        KeyScrollToStep(aim.place, within: list, cursor: personCursor),
      );
    }
    final held = press.heldFor(up.timeStamp);
    final still = press.stillFor;
    final KeyStep step;
    if (still == null) {
      step = held >= kLongPressTimeout
          ? KeyHoldStep(aim.place, duration: _round(held), cursor: personCursor)
          : KeyTapStep(aim.place, cursor: personCursor);
    } else {
      final by = up.position - press.start;
      step = KeyDragStep(
        aim.place,
        by: Offset(by.dx.roundToDouble(), by.dy.roundToDouble()),
        hold: still >= kLongPressTimeout ? _round(still) : Duration.zero,
        cursor: personCursor,
      );
    }
    recording.add(step);
    // What the press runs is part of it.
    _hush();
  }

  _Aim _aimAt(PointerDownEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    RenderObject? hit;
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderObject) {
        hit = target;
        break;
      }
    }
    final spots = host.controller.spots;
    KeySpot? best;
    if (hit != null) {
      for (final spot in spots) {
        final box = spot.context.findRenderObject();
        if (box == null || !_isAtOrInside(hit, box)) continue;
        if (best == null || spot.within.length > best.within.length) {
          best = spot;
        }
      }
    }
    if (best == null) {
      return _Aim.none(hit == null ? 'nothing' : hit.toStringShort());
    }
    final scrollable = _scrollableAround(best);
    String? list;
    var scrolled = false;
    if (scrollable != null) {
      // Since the last press in it, or from its start: a replay starts from
      // a fresh screen.
      final pixels = scrollable.position.pixels;
      final known = _offsets[scrollable] ?? scrollable.position.minScrollExtent;
      _offsets[scrollable] = pixels;
      scrolled = (pixels - known).abs() > 1;
      if (scrolled) list = _listAnchorOf(scrollable, spots);
    }
    return _Aim(
      spot: best,
      place: _placeOf(best, spots),
      list: list,
      scrolledUnnamed: scrolled && list == null,
      scrollable: scrollable,
    );
  }

  static ScrollableState? _scrollableAround(KeySpot spot) {
    final context = spot.context;
    if (!context.mounted) return null;
    return context.findAncestorStateOfType<ScrollableState>();
  }

  /// The place of the anchor holding [scrollable], if one does.
  static String? _listAnchorOf(
    ScrollableState scrollable,
    List<KeySpot> spots,
  ) {
    Element? anchor;
    scrollable.context.visitAncestorElements((element) {
      if (element.widget is KeyAnchor) {
        anchor = element;
        return false;
      }
      return true;
    });
    for (final spot in spots) {
      if (identical(spot.context, anchor)) return _placeOf(spot, spots);
    }
    return null;
  }

  /// The shortest place that names [spot] alone among [spots]: its id, then
  /// with the anchors around it, then counted.
  static String _placeOf(KeySpot spot, List<KeySpot> spots) {
    final chain = [...spot.within, spot.id];
    for (var from = chain.length - 1; from >= 0; from--) {
      final text = chain.sublist(from).join('/');
      final place = KeyPlace.parse(text);
      if (spots.where(place.matches).length == 1) return text;
    }
    final text = chain.join('/');
    final place = KeyPlace.parse(text);
    final index = spots
        .where(place.matches)
        .toList()
        .indexWhere((other) => identical(other.context, spot.context));
    return '$text[$index]';
  }

  static bool _isAtOrInside(RenderObject node, RenderObject outer) {
    for (RenderObject? at = node; at != null; at = at.parent) {
      if (identical(at, outer)) return true;
    }
    return false;
  }

  static Duration _round(Duration duration) {
    return Duration(
      milliseconds: (duration.inMilliseconds / 100).round() * 100,
    );
  }

  // ── Keys ──────────────────────────────────────────────────────────────────

  /// How [stroke] is written so a script presses the same: by what it typed
  /// when no ⌘ or Ctrl is held, else by its key, with `meta` for the
  /// platform's command key (⌘ on Apple platforms, Ctrl elsewhere) so it
  /// plays back on either.
  static String? _specOf(KeyStroke stroke) {
    final character = stroke.character;
    final apple = KeyActivator.isAppleHost;
    final candidates = [
      if (character != null &&
          character.runes.length == 1 &&
          character.trim().isNotEmpty &&
          !stroke.meta &&
          !stroke.control)
        KeyActivator.character(character, alt: stroke.alt).toSpec(),
      KeyActivator.logical(
        stroke.logical,
        meta: apple ? stroke.meta : stroke.control,
        control: apple && stroke.control,
        shift: stroke.shift,
        alt: stroke.alt,
      ).toSpec(),
    ];
    for (final spec in candidates) {
      if (KeyActivator.parse(spec).accepts(stroke)) return spec;
    }
    return null;
  }

  void _flushKeys() {
    if (_keys.isEmpty) return;
    recording.add(KeyPressStep(_keys.join(' ')));
    _keys.clear();
  }

  // ── Typing ────────────────────────────────────────────────────────────────

  void _onFocus() {
    final focused = FocusManager.instance.primaryFocus?.context;
    final field = focused?.findAncestorStateOfType<EditableTextState>();
    if (identical(field, _field)) return;
    _flushTyping();
    _unwatchField();
    if (field == null || host.isPanelShowing) return;
    _field = field;
    final text = field.widget.controller;
    _text = text;
    _base = text.text;
    _typed = '';
    _enter = false;
    text.addListener(_onText);
  }

  void _unwatchField() {
    _text?.removeListener(_onText);
    _text = null;
    _field = null;
  }

  void _onText() {
    final text = _text!.text;
    if (host.isPlaying) {
      _base = text;
      _typed = '';
      return;
    }
    final current = _base + _typed;
    if (text == current) return;
    if (_enter && !text.startsWith(current)) {
      // Submitted, then emptied or changed by the app.
      _flushTyping();
      return;
    }
    if (text.startsWith(_base)) {
      // Typed, or corrected what was typed.
      _typed = text.substring(_base.length);
      return;
    }
    // Changed before where the typing started: a field emptied as it was
    // submitted, or the app setting its text. What was typed stands.
    _flushTyping();
    _base = text;
  }

  bool _onHardwareKey(KeyEvent event) {
    final field = _field;
    if (event is KeyDownEvent &&
        field != null &&
        field.mounted &&
        field.widget.maxLines == 1 &&
        !host.isPlaying &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      _enter = true;
    }
    return false;
  }

  void _flushTyping() {
    final text = _text;
    if (text == null) return;
    if (_typed.isNotEmpty || _enter) {
      recording.add(KeyTypeStep(_typed, submit: _enter));
    }
    _base = text.text;
    _typed = '';
    _enter = false;
  }

  void _flush() {
    _flushTyping();
    _flushKeys();
  }

  /// Marks where what the event being handled adds begins.
  void _begin() {
    if (_inEvent) return;
    _inEvent = true;
    _markSteps = recording.steps.length;
    _markMisses = recording.misses.length;
    scheduleMicrotask(() => _inEvent = false);
  }

  void _hush() {
    if (_quiet) return;
    _quiet = true;
    scheduleMicrotask(() => _quiet = false);
  }

  // ── Played steps ──────────────────────────────────────────────────────────

  /// [step] with the cursor it played with written in, as a recording mixes
  /// cursors from several scripts.
  static KeyStep _withCursor(KeyStep step, String cursor) {
    final id = step.cursor ?? cursor;
    return switch (step) {
      KeyPointStep(:final at) => KeyPointStep(at, cursor: id),
      KeyTapStep(:final at) => KeyTapStep(at, cursor: id),
      KeyHoldStep(:final at, :final duration) => KeyHoldStep(
        at,
        duration: duration,
        cursor: id,
      ),
      KeyDragStep(:final at, :final to, :final by, :final hold) => KeyDragStep(
        at,
        to: to,
        by: by,
        hold: hold,
        cursor: id,
      ),
      KeyScrollToStep(:final at, :final within) => KeyScrollToStep(
        at,
        within: within,
        cursor: id,
      ),
      KeyTypeStep(:final text, :final at, :final submit) => KeyTypeStep(
        text,
        at: at,
        submit: submit,
        cursor: id,
      ),
      KeyRunStep(:final command, :final args) => KeyRunStep(
        command,
        args: args,
        cursor: id,
      ),
      KeyTogetherStep(:final steps) => KeyTogetherStep([
        for (final inner in steps) _withCursor(inner, cursor),
      ]),
      KeyPressStep() ||
      KeyCaptionStep() ||
      KeyWaitStep() ||
      KeyWaitForStep() => step,
    };
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What a press landed on.
final class _Aim {
  /// The anchor, or null when it landed inside none.
  final KeySpot? spot;

  /// The place naming [spot].
  final String place;

  /// What it hit, for a press inside no anchor.
  final String hit;

  /// The place of the list to scroll before pressing, when the list moved
  /// since the last step.
  final String? list;

  /// Whether the list around [spot] moved but no anchor holds it.
  final bool scrolledUnnamed;

  /// The scrollable around [spot], if any.
  final ScrollableState? scrollable;

  const _Aim({
    required KeySpot this.spot,
    required this.place,
    required this.list,
    required this.scrolledUnnamed,
    required this.scrollable,
  }) : hit = '';

  const _Aim.none(this.hit)
    : spot = null,
      place = '',
      list = null,
      scrolledUnnamed = false,
      scrollable = null;
}

/// A press in progress.
///
/// Timed by its events' time stamps and by a timer both, taking the longer:
/// events made in code (a test's, an agent's) often carry no time stamps.
final class _Press {
  final _Aim aim;
  final Duration downAt;
  final Offset start;
  final PointerDeviceKind kind;
  final double slop;
  final _clock = Stopwatch();
  late final Timer _ticker;
  var _ticked = Duration.zero;

  /// How long it stayed put before it first moved further than a tap may.
  Duration? stillFor;

  _Press(PointerDownEvent down, this.aim)
    : downAt = down.timeStamp,
      start = down.position,
      kind = down.kind,
      slop = computeHitSlop(down.kind, null) {
    _clock.start();
    _ticker = Timer.periodic(_tick, (_) => _ticked += _tick);
  }

  static const _tick = Duration(milliseconds: 50);

  Duration _since(Duration stamp) {
    final byStamps = stamp - downAt;
    final byTimer = _ticked > _clock.elapsed ? _ticked : _clock.elapsed;
    return byStamps > byTimer ? byStamps : byTimer;
  }

  void moveTo(PointerMoveEvent event) {
    if (stillFor == null && (event.position - start).distance > slop) {
      stillFor = _since(event.timeStamp);
    }
  }

  /// How long it was held down, at [up].
  Duration heldFor(Duration up) => _since(up);

  void dispose() {
    _ticker.cancel();
    _clock.stop();
  }
}
