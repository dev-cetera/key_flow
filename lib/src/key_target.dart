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

/// Makes [child], however it is drawn, a control for a command: a person can
/// Tab to it and press it with Enter or Space, click it, see its keys on
/// hover, and a screen reader or agent reads it by the command's name.
///
/// [command] is the command's full id, looked up among the commands in force
/// here, so the control greys out when the command cannot run and shows on
/// or off for a switch:
///
/// ```dart
/// KeyTarget(command: 'run', child: MyRunButtonLook())
/// ```
///
/// For a control that is already a button, such as an `IconButton`, use
/// [KeyHint] instead.
class KeyTarget extends StatefulWidget {
  /// The full id of the command this control runs.
  final String command;

  /// How the control looks. Its own semantics are replaced by the command's.
  final Widget child;

  /// The focus node to use; one is made when null.
  final FocusNode? focusNode;

  /// Whether to take the focus when first shown.
  final bool autofocus;

  /// Whether hovering shows the command's name and keys.
  final bool showTooltip;

  /// The corner radius of the default focus ring.
  final double borderRadius;

  /// Draws the control when focused by keyboard instead of the default ring.
  final Widget Function(BuildContext context, Widget child, bool focused)?
  focusRingBuilder;

  const KeyTarget({
    super.key,
    required this.command,
    required this.child,
    this.focusNode,
    this.autofocus = false,
    this.showTooltip = true,
    this.borderRadius = 6,
    this.focusRingBuilder,
  });

  @override
  State<KeyTarget> createState() => _KeyTargetState();
}

class _KeyTargetState extends State<KeyTarget> {
  var _focused = false;

  @override
  Widget build(BuildContext context) {
    final controller = KeyFlow.maybeOf(context);
    final command = resolveCommand(context, widget.command);
    if (controller == null || command == null) return widget.child;
    final enabled = command.enabled;
    void run() => controller.runEntry(command);

    final style = KeyFlowStyle.of(context);
    final looks =
        widget.focusRingBuilder?.call(context, widget.child, _focused) ??
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: _focused
                ? Border.all(color: style.accent, width: style.focusRingWidth)
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        );

    Widget result = FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: enabled,
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            run();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: enabled ? run : null,
        child: ExcludeSemantics(child: looks),
      ),
    );
    result = Semantics(
      container: true,
      button: command.checked == null,
      toggled: command.checked,
      enabled: enabled,
      identifier: command.id,
      label: command.label,
      hint: commandHint(command),
      value: semanticsValueOf(controller, command),
      onTap: enabled ? run : null,
      child: result,
    );
    if (widget.showTooltip && Overlay.maybeOf(context) != null) {
      result = Tooltip(
        message: tooltipOf(command),
        excludeFromSemantics: true,
        child: result,
      );
    }
    return result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Gives a control that is already a button, such as an `IconButton`, a
/// command's name for screen readers and agents, its keys, and a tooltip with
/// both. The child's own semantics merge into one node with them, so leave
/// the child without a tooltip or label of its own.
///
/// Pair it with [KeyFlowController.callbackFor] so the button runs the
/// command and greys out with it:
///
/// ```dart
/// KeyHint(
///   command: 'run',
///   child: IconButton(
///     icon: const Icon(Icons.play_arrow),
///     onPressed: KeyFlow.of(context).callbackFor(context, 'run'),
///   ),
/// )
/// ```
class KeyHint extends StatelessWidget {
  /// The full id of the command.
  final String command;

  /// The control.
  final Widget child;

  /// Whether hovering shows the command's name and keys.
  final bool showTooltip;

  const KeyHint({
    super.key,
    required this.command,
    required this.child,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = KeyFlow.maybeOf(context);
    final entry = resolveCommand(context, command);
    if (controller == null || entry == null) return child;
    Widget result = MergeSemantics(
      child: Semantics(
        identifier: entry.id,
        label: entry.label,
        hint: commandHint(entry),
        value: semanticsValueOf(controller, entry),
        child: child,
      ),
    );
    if (showTooltip && Overlay.maybeOf(context) != null) {
      result = Tooltip(
        message: tooltipOf(entry),
        excludeFromSemantics: true,
        child: result,
      );
    }
    return result;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The command with full id [id] among those in force at [context], or null
/// (with a note in debug builds) when there is none. Rebuilds [context] when
/// the commands of any scope above it change.
KeyCommandEntry? resolveCommand(BuildContext context, String id) {
  final controller = KeyFlow.maybeOf(context);
  if (controller == null) return null;
  context.visitAncestorElements((element) {
    if (element is InheritedElement && element.widget is KeyLayerScope) {
      context.dependOnInheritedElement(element);
    }
    return true;
  });
  final entry = controller.treeAt(context).find(id);
  if (entry is KeyCommandEntry) return entry;
  assert(() {
    debugPrint('key_flow: no command "$id" where ${context.widget} is');
    return true;
  }());
  return null;
}

/// What a linked control tells screen readers after its name: what the
/// command does and its keys.
String? commandHint(KeyCommandEntry command) {
  final keys = command.fullBindings.map((binding) => binding.describe());
  final parts = [
    if (command.description != null) command.description!,
    if (keys.isNotEmpty) 'Shortcut ${keys.join(' or ')}',
  ];
  return parts.isEmpty ? null : parts.join('. ');
}

/// The accessibility value of a linked control: its first shortcut, where
/// [KeyFlowController.shortcutsInSemanticsValue] says so, and never for a
/// switch, whose value is on or off.
String? semanticsValueOf(
  KeyFlowController controller,
  KeyCommandEntry command,
) {
  if (!controller.shortcutsInSemanticsValue || command.checked != null) {
    return null;
  }
  return command.fullBindings.firstOrNull?.describe();
}

/// A linked control's tooltip: its name, then its keys.
String tooltipOf(KeyCommandEntry command) {
  final keys = command.fullBindings.firstOrNull?.describe();
  return keys == null ? command.label : '${command.label}   $keys';
}
