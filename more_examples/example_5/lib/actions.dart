// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
// Action keys, callbacks, profiles, and app state for the demo.
//
// Everything moddable. Nothing hardcoded inline at a KeyFlowFocus.
// Profiles swap *only* the mappings — callbacks are wired once.
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

// ─── ACTION KEYS ─────────────────────────────────────────────────────────────
//
// `UniqueActionKey` is a `UniqueKey` that carries a human-readable debug name
// — used by the help overlay and the bindings page to render rows.

// App-wide
final aShowHelp = UniqueActionKey((c) => 'Show / hide help');
final aCloseOverlay = UniqueActionKey((c) => 'Close overlay or dialog');
final aGoHome = UniqueActionKey((c) => 'Go to Home');
final aGoInbox = UniqueActionKey((c) => 'Go to Inbox');
final aGoSettings = UniqueActionKey((c) => 'Go to Settings');
final aGoBindings = UniqueActionKey((c) => 'Go to Bindings');
final aCommandPalette = UniqueActionKey((c) => 'Command palette');
final aCycleProfile = UniqueActionKey((c) => 'Cycle key profile');
final aFocusSearch = UniqueActionKey((c) => 'Focus search field');
final aEasterEgg = UniqueActionKey((c) => 'Easter egg (weird combo)');

// Inbox-specific
final aMoveDown = UniqueActionKey((c) => 'Selection: down');
final aMoveUp = UniqueActionKey((c) => 'Selection: up');
final aJumpTop = UniqueActionKey((c) => 'Selection: top');
final aJumpBottom = UniqueActionKey((c) => 'Selection: bottom');
final aOpenItem = UniqueActionKey((c) => 'Open selected item');
final aArchiveItem = UniqueActionKey((c) => 'Archive selected item');
final aBulkArchive = UniqueActionKey((c) => 'Archive all (chord)');

// ─── APP STATE ───────────────────────────────────────────────────────────────

enum AppPage { home, inbox, settings, bindings }

enum KeyProfile { keyflow, vim, emacs }

extension KeyProfileLabelX on KeyProfile {
  String get label => switch (this) {
        KeyProfile.keyflow => 'KeyFlow (default)',
        KeyProfile.vim => 'Vim-ish',
        KeyProfile.emacs => 'Emacs-ish',
      };
}

class AppState {
  final ValueNotifier<AppPage> page = ValueNotifier(AppPage.home);
  final ValueNotifier<bool> helpVisible = ValueNotifier(false);
  final ValueNotifier<bool> paletteVisible = ValueNotifier(false);
  final ValueNotifier<KeyProfile> profile = ValueNotifier(KeyProfile.keyflow);

  // Inbox selection
  final ValueNotifier<int> inboxIndex = ValueNotifier(0);
  final ValueNotifier<List<String>> inboxItems = ValueNotifier(
    List<String>.generate(
      20,
      (i) => 'Item ${i + 1}  — try j / k, gg, G, e, ⌘⇧E',
    ),
  );

  // Settings search-field focus node (focused by aFocusSearch).
  final searchFocus = FocusNode();
}

final appState = AppState();

// ─── CONTROLLERS ─────────────────────────────────────────────────────────────
//
// `appController` is always active (top-level scope). `inboxController` is
// merged in when the inbox page mounts its own KeyFlowFocus.

final appController = KeyFlowControl();
final inboxController = KeyFlowControl();

/// All controllers a user can remap from the Bindings page.
final moddableControllers = <KeyFlowControl>[appController, inboxController];

// ─── CALLBACKS ───────────────────────────────────────────────────────────────

TCallbackMap _appCallbacks() => {
      aShowHelp: (c, r) => appState.helpVisible.value = !appState.helpVisible.value,
      aCloseOverlay: (c, r) {
        if (appState.paletteVisible.value) {
          appState.paletteVisible.value = false;
        } else if (appState.helpVisible.value) {
          appState.helpVisible.value = false;
        }
      },
      aGoHome: (c, r) => appState.page.value = AppPage.home,
      aGoInbox: (c, r) => appState.page.value = AppPage.inbox,
      aGoSettings: (c, r) => appState.page.value = AppPage.settings,
      aGoBindings: (c, r) => appState.page.value = AppPage.bindings,
      aCommandPalette: (c, r) => appState.paletteVisible.value = true,
      aCycleProfile: (c, r) {
        final next = KeyProfile
            .values[(appState.profile.value.index + 1) % KeyProfile.values.length];
        applyProfile(next);
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text('Switched to ${next.label}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      aFocusSearch: (c, r) {
        appState.page.value = AppPage.settings;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => appState.searchFocus.requestFocus(),
        );
      },
      aEasterEgg: (c, r) => ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(
              content: Text('🎉 You found the weird combo!'),
              duration: Duration(seconds: 2),
            ),
          ),
    };

