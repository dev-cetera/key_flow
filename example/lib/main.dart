import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  runApp(const MyApp());
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Email App Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
      builder: (context, page) {
        if (page == null) return const SizedBox.shrink();
        return Scaffold(
          key: UniqueKey(),
          drawer: const MainDrawer(),
          body: KeyFlowFocus(
            autofocus: true,
            control: MainControl(),
            child: page,
          ),
          bottomSheet: ControlMappingsBuilderExample(
            controls: [
              InboxControl(),
              MainControl(),
              MainDrawerControl(),
              MessagesControl(),
              NavigationControl(),
            ],
          ),
        );
      },
    );
  }
}
