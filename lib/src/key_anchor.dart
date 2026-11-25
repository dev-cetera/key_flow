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

import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Names a place on screen so a script can point at it, tap it, hold it,
/// drag it or type into it: a list row, a text field, a card.
///
/// [KeyTarget] and [KeyHint] are anchors already, named by their command's
/// full id, so the controls of commands need nothing more.
///
/// When the same id shows more than once, such as a "tick" button on every
/// row, give each row an anchor of its own and name the one meant by both:
/// `row-42/tick`. See [KeyFlowController.findSpot].
class KeyAnchor extends StatefulWidget {
  /// Its name: letters, digits, `-`, `_` and `.`.
  final String id;

  /// What it is, for agents reading [KeyFlowController.spots].
  final String? label;

  /// The place.
  final Widget child;

  const KeyAnchor({
    super.key,
    required this.id,
    this.label,
    required this.child,
  });

  @override
  State<KeyAnchor> createState() => _KeyAnchorState();
}

class _KeyAnchorState extends State<KeyAnchor> {
  KeyAnchorRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = KeyFlow.maybeOf(context)?.anchors;
    if (!identical(registry, _registry)) {
      _registry?.remove(context as Element);
      _registry = registry;
      registry?.add(context as Element);
    }
  }

  @override
  void dispose() {
    _registry?.remove(context as Element);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An anchor showing on screen now.
@immutable
final class KeySpot {
  /// The anchor's id.
  final String id;

  /// The ids of the anchors around it, outermost first.
  final List<String> within;

  /// What it is, if its anchor says.
  final String? label;

  /// Where it is, in the logical pixels of its window.
  final Rect rect;

  /// Whether a tap at its centre reaches it, rather than something drawn
  /// over it.
  final bool reachable;

  /// The id of the window it is in.
  final int viewId;

  /// Where the anchor is in the widget tree.
  final BuildContext context;

  const KeySpot._({
    required this.id,
    required this.within,
    required this.label,
    required this.rect,
    required this.reachable,
    required this.viewId,
    required this.context,
  });

  /// The place that names it: its id after those of the anchors around it.
  String get place => [...within, id].join('/');

  /// It as plain data, for an agent: what it is and where.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'place': place,
      'label': ?label,
      'rect': [
        rect.left.roundToDouble(),
        rect.top.roundToDouble(),
        rect.width.roundToDouble(),
        rect.height.roundToDouble(),
      ],
      'reachable': reachable,
    };
  }

  @override
  String toString() => 'KeySpot($place at $rect)';
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Which anchor a script means: `save`, `row-42/tick`, or `tick[2]` for the
/// third "tick" on screen in reading order.
@immutable
final class KeyPlace {
  /// The anchor's id.
  final String id;

  /// Ids of anchors that must be around it, outermost first.
  final List<String> within;

  /// Which of several matches, counted in reading order from 0.
  final int? index;

  const KeyPlace(this.id, {this.within = const [], this.index});

  static final _indexed = RegExp(r'^(.+)\[(\d+)\]$');

  /// Reads a place written as text. Throws a [FormatException] for an empty
  /// part.
  factory KeyPlace.parse(String text) {
    final parts = text.split('/').map((part) => part.trim()).toList();
    if (parts.any((part) => part.isEmpty)) {
      throw FormatException('A place has an empty part', text);
    }
    final last = _indexed.firstMatch(parts.last);
    return KeyPlace(
      last == null ? parts.last : last.group(1)!,
      within: parts.sublist(0, parts.length - 1),
      index: last == null ? null : int.parse(last.group(2)!),
    );
  }

  /// Whether [spot] is one this place names, leaving [index] aside.
  bool matches(KeySpot spot) {
    if (spot.id != id) return false;
    var at = 0;
    for (final outer in spot.within) {
      if (at < within.length && within[at] == outer) at++;
    }
    return at == within.length;
  }