TCallbackMap _inboxCallbacks() => {
      aMoveDown: (c, r) {
        final n = appState.inboxItems.value.length;
        if (n == 0) return;
        appState.inboxIndex.value = (appState.inboxIndex.value + 1) % n;
      },
      aMoveUp: (c, r) {
        final n = appState.inboxItems.value.length;
        if (n == 0) return;
        appState.inboxIndex.value =
            (appState.inboxIndex.value - 1 + n) % n;
      },
      aJumpTop: (c, r) => appState.inboxIndex.value = 0,
      aJumpBottom: (c, r) {
        final n = appState.inboxItems.value.length;
        if (n == 0) return;
        appState.inboxIndex.value = n - 1;
      },
      aOpenItem: (c, r) {
        final items = appState.inboxItems.value;
        if (items.isEmpty) return;
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text(
              'Opened: ${items[appState.inboxIndex.value]}',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      aArchiveItem: (c, r) {
        final items = [...appState.inboxItems.value];
        if (items.isEmpty) return;
        final idx = appState.inboxIndex.value;
        final removed = items.removeAt(idx);
        appState.inboxItems.value = items;
        if (idx >= items.length) {
          appState.inboxIndex.value =
              items.isEmpty ? 0 : items.length - 1;
        }
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text('Archived: $removed'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      aBulkArchive: (c, r) {
        final n = appState.inboxItems.value.length;
        appState.inboxItems.value = const [];
        appState.inboxIndex.value = 0;
        ScaffoldMessenger.of(c).showSnackBar(
          SnackBar(
            content: Text('Archived all $n items'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    };

// ─── PROFILES ────────────────────────────────────────────────────────────────
//
// Each profile builds full mappings dictionaries for both controllers.
// `applyProfile` swaps the mappings live without touching callbacks.

class _Bindings {
  final TMappingsMap app;
  final TMappingsMap inbox;
  const _Bindings({required this.app, required this.inbox});
}

_Bindings _keyflowBindings() => _Bindings(
      app: {
        aShowHelp: const [
          LogicalKeyActivator(LogicalKeyboardKey.slash, shift: true), // "?"
        ],
        aCloseOverlay: const [
          LogicalKeyActivator(LogicalKeyboardKey.escape),
        ],
        aGoHome: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
          LogicalKeyActivator(LogicalKeyboardKey.keyH),
        ],
        aGoInbox: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
          LogicalKeyActivator(LogicalKeyboardKey.keyI),
        ],
        aGoSettings: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
          LogicalKeyActivator(LogicalKeyboardKey.keyS),
        ],
        aGoBindings: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
          LogicalKeyActivator(LogicalKeyboardKey.keyB),
        ],
        aCommandPalette: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyK, meta: true),
        ],
        aCycleProfile: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyP, meta: true, shift: true),
        ],
        aFocusSearch: const [
          LogicalKeyActivator(LogicalKeyboardKey.slash),
        ],
        aEasterEgg: const [
          LogicalKeyActivator(
            LogicalKeyboardKey.keyX,
            meta: true,
            shift: true,
            alt: true,
          ),
        ],
      },
      inbox: {
        aMoveDown: const [LogicalKeyActivator(LogicalKeyboardKey.keyJ)],
        aMoveUp: const [LogicalKeyActivator(LogicalKeyboardKey.keyK)],
        aJumpTop: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
        ],
        aJumpBottom: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG, shift: true),
        ],
        aOpenItem: const [LogicalKeyActivator(LogicalKeyboardKey.enter)],
        aArchiveItem: const [LogicalKeyActivator(LogicalKeyboardKey.keyE)],
        aBulkArchive: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyE, meta: true, shift: true),
        ],
      },
    );

