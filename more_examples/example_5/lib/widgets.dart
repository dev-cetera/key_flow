// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// Overlays + the live key-capture dialog. These read app state from
// `actions.dart` but install no permanent KeyFlowControl of their own — the
// capture dialog deliberately bypasses key flow and listens to raw KeyEvents
// so it can record ANY combination including bindings already in use.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

import 'actions.dart';

// ─── KEY CAPTURE DIALOG ──────────────────────────────────────────────────────

/// Opens a modal that records the next sequence of key chords. The user can
/// press one chord (e.g. `⌘K`), or several in a row (`g` then `i`). Each
/// chord is committed on KeyDown; Esc finalises the sequence; Backspace
/// removes the last chord.
Future<void> showKeyCaptureDialog({
  required BuildContext context,
  required void Function(List<KeyActivator>) onCaptured,
}) async {
  final result = await showDialog<List<KeyActivator>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _KeyCaptureDialog(),
  );
  if (result != null && result.isNotEmpty) {
    onCaptured(result);
  }
}

class _KeyCaptureDialog extends StatefulWidget {
  const _KeyCaptureDialog();

  @override
  State<_KeyCaptureDialog> createState() => _KeyCaptureDialogState();
}

class _KeyCaptureDialogState extends State<_KeyCaptureDialog> {
  final List<KeyActivator> _seq = [];
  final FocusNode _node = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _node.requestFocus());
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    // Modifier-only presses don't record — they only count in combination.
    if (isModifierKey(key)) return KeyEventResult.handled;

    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop(_seq);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace && _seq.isNotEmpty) {
      setState(() => _seq.removeLast());
      return KeyEventResult.handled;
    }

    final kb = HardwareKeyboard.instance;
    setState(() {
      _seq.add(
        LogicalKeyActivator(
          key,
          meta: kb.isMetaPressed,
          control: kb.isControlPressed,
          shift: kb.isShiftPressed,
          alt: kb.isAltPressed,
        ),
      );
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        title: const Text('Press a key combination'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Press one chord, or several in a row for a sequence '
                '(e.g. g then i). Backspace removes the last chord. '
                'Press Esc when done.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _seq.isEmpty ? '(waiting…)' : _seq.debugName,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _seq.isEmpty
                ? null
                : () => Navigator.of(context).pop(_seq),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─── HELP OVERLAY ────────────────────────────────────────────────────────────

class HelpOverlay extends StatelessWidget {
  const HelpOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appState.helpVisible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        return Positioned.fill(
          child: GestureDetector(
            onTap: () => appState.helpVisible.value = false,
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(48),
                  padding: const EdgeInsets.all(20),
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Keyboard shortcuts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _OverlaySection(
                          title: 'App-wide',
                          control: appController,
                        ),
                        const SizedBox(height: 12),
                        _OverlaySection(
                          title: 'Inbox (only when focused)',
                          control: inboxController,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Press Esc or click outside to close.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverlaySection extends StatelessWidget {
  const _OverlaySection({required this.title, required this.control});
  final String title;
  final KeyFlowControl control;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        KeyFlowMappingsBuilder(
          control: control,
          builder: (context, c, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in c.mappings.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: KeyFlowKeyNameBuilder(
                            mappingKey: e.key,
                            builder: (context, name, _) => Text(name),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            e.value.debugName,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── COMMAND PALETTE ─────────────────────────────────────────────────────────

class CommandPaletteOverlay extends StatelessWidget {
  const CommandPaletteOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appState.paletteVisible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        return Positioned.fill(
          child: GestureDetector(
            onTap: () => appState.paletteVisible.value = false,
            child: ColoredBox(
              color: Colors.black54,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 80),
                  width: 500,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _PaletteList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PaletteList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Go: Home', () => appState.page.value = AppPage.home),
      ('Go: Inbox', () => appState.page.value = AppPage.inbox),
      ('Go: Settings', () => appState.page.value = AppPage.settings),
      ('Go: Bindings', () => appState.page.value = AppPage.bindings),
      for (final p in KeyProfile.values)
        ('Load profile: ${p.label}', () => applyProfile(p)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Command palette',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        for (final (label, action) in entries)
          ListTile(
            title: Text(label),
            onTap: () {
              appState.paletteVisible.value = false;
              action();
            },
          ),
      ],
    );
  }
}