  @override
  String toString() {
    final last = index == null ? id : '$id[$index]';
    return [...within, last].join('/');
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The anchors under one [KeyFlow]. Read through
/// [KeyFlowController.spots] and [KeyFlowController.findSpot].
final class KeyAnchorRegistry {
  final _elements = <Element>{};

  /// Adds the element of a [KeyAnchor].
  @internal
  void add(Element element) => _elements.add(element);

  /// Removes the element of a [KeyAnchor].
  @internal
  void remove(Element element) => _elements.remove(element);

  /// Every anchor drawn on screen now, on the route on top, in reading
  /// order: top to bottom, then left to right.
  List<KeySpot> spots() {
    final found = <KeySpot>[];
    for (final element in _elements) {
      final spot = _spotOf(element);
      if (spot != null) found.add(spot);
    }
    found.sort((a, b) {
      final byTop = a.rect.top.compareTo(b.rect.top);
      return byTop != 0 ? byTop : a.rect.left.compareTo(b.rect.left);
    });
    return found;
  }

  /// The one anchor on screen that [place] names; see [KeyPlace].
  ///
  /// Throws a [StateError] when none does, or when several do and [place]
  /// does not say which.
  KeySpot find(String place) {
    final wanted = KeyPlace.parse(place);
    final all = spots();
    final matches = all.where(wanted.matches).toList();
    final index = wanted.index;
    if (matches.isEmpty) {
      final ids = {for (final spot in all) spot.place};
      throw StateError(
        'Nothing on screen is "$place". On screen: '
        '${ids.isEmpty ? 'no anchors' : ids.join(', ')}',
      );
    }
    if (index != null) {
      if (index >= matches.length) {
        throw StateError(
          '"$place": only ${matches.length} on screen, counted from 0',
        );
      }
      return matches[index];
    }
    if (matches.length > 1) {
      throw StateError(
        '"$place" names ${matches.length} things on screen: '
        '${matches.map((spot) => spot.place).join(', ')}. Name an anchor '
        'around the one meant ("row/$place") or count them ("$place[0]")',
      );
    }
    return matches.single;
  }

  KeySpot? _spotOf(Element element) {
    if (!element.mounted) return null;
    final widget = element.widget;
    if (widget is! KeyAnchor) return null;
    final box = element.renderObject;
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (!_isPainted(box)) return null;
    final route = ModalRoute.of(element);
    if (route != null && !route.isCurrent) return null;
    final view = _viewOf(box);
    if (view == null) return null;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    final within = <String>[];
    element.visitAncestorElements((ancestor) {
      final outer = ancestor.widget;
      if (outer is KeyAnchor) within.add(outer.id);
      return true;
    });
    return KeySpot._(
      id: widget.id,
      within: within.reversed.toList(),
      label: widget.label,
      rect: rect,
      reachable: _reaches(box, rect.center, view.flutterView.viewId),
      viewId: view.flutterView.viewId,
      context: element,
    );
  }

  /// Whether every render object above [box] paints the one below it: false
  /// inside an [Offstage] or a hidden child of an [IndexedStack].
  static bool _isPainted(RenderObject box) {
    var child = box;
    var parent = child.parent;
    while (parent != null) {
      if (!parent.paintsChild(child)) return false;
      child = parent;
      parent = child.parent;
    }
    return true;
  }

  static RenderView? _viewOf(RenderObject box) {
    RenderObject? node = box;
    while (node != null && node is! RenderView) {
      node = node.parent;
    }
    return node is RenderView ? node : null;
  }

  /// Whether a pointer at [position] reaches [box]: the first render object
  /// hit is [box], inside it, or around it (nothing inside [box] takes hits
  /// there). Anything else is drawn over it.
  static bool _reaches(RenderBox box, Offset position, int viewId) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, position, viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderObject) continue;
      return _isAtOrInside(target, box) || _isAtOrInside(box, target);
    }
    return false;
  }

  static bool _isAtOrInside(RenderObject node, RenderObject outer) {
    for (RenderObject? at = node; at != null; at = at.parent) {
      if (identical(at, outer)) return true;
    }
    return false;
  }
}
