import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CloseDrawerAction extends UniqueActionKey {
  static final i = CloseDrawerAction._();
  factory CloseDrawerAction() => i;
  CloseDrawerAction._() : super((context) => 'Closes the drawer when in focus.');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MainDrawerControl extends KeyFlowControl {
  static final i = MainDrawerControl._();
  factory MainDrawerControl() => i;
  MainDrawerControl._()
    : super(
        mappings: {
          CloseDrawerAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyZ),
          ],
        },
      );
}
