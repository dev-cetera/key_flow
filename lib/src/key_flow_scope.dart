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

/// An [InheritedWidget] that provides access to [KeyFlowControl] up the
/// widget tree.
///
/// Used internally by [KeyFlowFocus], [KeyFlowScopeBuilder] and
/// [KeyFlowMappingsBuilder].
class KeyFlowScope extends InheritedWidget {
  //
  //
  //

  final KeyFlowControl? control;
  final FocusNode? focusNode;

  //
  //
  //

  const KeyFlowScope({
    super.key,
    required this.control,
    required this.focusNode,
    required super.child,
  });

  //
  //
  //

  @override
  bool updateShouldNotify(KeyFlowScope oldWidget) {
    return control != oldWidget.control;
  }

  //
  //
  //

  static KeyFlowScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<KeyFlowScope>();
  }
}
