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

// Material leaves Flutter's core for package:material_ui, which needs Flutter
// 3.47; this keeps key_flow working on 3.32 and later until it moves.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// How key_flow's panels, focus rings and key caps look.
///
/// Taken from the app's [Theme] unless [KeyFlow.style] gives one.
@immutable
class KeyFlowStyle {
  /// The background of panels.
  final Color surface;

  /// Text on [surface].
  final Color onSurface;

  /// Secondary text: paths, hints, disabled commands.
  final Color muted;

  /// The chosen row and the focus ring.
  final Color accent;

  /// Text on [accent].
  final Color onAccent;

  /// The background of a key cap.
  final Color keyCap;

  /// Panel and key cap borders.
  final Color border;

  /// Drawn over the app behind the palette and the help sheet.
  final Color scrim;

  /// Corner radius of panels.
  final double radius;

  /// The base text style of panels.
  final TextStyle textStyle;

  /// The width of the focus ring around a [KeyTarget].
  final double focusRingWidth;

  const KeyFlowStyle({
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.keyCap,
    required this.border,
    required this.scrim,
    this.radius = 10,
    this.textStyle = const TextStyle(fontSize: 14),
    this.focusRingWidth = 2,
  });

  /// The style drawn from [theme]'s colours and body text.
  factory KeyFlowStyle.fromTheme(ThemeData theme) {
    final colors = theme.colorScheme;
    return KeyFlowStyle(
      surface: colors.surface,
      onSurface: colors.onSurface,
      muted: colors.onSurfaceVariant,
      accent: colors.primary,
      onAccent: colors.onPrimary,
      keyCap: colors.surfaceContainerHighest,
      border: colors.outlineVariant,
      scrim: Colors.black.withValues(alpha: 0.2),
      textStyle: (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
          .copyWith(color: colors.onSurface),
    );
  }

  /// The style for [context]: the nearest [KeyFlow]'s, else the theme's.
  static KeyFlowStyle of(BuildContext context) {
    return KeyFlow.styleOf(context) ??
        KeyFlowStyle.fromTheme(Theme.of(context));
  }

  /// A copy with the given values changed.
  KeyFlowStyle copyWith({
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? accent,
    Color? onAccent,
    Color? keyCap,
    Color? border,
    Color? scrim,
    double? radius,
    TextStyle? textStyle,
    double? focusRingWidth,
  }) {
    return KeyFlowStyle(
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      keyCap: keyCap ?? this.keyCap,
      border: border ?? this.border,
      scrim: scrim ?? this.scrim,
      radius: radius ?? this.radius,
      textStyle: textStyle ?? this.textStyle,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KeyFlowStyle &&
        other.surface == surface &&
        other.onSurface == onSurface &&
        other.muted == muted &&
        other.accent == accent &&
        other.onAccent == onAccent &&
        other.keyCap == keyCap &&
        other.border == border &&
        other.scrim == scrim &&
        other.radius == radius &&
        other.textStyle == textStyle &&
        other.focusRingWidth == focusRingWidth;
  }

  @override
  int get hashCode => Object.hash(
    surface,
    onSurface,
    muted,
    accent,
    onAccent,
    keyCap,
    border,
    scrim,
    radius,
    textStyle,
    focusRingWidth,
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Keys drawn as key caps: ⌘K as one cap, G P as two.
///
/// Screen readers and agents read the keys as text ("⌘K").
class KeyCaps extends StatelessWidget {
  /// The keys to draw.
  final KeyBinding binding;

  /// Draws the caps dimmed, for a command that cannot run now.
  final bool dimmed;

  const KeyCaps({super.key, required this.binding, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final style = KeyFlowStyle.of(context);
    final color = dimmed ? style.muted : style.onSurface;
    return Semantics(
      label: binding.describe(),
      excludeSemantics: true,
      child: Wrap(
        spacing: 4,
        children: [
          for (final step in binding.steps)
            DecoratedBox(
              decoration: BoxDecoration(
                color: style.keyCap,
                border: Border.all(color: style.border),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                  step.describe(),
                  style: style.textStyle.copyWith(
                    color: color,
                    fontSize: (style.textStyle.fontSize ?? 14) - 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
