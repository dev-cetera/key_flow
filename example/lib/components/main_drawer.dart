import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Outer scope: NavigationControl provides I/P/S/K shortcuts; it is
    // *not* autofocused, only the inner scope is. Otherwise the outer
    // would grab focus and the inner's bindings (Z) would never see the
    // key event.
    // Inner scope: MainDrawerControl owns CloseDrawerAction → Z; we
    // attach the callback here. Via the transitive scope-chain merge
    // it also picks up NavigationControl's bindings.
    return KeyFlowFocus(
      control: NavigationControl(),
      child: KeyFlowFocus(
        autofocus: true,
        control: MainDrawerControl().merge(
          callbacks: {
            CloseDrawerAction(): (context, _) {
              Scaffold.of(context).closeDrawer();
            },
          },
        ),
        child: Drawer(
        key: UniqueKey(),
        // Use NavigationControl explicitly here — the nearest scope is
        // MainDrawerControl, which doesn't know about GotoInbox/etc.
        child: KeyFlowMappingsBuilder(
          control: NavigationControl(),
          builder: (context, control, child) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(child: Text('Email App Example')),
                ListTile(
                  title: Text('Inbox (${control.getCombination(GotoInboxAction())?.debugName})'),
                  onTap: () {
                    NavigationControl().call(context, GotoInboxAction());
                  },
                ),
                ListTile(
                  title: Text(
                    'Profile (${control.getCombination(GotoProfileAction())?.debugName})',
                  ),
                  onTap: () {
                    NavigationControl().call(context, GotoProfileAction());
                  },
                ),
                ListTile(
                  title: Text(
                    'Settings (${control.getCombination(GotoSettingsAction())?.debugName})',
                  ),
                  onTap: () {
                    NavigationControl().call(context, GotoSettingsAction());
                  },
                ),
                ListTile(
                  title: Text(
                    'Keybindings (${control.getCombination(GotoKeybindingsAction())?.debugName})',
                  ),
                  onTap: () {
                    NavigationControl().call(context, GotoKeybindingsAction());
                  },
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}
