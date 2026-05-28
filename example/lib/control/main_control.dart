import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ExitAppAction extends UniqueActionKey {
  static final i = ExitAppAction._();
  factory ExitAppAction() => i;
  ExitAppAction._() : super((context) => 'Exits the app from anywhere in the app.');
}

class OpenDrawerAction extends UniqueActionKey {
  static final i = OpenDrawerAction._();
  factory OpenDrawerAction() => i;
  OpenDrawerAction._() : super((context) => 'Opens the drawer from anywhere in the app.');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MainControl extends KeyFlowControl {
  static final i = MainControl._();
  factory MainControl() => i;
  MainControl._()
    : super(
        mappings: {
          OpenDrawerAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyD, meta: true),
          ],
          ExitAppAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.escape),
          ],
        },
        callbacks: {
          OpenDrawerAction(): (context, registry) {
            Scaffold.of(context).openDrawer();
          },
          ExitAppAction(): (context, registry) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Closing app...')));
          },
        },
      );
}
