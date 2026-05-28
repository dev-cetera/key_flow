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

/// A widget builder that builds either with [hasFocusBuilder] or
/// [hasNoFocusBuilder] depending on whether the parent has focus or not.
class FocusBuilder extends StatelessWidget {
  //
  //
  //

  final Widget Function(BuildContext context, Widget? child) hasFocusBuilder;
  final Widget Function(BuildContext context, Widget? child) hasNoFocusBuilder;
  final Widget? child;

  //
  //
  //

  const FocusBuilder({
    super.key,
    required this.hasFocusBuilder,
    required this.hasNoFocusBuilder,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (Focus.of(context).hasFocus) {
          return hasFocusBuilder(context, child);
        } else {
          return hasNoFocusBuilder(context, child);
        }
      },
    );
  }
}