_Bindings _vimBindings() => _Bindings(
      app: {
        aShowHelp: const [
          LogicalKeyActivator(LogicalKeyboardKey.slash, shift: true),
        ],
        aCloseOverlay: const [
          LogicalKeyActivator(LogicalKeyboardKey.escape),
        ],
        aGoHome: const [
          LogicalKeyActivator(LogicalKeyboardKey.semicolon, shift: true), // ":"
          LogicalKeyActivator(LogicalKeyboardKey.keyH),
        ],
        aGoInbox: const [
          LogicalKeyActivator(LogicalKeyboardKey.semicolon, shift: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyI),
        ],
        aGoSettings: const [
          LogicalKeyActivator(LogicalKeyboardKey.semicolon, shift: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyS),
        ],
        aGoBindings: const [
          LogicalKeyActivator(LogicalKeyboardKey.semicolon, shift: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyB),
        ],
        aCommandPalette: const [
          LogicalKeyActivator(LogicalKeyboardKey.slash),
        ],
        aCycleProfile: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyZ, shift: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyZ, shift: true),
        ],
        aFocusSearch: const [
          LogicalKeyActivator(LogicalKeyboardKey.slash, shift: true),
        ],
        aEasterEgg: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
        ],
      },
      inbox: {
        // Position-based (PhysicalKeyActivator) so it stays on the home row
        // regardless of keyboard layout.
        aMoveDown: const [PhysicalKeyActivator(PhysicalKeyboardKey.keyJ)],
        aMoveUp: const [PhysicalKeyActivator(PhysicalKeyboardKey.keyK)],
        aJumpTop: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
          LogicalKeyActivator(LogicalKeyboardKey.keyG),
        ],
        aJumpBottom: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG, shift: true),
        ],
        aOpenItem: const [LogicalKeyActivator(LogicalKeyboardKey.enter)],
        aArchiveItem: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyD),
          LogicalKeyActivator(LogicalKeyboardKey.keyD),
        ],
        aBulkArchive: const [
          LogicalKeyActivator(LogicalKeyboardKey.semicolon, shift: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyQ),
          LogicalKeyActivator(LogicalKeyboardKey.enter),
        ],
      },
    );

_Bindings _emacsBindings() => _Bindings(
      app: {
        aShowHelp: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyH, control: true),
        ],
        aCloseOverlay: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyG, control: true),
        ],
        aGoHome: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyH),
        ],
        aGoInbox: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyI),
        ],
        aGoSettings: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyS),
        ],
        aGoBindings: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyB),
        ],
        aCommandPalette: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, alt: true),
        ],
        aCycleProfile: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyC, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyP, control: true),
        ],
        aFocusSearch: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyS, control: true),
        ],
        aEasterEgg: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyC, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyX, alt: true),
        ],
      },
      inbox: {
        aMoveDown: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyN, control: true),
        ],
        aMoveUp: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyP, control: true),
        ],
        aJumpTop: const [
          LogicalKeyActivator(LogicalKeyboardKey.comma, alt: true, shift: true),
        ],
        aJumpBottom: const [
          LogicalKeyActivator(LogicalKeyboardKey.period, alt: true, shift: true),
        ],
        aOpenItem: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyM, control: true),
        ],
        aArchiveItem: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyK, control: true),
        ],
        aBulkArchive: const [
          LogicalKeyActivator(LogicalKeyboardKey.keyX, control: true),
          LogicalKeyActivator(LogicalKeyboardKey.keyK, control: true),
        ],
      },
    );

_Bindings _bindingsFor(KeyProfile profile) => switch (profile) {
      KeyProfile.keyflow => _keyflowBindings(),
      KeyProfile.vim => _vimBindings(),
      KeyProfile.emacs => _emacsBindings(),
    };

// ─── WIRING ──────────────────────────────────────────────────────────────────

bool _wired = false;

/// Wire callbacks once and apply the initial profile.
void wireControllers() {
  if (_wired) return;
  _wired = true;
  // Callbacks never change — only mappings do when profile switches.
  appController.callbacks = _appCallbacks();
  inboxController.callbacks = _inboxCallbacks();
  applyProfile(appState.profile.value);
}

/// Replace all mappings on both controllers for the given [profile].
void applyProfile(KeyProfile profile) {
  final b = _bindingsFor(profile);
  appController.mappingsNotifier.set(b.app);
  inboxController.mappingsNotifier.set(b.inbox);
  appState.profile.value = profile;
}
