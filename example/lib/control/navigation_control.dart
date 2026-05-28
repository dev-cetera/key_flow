import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GotoInboxAction extends UniqueActionKey {
  static final i = GotoInboxAction._();
  factory GotoInboxAction() => i;
  GotoInboxAction._() : super((context) => 'Goes to the /inbox from anywhere in the app.');
}

class GotoProfileAction extends UniqueActionKey {
  static final i = GotoProfileAction._();
  factory GotoProfileAction() => i;
  GotoProfileAction._() : super((context) => 'Goes to the /profile from anywhere in the app.');
}

class GotoSettingsAction extends UniqueActionKey {
  static final i = GotoSettingsAction._();
  factory GotoSettingsAction() => i;
  GotoSettingsAction._() : super((context) => 'Goes to the /settings from anywhere in the app.');
}

class GotoKeybindingsAction extends UniqueActionKey {
  static final i = GotoKeybindingsAction._();
  factory GotoKeybindingsAction() => i;
  GotoKeybindingsAction._()
    : super((context) => 'Goes to the /keybindings from anywhere in the app.');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class NavigationControl extends KeyFlowControl {
  static final i = NavigationControl._();
  factory NavigationControl() => i;
  NavigationControl._()
    : super(
        mappings: {
          ExitAppAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.escape),
          ],
          GotoInboxAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyI),
          ],
          GotoProfileAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyP),
          ],
          GotoSettingsAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyS),
          ],
          GotoKeybindingsAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyK),
          ],
        },
        callbacks: {
          GotoInboxAction(): (context, _) {
            try {
              Scaffold.of(context).closeDrawer();
            } catch (_) {}
            router.go('/inbox');
          },
          GotoProfileAction(): (context, _) {
            try {
              Scaffold.of(context).closeDrawer();
            } catch (_) {}
            router.go('/profile');
          },
          GotoSettingsAction(): (context, _) {
            try {
              Scaffold.of(context).closeDrawer();
            } catch (_) {}
            router.go('/settings');
          },
          GotoKeybindingsAction(): (context, _) {
            try {
              Scaffold.of(context).closeDrawer();
            } catch (_) {}
            router.go('/keybindings');
          },
        },
      );
}
