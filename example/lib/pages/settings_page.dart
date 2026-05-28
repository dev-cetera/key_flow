import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyFlowFocus(
      autofocus: true,
      control: NavigationControl(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Settings Page'),
              ElevatedButton(
                onPressed: () => router.go('/inbox'),
                child: const Text('Back to Inbox'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
