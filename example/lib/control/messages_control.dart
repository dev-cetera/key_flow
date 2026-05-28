import '/_common.dart';

class NextMessageAction extends UniqueActionKey {
  static final i = NextMessageAction._();
  factory NextMessageAction() => i;
  NextMessageAction._() : super((context) => 'Goes to the next message.');
}

class PreviousMessageAction extends UniqueActionKey {
  static final i = PreviousMessageAction._();
  factory PreviousMessageAction() => i;
  PreviousMessageAction._() : super((context) => 'Goes to the previous message.');
}

class OpenMessage1Action extends UniqueActionKey {
  static final i = OpenMessage1Action._();
  factory OpenMessage1Action() => i;
  OpenMessage1Action._() : super((context) => 'Opens the selected message.');
}

class OpenMessage2Action extends UniqueActionKey {
  static final i = OpenMessage2Action._();
  factory OpenMessage2Action() => i;
  OpenMessage2Action._() : super((context) => 'Opens the selected message.');
}

class DeleteMessageAction extends UniqueActionKey {
  static final i = DeleteMessageAction._();
  factory DeleteMessageAction() => i;
  DeleteMessageAction._() : super((context) => 'Deletes a message.');
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MessagesControl extends KeyFlowControl {
  static final i = MessagesControl._();
  factory MessagesControl() => i;
  MessagesControl._()
    : super(
        mappings: {
          NextMessageAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.arrowDown),
          ],
          PreviousMessageAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.arrowUp),
          ],
          OpenMessage1Action(): [
            const LogicalKeyActivator(LogicalKeyboardKey.enter),
          ],
          OpenMessage2Action(): [
            const LogicalKeyActivator(LogicalKeyboardKey.arrowRight),
          ],
          DeleteMessageAction(): [
            const LogicalKeyActivator(LogicalKeyboardKey.minus),
          ],
        },
      );
}
