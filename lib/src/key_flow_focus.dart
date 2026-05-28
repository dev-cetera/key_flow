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

/// A widget that manages a [FocusNode] and [KeyFlowControl].
class KeyFlowFocus extends StatefulWidget {
  //
  //
  //

  final KeyFlowControl? control;
  final FocusNode? focusNode;
  final bool autofocus;
  final Widget child;

  //
  //
  //

  const KeyFlowFocus({
    super.key,
    required this.control,
    this.focusNode,
    this.autofocus = false,
    required this.child,
  });

  //
  //
  //

  @override
  State<KeyFlowFocus> createState() => _KeyFlowFocusState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _KeyFlowFocusState extends State<KeyFlowFocus> {
  //
  //
  //

  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
  }

  //
  //
  //

  @override
  void didUpdateWidget(KeyFlowFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _ownsFocusNode = widget.focusNode == null;
    }
  }

  //
  //
  //

  @override
  void dispose() {
    // Clear the control's pointer if it still references the node we're
    // about to dispose, so callers like ControlMappingsBuilder don't read
    // a dead node.
    // ignore: invalid_use_of_protected_member
    if (identical(widget.control?.$focusNode, _focusNode)) {
      // ignore: invalid_use_of_protected_member
      widget.control?.$focusNode = null;
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    // ignore: invalid_use_of_protected_member
    widget.control?.$focusNode = _focusNode;
    // The outer `context` here lives *above* the KeyFlowScope we install
    // below; passing it into handleKeyEvent is what lets the control walk
    // up to its parent scope and merge in parent bindings. Do NOT switch
    // this to `innerContext` — that resolves the scope lookup to self and
    // silently breaks cross-scope shortcuts.
    return KeyFlowScope(
      control: widget.control,
      focusNode: _focusNode,
      child: Builder(
        builder: (innerContext) => Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          includeSemantics: true,
          onFocusChange: widget.control?.onFocusChange != null
              ? (hasFocus) =>
                  widget.control!.onFocusChange!(innerContext, hasFocus)
              : null,
          onKeyEvent: (node, keyEvent) =>
              KeyFlowScope.of(innerContext)
                  ?.control
                  ?.handleKeyEvent(context, node, keyEvent) ??
              KeyEventResult.ignored,
          child: widget.child,
        ),
      ),
    );
  }
}
