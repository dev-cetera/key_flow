import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyFlowFocus(
      autofocus: true,
      control: NavigationControl(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Profile Page'),
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
