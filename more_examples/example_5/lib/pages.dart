// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// Pages for the demo. Each page reads from / writes to the global app state.
// Only the Inbox page installs its own KeyFlowFocus (with inboxController)
// to add page-scoped key mappings on top of the app-wide ones.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

import 'actions.dart';
import 'widgets.dart';

// ─── HOME ────────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.headlineMedium;
    final body = Theme.of(context).textTheme.bodyLarge;
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text('key_flow — full demo', style: headline),
        const SizedBox(height: 12),
        Text(
          'This entire app is navigable from the keyboard. The mouse is '
          'optional. Every binding below is moddable at runtime — the '
          'Bindings page lets you press a new combination to overwrite any '
          'mapping live, and the profile switcher swaps the whole set in '
          'one shot.',
          style: body,
        ),
        const SizedBox(height: 24),
        _Card(
          title: 'Start here',
          body: const [
            'Press "?" anytime for the help overlay.',
            'Press "g" then "i" to jump to the Inbox.',
            'Press "g" then "b" to jump to the Bindings page and remap things.',
            '⌘⇧P cycles through the three profiles (KeyFlow / Vim / Emacs).',
            '⌘K opens the command palette.',
            'Hidden weird combo: ⌘⌥⇧X.',
          ],
        ),
        const SizedBox(height: 16),
        _Card(
          title: 'How focus works',
          body: const [
            'The app installs ONE top-level KeyFlowFocus with `appController`.',
            'The Inbox page nests its OWN KeyFlowFocus with `inboxController` '
                'on top — sequences like "j" only fire while the inbox is focused.',
            'Sequences merge up the ancestor chain — "g i" works from anywhere.',
            'Text fields auto-suppress bare-key activators so typing "j" inside '
                'a TextField does NOT trigger the inbox down action.',
          ],
        ),
      ],
    );
  }
}

// ─── INBOX ───────────────────────────────────────────────────────────────────

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Layer the inbox controller on top of the app controller. KeyFlowFocus
    // walks the ancestor chain when handling events — so app-wide bindings
    // still work here, and inbox bindings only work *while focused here*.
    return KeyFlowFocus(
      autofocus: true,
      control: inboxController,
      child: FocusBuilder(
        hasFocusBuilder: (context, _) => _InboxBody(focused: true),
        hasNoFocusBuilder: (context, _) => _InboxBody(focused: false),
      ),
    );
  }
}

class _InboxBody extends StatelessWidget {
  const _InboxBody({required this.focused});
  final bool focused;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: focused ? Colors.green.shade100 : Colors.amber.shade100,
          padding: const EdgeInsets.all(12),
          child: Text(
            focused
                ? 'Inbox focused — j / k to move, Enter to open, e to archive.'
                : 'Inbox NOT focused. Click into it or press Tab.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: Listenable.merge(
              [appState.inboxIndex, appState.inboxItems],
            ),
            builder: (context, _) {
              final items = appState.inboxItems.value;
              final selected = appState.inboxIndex.value;
              if (items.isEmpty) {
                return const Center(
                  child: Text('Empty — load a profile from Settings to reset.'),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final isSelected = i == selected;
                  return Container(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.arrow_right : Icons.mail_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(items[i])),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── SETTINGS ────────────────────────────────────────────────────────────────

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final body = TextEditingController();

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        Text(
          'Text-field demo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'When focus is inside one of these fields, bare-key activators '
          '(j, k, e, ?, slash on its own…) are auto-suppressed so you can '
          'type freely. Modifier-bearing chords (⌘K, ⌘⇧P, etc.) still fire. '
          'Press "/" to jump focus straight into the first field — without '
          'the slash being inserted.',
        ),
        const SizedBox(height: 24),
        TextField(
          focusNode: appState.searchFocus,
          decoration: const InputDecoration(
            labelText: 'Search (press "/" to focus me)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: body,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Notes — try typing "jjkk e gg" here, nothing fires',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reset',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            for (final p in KeyProfile.values)
              FilledButton.tonal(
                onPressed: () => applyProfile(p),
                child: Text('Load ${p.label}'),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── BINDINGS (live remap) ───────────────────────────────────────────────────

class BindingsPage extends StatelessWidget {
  const BindingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Live bindings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Click "Capture" then press any combination (modifiers + key, or a '
          'multi-step sequence — keep pressing keys, hit Esc to commit). '
          'The mapping replaces the current one immediately.',
        ),
        const SizedBox(height: 16),
        _Section(label: 'App-wide', control: appController),
        const SizedBox(height: 24),
        _Section(label: 'Inbox (only fires when inbox is focused)', control: inboxController),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.control});
  final String label;
  final KeyFlowControl control;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        KeyFlowMappingsBuilder(
          control: control,
          builder: (context, c, _) {
            final entries = c.mappings.entries.toList();
            return Card(
              child: Column(
                children: [
                  for (final e in entries)
                    _BindingRow(
                      control: control,
                      actionKey: e.key,
                      activators: e.value,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BindingRow extends StatelessWidget {
  const _BindingRow({
    required this.control,
    required this.actionKey,
    required this.activators,
  });
  final KeyFlowControl control;
  final Key actionKey;
  final List<KeyActivator> activators;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: KeyFlowKeyNameBuilder(
              mappingKey: actionKey,
              builder: (context, name, _) => Text(name),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              activators.debugName,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => showKeyCaptureDialog(
              context: context,
              onCaptured: (seq) => control.remap(actionKey, seq),
            ),
            child: const Text('Capture…'),
          ),
        ],
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.body});
  final String title;
  final List<String> body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final line in body)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line'),
              ),
          ],
        ),
      ),
    );
  }
}
