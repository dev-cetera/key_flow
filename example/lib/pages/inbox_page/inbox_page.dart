import 'package:df_pod/df_pod.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _InboxPageState extends State<InboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyFlowFocus(
      autofocus: true,
      control: NavigationControl(),
      child: KeyFlowFocus(
        autofocus: true,
        focusNode: focusNode,
        control: InboxControl().merge(
          callbacks: {
            NextMessageAction(): (context, registry) {
              if (_tabController.index == 0) {
                MessagesControl().focusNode?.requestFocus();
                MessagesControl().call(context, NextMessageAction());
              }
            },
            PreviousMessageAction(): (context, registry) {
              if (_tabController.index == 1) {
                MessagesControl().focusNode?.requestFocus();
                MessagesControl().call(context, PreviousMessageAction());
              }
            },
            GotoMessagesTabAction(): (_, __) {
              _tabController.animateTo(0);
            },
            GotoNotificationsTabAction(): (_, __) {
              _tabController.animateTo(1);
            },
            OpenTasksTabAction(): (_, __) {
              _tabController.animateTo(2);
            },
          },
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Inbox'),
            ),
            actions: [
              PodBuilder(
                pod: InboxControl().mappingsNotifier,
                builder: (context, snapshot) {
                  return TextButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(
                      'Search (${InboxControl().getCombination(OpenSearchDialogAction())?.debugName})',
                    ),
                    onPressed: () {
                      InboxControl().call(context, OpenSearchDialogAction());
                    },
                  );
                },
              ),
              TextButton(
                onPressed: () {
                  InboxControl().remap(OpenSearchDialogAction(), [
                    const LogicalKeyActivator(
                      LogicalKeyboardKey.keyF,
                      meta: true,
                    ),
                  ]);
                },
                child: const Text('G -> F'),
              ),
              TextButton(
                onPressed: () {
                  InboxControl().remap(OpenSearchDialogAction(), [
                    const LogicalKeyActivator(
                      LogicalKeyboardKey.keyG,
                      meta: true,
                    ),
                  ]);
                },
                child: const Text('F -> G'),
              ),
            ],
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                MainControl().call(context, OpenDrawerAction());
              },
              tooltip: 'Open navigation menu',
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kTextTabBarHeight),
              child: KeyFlowMappingsBuilder(
                builder: (context, control, _) => TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      text:
                          'Messages (${control.getCombination(GotoMessagesTabAction())?.debugName})',
                    ),
                    Tab(
                      text:
                          'Notifications (${control.getCombination(GotoNotificationsTabAction())?.debugName})',
                    ),
                    Tab(
                      text:
                          'Tasks (${control.getCombination(OpenTasksTabAction())?.debugName})',
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              const MessagesTab(),
              const NotificationsTab(),
              const TasksTab(),
            ],
          ),
        ),
      ),
    );
  }
}
