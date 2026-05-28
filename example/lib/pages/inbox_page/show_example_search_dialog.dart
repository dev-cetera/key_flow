import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void showExampleSearchDialog(BuildContext context) {
  final exitAction = UniqueActionKey((_) => 'Exits the search dialog.');
  showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return KeyFlowFocus(
        autofocus: true,
        control: KeyFlowControl(
          mappings: {
            exitAction: [
              const LogicalKeyActivator(LogicalKeyboardKey.escape),
            ],
          },
          callbacks: {
            exitAction: (context, _) {
              Navigator.of(context).pop();
            },
          },
        ),
        child: AlertDialog(
          title: const Text('Search/Find'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search term...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    },
  );
}
