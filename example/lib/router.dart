import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final router = GoRouter(
  initialLocation: '/inbox',
  routes: [
    GoRoute(path: '/inbox', builder: (context, state) => const InboxPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(path: '/keybindings', builder: (context, state) => const KeybindingsPage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
  ],
);
