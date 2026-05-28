// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// key_flow — full-featured demo (example_5).
//
//   • Multiple focus levels (app shell + inbox).
//   • Live keybinding remap (Bindings page).
//   • Three swappable profiles (KeyFlow / Vim / Emacs).
//   • Sequence + chord activators, including a weird ⌘⌥⇧X combo.
//   • Text field bare-key suppression demo (Settings).
//   • Help overlay (`?`) and command palette (`⌘K` by default).
//   • Zero hardcoded mappings — every binding lives on a moddable controller.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

import 'actions.dart';
import 'pages.dart';
import 'widgets.dart';

void main() {
  wireControllers();
  runApp(const KeyFlowDemoApp());
}

class KeyFlowDemoApp extends StatelessWidget {
  const KeyFlowDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'key_flow demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const _Shell(),
    );
  }
}

// ─── SHELL ───────────────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    // ONE top-level KeyFlowFocus wraps the whole app. Its `appController`
    // is what every page inherits app-wide bindings from. Pages can add
    // their own nested KeyFlowFocus (the Inbox does) and those bindings
    // merge in via the ancestor walk inside KeyFlowControl.
    return Scaffold(
      body: KeyFlowFocus(
        autofocus: true,
        control: appController,
        child: Stack(
          children: [
            Column(
              children: [
                const _TopBar(),
                const Expanded(child: _PageHost()),
                const _Cheatsheet(),
              ],
            ),
            const HelpOverlay(),
            const CommandPaletteOverlay(),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.keyboard_alt_outlined),
            const SizedBox(width: 8),
            Text(
              'key_flow',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 24),
            for (final p in AppPage.values) _NavButton(page: p),
            const Spacer(),
            ValueListenableBuilder<KeyProfile>(
              valueListenable: appState.profile,
              builder: (context, p, _) => DropdownButton<KeyProfile>(
                value: p,
                onChanged: (v) {
                  if (v != null) applyProfile(v);
                },
                items: [
                  for (final p in KeyProfile.values)
                    DropdownMenuItem(value: p, child: Text(p.label)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.page});
  final AppPage page;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPage>(
      valueListenable: appState.page,
      builder: (context, current, _) {
        final selected = current == page;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: () => appState.page.value = page,
            style: TextButton.styleFrom(
              backgroundColor: selected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : null,
            ),
            child: Text(
              _labelFor(page),
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  static String _labelFor(AppPage p) => switch (p) {
        AppPage.home => 'Home',
        AppPage.inbox => 'Inbox',
        AppPage.settings => 'Settings',
        AppPage.bindings => 'Bindings',
      };
}

class _PageHost extends StatelessWidget {
  const _PageHost();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppPage>(
      valueListenable: appState.page,
      builder: (context, page, _) {
        return switch (page) {
          AppPage.home => const HomePage(),
          AppPage.inbox => const InboxPage(),
          AppPage.settings => const SettingsPage(),
          AppPage.bindings => const BindingsPage(),
        };
      },
    );
  }
}

// ─── CHEATSHEET ──────────────────────────────────────────────────────────────
//
// A compact strip along the bottom that renders the live binding for a few
// "always relevant" actions. Rebuilds automatically when the profile is
// swapped or a key is remapped, because it reads through the controller's
// mapping notifier.

class _Cheatsheet extends StatelessWidget {
  const _Cheatsheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: KeyFlowMappingsBuilder(
          control: appController,
          builder: (context, c, _) {
            final m = c.mappings;
            return Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _Chip(label: 'Help', combo: m[aShowHelp]?.debugName),
                _Chip(label: 'Palette', combo: m[aCommandPalette]?.debugName),
                _Chip(label: 'Inbox', combo: m[aGoInbox]?.debugName),
                _Chip(label: 'Bindings', combo: m[aGoBindings]?.debugName),
                _Chip(label: 'Profile', combo: m[aCycleProfile]?.debugName),
                _Chip(label: 'Search', combo: m[aFocusSearch]?.debugName),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.combo});
  final String label;
  final String? combo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label '),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            combo ?? '—',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }
}
