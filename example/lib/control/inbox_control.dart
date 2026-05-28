import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GotoMessagesTabAction extends UniqueActionKey {
  static final i = GotoMessagesTabAction._();
  factory GotoMessagesTabAction() => i;
  GotoMessagesTabAction._() : super((context) => 'Opens the messages tab in the inbox screen.');
}

class GotoNotificationsTabAction extends UniqueActionKey {
  static final i = GotoNotificationsTabAction._();
  factory GotoNotificationsTabAction() => i;
  GotoNotificationsTabAction._()
    : super((context) => 'Opens the notifications tab in the inbox screen.');
}

class OpenTasksTabAction extends UniqueActionKey {
  static final i = OpenTasksTabAction._();
  factory OpenTasksTabAction() => i;
  OpenTasksTabAction._() : super((context) => 'Opens the tasks tab in the inbox screen.');
}

class OpenSearchDialogAction extends UniqueActionKey {
  static final i = OpenSearchDialogAction._();
  factory OpenSearchDialogAction() => i;
  OpenSearchDialogAction._() : super((context) => 'Opens a search dialog from the inbox screen.');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class InboxControl extends KeyFlowControl {
  static final i = InboxControl._();
  factory InboxControl() => i;
  InboxControl._()
    : super(
        mappings: {
          NextMessageAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.arrowDown),
          ],
          PreviousMessageAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.arrowUp),
          ],
          GotoMessagesTabAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyM),
          ],
          GotoNotificationsTabAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyN),
          ],
          OpenTasksTabAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyT),
          ],
          OpenSearchDialogAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.keyG, meta: true),
          ],
        },
        callbacks: {
          OpenSearchDialogAction(): (context, _) {
            showExampleSearchDialog(context);
          },
        },
      );
}
