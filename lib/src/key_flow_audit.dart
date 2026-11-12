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

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A control that a person without a mouse, a screen reader or an agent
/// cannot use: it can be tapped, but has no name or cannot take the focus.
@immutable
final class KeyFlowIssue {
  /// The semantics node's id.
  final int nodeId;

  /// Whatever the control is called, if anything: its label, value or
  /// tooltip.
  final String name;

  /// What is wrong, in words.
  final String problem;

  const KeyFlowIssue._(this.nodeId, this.name, this.problem);

  @override
  String toString() {
    final what = name.isEmpty ? 'a control' : '"$name"';
    return '$what (semantics node $nodeId) $problem';
  }
}

/// The controls under [root] that can be tapped but have no name, or that
/// the keyboard cannot reach.
///
/// In a widget test, with semantics on:
///
/// ```dart
/// final handle = tester.ensureSemantics();
/// final view = tester.binding.renderViews.first;
/// final root = view.owner!.semanticsOwner!.rootSemanticsNode!;
/// expect(findAccessibilityIssues(root), isEmpty);
/// handle.dispose();
/// ```
List<KeyFlowIssue> findAccessibilityIssues(SemanticsNode root) {
  final issues = <KeyFlowIssue>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    final flags = data.flagsCollection;
    if (!flags.isHidden &&
        !node.isInvisible &&
        data.hasAction(SemanticsAction.tap)) {
      final name = [
        data.label,
        data.value,
        data.tooltip,
      ].firstWhere((text) => text.trim().isNotEmpty, orElse: () => '');
      if (name.isEmpty) {
        issues.add(KeyFlowIssue._(node.id, name, 'has no name'));
      }
      if (flags.isFocused == ui.Tristate.none) {
        issues.add(
          KeyFlowIssue._(node.id, name, 'cannot be reached with the keyboard'),
        );
      }
    }
    node.visitChildren(visit);
    return true;
  }

  visit(root);
  return issues;
}
