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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Puts the menus of the commands in force (each top-level [KeyGroup] with
/// [KeyGroup.inMenuBar]) in the macOS menu bar, and keeps them up to date as
/// the focus moves. Elsewhere it draws them in a bar above [child] when
/// [drawOnOtherPlatforms] is true, else shows [child] as it is; an app with
/// its own bar can use [menuBarChildrenOf].
///
/// Native menus show each command's one-key shortcut, and screen readers and
/// agents read them like any Mac app's menus. Put it inside the [KeyFlow].
class KeyFlowMenuBar extends StatefulWidget {
  /// The app.
  final Widget child;

  /// Menus before the commands' own. On macOS the first menu is always the
  /// app's own (About, Hide, Quit); null gives the standard one
  /// ([standardAppMenu]).
  final List<PlatformMenuItem>? leading;

  /// Menus after the commands' own, such as Window and Help.
  final List<PlatformMenuItem> trailing;

  /// Whether to draw the menus in a bar above [child] where there is no
  /// native menu bar: Windows, Linux and the web.
  final bool drawOnOtherPlatforms;

  const KeyFlowMenuBar({
    super.key,
    required this.child,
    this.leading,
    this.trailing = const [],
    this.drawOnOtherPlatforms = false,
  });

  /// The app menu every Mac app has: About, Services, Hide, Hide Others,
  /// Show All and Quit, each provided by macOS.
  static List<PlatformMenuItem> standardAppMenu() {
    PlatformMenuItem? provided(PlatformProvidedMenuItemType type) {
      return PlatformProvidedMenuItem.hasMenu(type)
          ? PlatformProvidedMenuItem(type: type)
          : null;
    }

    final groups = [
      [provided(PlatformProvidedMenuItemType.about)],
      [provided(PlatformProvidedMenuItemType.servicesSubmenu)],
      [
        provided(PlatformProvidedMenuItemType.hide),
        provided(PlatformProvidedMenuItemType.hideOtherApplications),
        provided(PlatformProvidedMenuItemType.showAllApplications),
      ],
      [provided(PlatformProvidedMenuItemType.quit)],
    ];
    return [
      PlatformMenu(
        // macOS shows the app's name here whatever the label.
        label: '',
        menus: [
          for (final group in groups)
            if (group.nonNulls.isNotEmpty)
              PlatformMenuItemGroup(members: group.nonNulls.toList()),
        ],
      ),
    ];
  }

  @override
  State<KeyFlowMenuBar> createState() => _KeyFlowMenuBarState();
}

class _KeyFlowMenuBarState extends State<KeyFlowMenuBar> {
  KeyFlowController? _controller;
  String _shape = '';

  static bool get _native =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_maybeRebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = KeyFlow.maybeOf(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_maybeRebuild);
      _controller = controller?..addListener(_maybeRebuild);
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_maybeRebuild);
    _controller?.removeListener(_maybeRebuild);
    super.dispose();
  }

  /// Rebuilds only when what the menus show changed, so the platform is not
  /// sent the same menus on every focus move.
  void _maybeRebuild() {
    if (!mounted || !(_native || widget.drawOnOtherPlatforms)) return;
    final shape = _shapeOf(_controller?.currentTree);
    if (shape != _shape) setState(() {});
  }

  static String _shapeOf(KeyTree? tree) {
    if (tree == null) return '';
    final buffer = StringBuffer();
    void visit(KeyGroupEntry group) {
      for (final child in group.children) {
        switch (child) {
          case KeyGroupEntry():
            buffer.write('[${child.id}:${child.label}');
            visit(child);
            buffer.write(']');
          case KeyCommandEntry():
            buffer.write(
              '(${child.id}:${child.label}:${child.enabled}:'
              '${child.fullBindings.map((b) => b.toSpec()).join(',')})',
            );
          case KeyDividerEntry():
            buffer.write('|');
        }
      }
    }

    for (final child in tree.root.children) {
      if (child is KeyGroupEntry && child.inMenuBar) visit(child);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    if (!_native) {
      if (!widget.drawOnOtherPlatforms) return widget.child;
      final tree = controller.currentTree;
      _shape = _shapeOf(tree);
      final bar = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MenuBar(
            children: menuBarChildrenOf(tree, onSelected: controller.runEntry),
          ),
          Expanded(child: widget.child),
        ],
      );
      // The menus open in an overlay; give them one above the navigator.
      return Overlay.maybeOf(context) == null ? Overlay.wrap(child: bar) : bar;
    }
    final tree = controller.currentTree;
    _shape = _shapeOf(tree);
    return PlatformMenuBar(
      menus: [
        ...widget.leading ?? KeyFlowMenuBar.standardAppMenu(),
        ...platformMenusOf(tree, onSelected: controller.runEntry),
        ...widget.trailing,
      ],
      child: widget.child,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The menus of [tree] as native menu items: one [PlatformMenu] per
/// top-level group with [KeyGroup.inMenuBar], submenus for groups inside it,
/// and dividers as item groups. For an app that builds its own
/// [PlatformMenuBar].
List<PlatformMenuItem> platformMenusOf(
  KeyTree tree, {
  required ValueChanged<KeyCommandEntry> onSelected,
}) {
  return [
    for (final child in tree.root.children)
      if (child is KeyGroupEntry &&
          child.inMenuBar &&
          !child.isHiddenFrom(KeySurface.menuBar))
        PlatformMenu(
          label: child.label,
          menus: _platformItems(child, onSelected),
        ),
  ];
}

List<PlatformMenuItem> _platformItems(
  KeyGroupEntry group,
  ValueChanged<KeyCommandEntry> onSelected,
) {
  final sections = <List<PlatformMenuItem>>[[]];
  for (final child in group.children) {
    if (child is KeyItemEntry && child.isHiddenFrom(KeySurface.menuBar)) {
      continue;
    }
    switch (child) {
      case KeyDividerEntry():
        sections.add([]);
      case KeyCommandEntry():
        sections.last.add(
          PlatformMenuItem(
            label: _menuLabel(child),
            shortcut: menuShortcutOf(child),
            onSelected: child.enabled ? () => onSelected(child) : null,
          ),
        );
      case KeyGroupEntry():
        final items = _platformItems(child, onSelected);
        if (items.isNotEmpty) {
          sections.last.add(PlatformMenu(label: child.label, menus: items));
        }
    }
  }
  final filled = [
    for (final section in sections)
      if (section.isNotEmpty) section,
  ];
  if (filled.length <= 1) return filled.firstOrNull ?? const [];
  return [
    for (final section in filled) PlatformMenuItemGroup(members: section),
  ];
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// The menus of [tree] as widgets for Material's [MenuBar], for platforms
/// without a native menu bar (or an app that draws its own): one
/// [SubmenuButton] per top-level group with [KeyGroup.inMenuBar].
List<Widget> menuBarChildrenOf(
  KeyTree tree, {
  required ValueChanged<KeyCommandEntry> onSelected,
}) {
  return [
    for (final child in tree.root.children)
      if (child is KeyGroupEntry &&
          child.inMenuBar &&
          !child.isHiddenFrom(KeySurface.menuBar))
        SubmenuButton(
          menuChildren: _drawnItems(child, onSelected),
          child: Text(child.label),
        ),
  ];
}

List<Widget> _drawnItems(
  KeyGroupEntry group,
  ValueChanged<KeyCommandEntry> onSelected,
) {
  final items = <Widget>[];
  for (final child in group.children) {
    if (child is KeyItemEntry && child.isHiddenFrom(KeySurface.menuBar)) {
      continue;
    }
    switch (child) {
      case KeyDividerEntry():
        items.add(const Divider(height: 1));
      case KeyCommandEntry():
        final keys = child.fullBindings.firstOrNull;
        items.add(
          MenuItemButton(
            onPressed: child.enabled ? () => onSelected(child) : null,
            leadingIcon: child.checked == null
                ? null
                : Icon(child.checked! ? Icons.check : null, size: 16),
            trailingIcon: keys == null ? null : Text(keys.describe()),
            child: Text(child.label),
          ),
        );
      case KeyGroupEntry():
        items.add(
          SubmenuButton(
            menuChildren: _drawnItems(child, onSelected),
            child: Text(child.label),
          ),
        );
    }
  }
  return items;
}

/// The one-key shortcut a native menu can show for [command], if it has one.
/// Keys pressed one after another (G I) cannot show in a native menu.
MenuSerializableShortcut? menuShortcutOf(KeyCommandEntry command) {
  final apple = KeyActivator.isAppleHost;
  for (final binding in command.fullBindings) {
    if (binding.steps.length != 1) continue;
    final step = binding.steps.single;
    final meta = step.meta && apple;
    final control = step.control || (step.meta && !apple);
    final character = step.character;
    if (character != null) {
      return CharacterActivator(
        character,
        alt: step.alt,
        control: control,
        meta: meta,
      );
    }
    final logical = step.logical;
    if (logical != null) {
      return SingleActivator(
        logical,
        control: control,
        meta: meta,
        shift: step.shift,
        alt: step.alt,
      );
    }
  }
  return null;
}

String _menuLabel(KeyCommandEntry command) {
  // Native menu items have no tick of their own.
  return switch (command.checked) {
    true => '✓ ${command.label}',
    _ => command.label,
  };
}
