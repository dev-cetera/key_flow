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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A lightweight Flutter widget that triggers its [onTap] callback whenever
/// tapped, while preserving the interactivity of its [child] widget. Unlike
/// [GestureDetector], which may block child interactions, [AlwaysTappable]
/// ensures that both the parent tap event and any child-specific tap events
/// are handled independently.
class AlwaysTappable extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget? child;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const AlwaysTappable({
    super.key,
    this.onTap,
    this.child,
    this.padding = const EdgeInsets.all(8.0),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (_) => onTap?.call(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
