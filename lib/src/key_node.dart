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

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The places a command or group is shown or offered.
enum KeySurface {
  /// The menu bar: the native one on macOS, else one drawn in the window.
  menuBar,

  /// The command palette, which searches every command by name.
  palette,

  /// The sheet that lists every shortcut.
  helpSheet,

  /// The panel that lists what to press next once a group's key is pressed.
  prefixPanel,

  /// What an AI agent is told it can run, through [KeyTree.toCommandList] and
  /// [KeyTree.toToolList].
  agents,
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// One item in a tree of commands: a [KeyCommand], a [KeyGroup] holding
/// more items, or a [KeyDivider] between them.
///
/// A [KeyFlow] at the top of the app and each [KeyFlowScope] inside it give
/// a list of these. Where the person is decides which apply: the scopes
/// around the focused widget, merged from the outside in, so an inner scope
/// adds to and overrides the outer ones.
sealed class KeyNode {
  const KeyNode();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Something a person can do: run from its keys, from a menu, from the
/// command palette, from a control linked to it by [KeyTarget], or by an
/// agent through [KeyFlowController.run].
final class KeyCommand extends KeyNode {
  /// Names this command among its siblings. Letters, digits, `-` and `_`;
  /// never translated, so agents, saved key choices and [KeyTarget] can refer
  /// to it. Its full id joins the ids of the groups it is in with dots:
  /// `go.inbox`.
  final String id;

  /// What it is called, shown to people and agents alike: in menus, the
  /// palette, the help sheet and to screen readers.
  final String label;

  /// More about what it does, for the palette, tooltips and agents.
  final String? description;

  /// The keys that run it, each written as text: `['meta+r']`, or
  /// `['g i', 'meta+1']` for two ways in. Inside a group that has keys of its
  /// own, these come after the group's: `S` in a group on `G` is `G S`.
  final List<String> keys;

  /// What it does. Given the context of the scope that declared it.
  ///
  /// A command with [params] uses [onRunWithArgs] instead.
  final FutureOr<void> Function(BuildContext context)? onRun;

  /// The values it takes when code or an agent runs it; see [KeyParam].
  /// [KeyTree.toToolList] gives them to models as the tool's parameters.
  final List<KeyParam> params;

  /// What it does, for a command with [params]: given the context of the
  /// scope that declared it and the values it was run with, checked against
  /// [params]. Give this or [onRun], not both.
  final FutureOr<void> Function(BuildContext context, KeyArgs args)?
  onRunWithArgs;

  /// Whether it can run now. A disabled command still shows, greyed out.
  final bool enabled;

  /// For a command that switches something on or off, whether it is on now;
  /// null for a command that is not a switch.
  final bool? checked;

  /// Places this command is left out of.
  final Set<KeySurface> hiddenFrom;

  const KeyCommand({
    required this.id,
    required this.label,
    this.description,
    this.keys = const [],
    this.onRun,
    this.params = const [],
    this.onRunWithArgs,
    this.enabled = true,
    this.checked,
    this.hiddenFrom = const {},
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A named folder of commands, as deep as needed.
///
/// With [keys], a group is a step on the way: pressing them opens the group,
/// a panel lists what to press next, and its children's keys follow. Without
/// keys, a group only gathers commands under a name, for a menu, the palette
/// and the help sheet, and its children's keys work as if they were outside
/// it.
///
/// Groups with the same id in an outer and an inner scope are one group: the
/// inner scope adds children to it, and replaces those with the same id. A
/// screen can so add "Projects" to the app's "Go to" group by declaring a
/// group with the same id and only its own children.
final class KeyGroup extends KeyNode {
  /// Names this group among its siblings; see [KeyCommand.id].
  final String id;

  /// What the group is called. May be left out by a scope that only adds
  /// children to a group another scope names.
  final String? label;

  /// More about what is in it.
  final String? description;

  /// The keys that open it, each written as text; see [KeyCommand.keys].
  final List<String> keys;

  /// What is in it.
  final List<KeyNode> children;

  /// Whether the group is a menu in the menu bar, such as File or View. Only
  /// groups at the top of the tree become menus.
  final bool inMenuBar;

  /// Places this group, and everything in it, is left out of.
  final Set<KeySurface> hiddenFrom;

  const KeyGroup({
    required this.id,
    this.label,
    this.description,
    this.keys = const [],
    this.children = const [],
    this.inMenuBar = false,
    this.hiddenFrom = const {},
  });
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A line between items in a menu, a panel or the help sheet.
final class KeyDivider extends KeyNode {
  const KeyDivider();
}
