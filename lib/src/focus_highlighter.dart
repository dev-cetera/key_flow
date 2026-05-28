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

import 'package:flutter/material.dart';

import '/key_flow.dart';
import '_always_tappable.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A  widget that provides visual feedback based on focus state, highlighting
/// its container with customizable decorations when focused or unfocused.
class FocusHighlighter extends StatelessWidget {
  //
  //
  //

  final Widget? child;
  final BoxDecoration? hasFocusDecoration;
  final BoxDecoration? hasNoFocusDecoration;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  //
  //
  //

  const FocusHighlighter({
    super.key,
    this.child,
    this.hasFocusDecoration,
    this.hasNoFocusDecoration,
    this.margin = const EdgeInsets.all(8.0),
    this.padding = const EdgeInsets.all(4.0),
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final defaultHasFocusDecoration = hasFocusDecoration ??
        BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withAlpha(16),
        );

    final defaultHasNoFocusDecoration = hasNoFocusDecoration;
    return FocusBuilder(
      hasFocusBuilder: (context, child) {
        return Container(
          decoration: defaultHasFocusDecoration,
          padding: padding,
          margin: margin,
          child: child,
        );
      },
      hasNoFocusBuilder: (context, child) {
        return Container(
          decoration: defaultHasNoFocusDecoration,
          padding: padding,
          margin: margin,
          child: child,
        );
      },
      child: child != null
          ? Builder(
              builder: (context) {
                return AlwaysTappable(
                  onTap: () {
                    KeyFlowScope.of(context)?.focusNode?.requestFocus();
                  },
                  child: child!,
                );
              },
            )
          : null,
    );
  }
}
