import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class KeybindingsPage extends StatelessWidget {
  const KeybindingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyFlowFocus(
      autofocus: true,
      control: NavigationControl(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Keybindings')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              spacing: 16.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MAIN BINDINGS', style: Theme.of(context).textTheme.headlineSmall),
                KeyMapExample(control: MainControl()),
                Text('MAIN DRAWER BINDINGS', style: Theme.of(context).textTheme.headlineSmall),
                KeyMapExample(control: MainDrawerControl()),
                Text('INBOX BINDINGS', style: Theme.of(context).textTheme.headlineSmall),
                KeyMapExample(control: InboxControl()),
                Text('MESSAGES BINDINGS', style: Theme.of(context).textTheme.headlineSmall),
                KeyMapExample(control: MessagesControl()),
                Text('NAVIGATION BINDINGS', style: Theme.of(context).textTheme.headlineSmall),
                KeyMapExample(control: NavigationControl()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
