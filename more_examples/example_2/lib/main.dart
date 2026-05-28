// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import 'package:key_flow/key_flow.dart';
import 'package:url_launcher/url_launcher.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// Step 1: Define some keys to identify actions in your app. These should be
// globally unique and should not change over time. Any kind of Flutter key
// can be used. Prefer the ContextualKeyFlowKey as it is a UniqueKey that =
// provides a nice description for the action with access the a BuilContext
// for things like localization support.
final openSomeSnackbarAction = UniqueActionKey((context) => 'Opens some snack bar.');
final openDrawerAction = UniqueActionKey((context) => 'Opens the drawer.');
final printAAction = UniqueActionKey((context) => 'Prints "A"');
final printZAction = UniqueActionKey((context) => 'Prints "Z"');
final printQAction = UniqueActionKey((context) => 'Prints "Q"');
final launchGmailAction = UniqueActionKey((context) => 'Launches Gmail');

// Step 2: Link key sequences to actions in your app. These can be rebound later.
// Everything moddable lives here — no inline KeyFlowControl in the widget
// tree. Pass these maps into a single KeyFlowControl below and remap at
// runtime through that controller.
final defaultCombinations = <Key, List<KeyActivator>>{
  // SPACE then SPACE — Superhuman-style two-step sequence.
  openSomeSnackbarAction: [
    const LogicalKeyActivator(LogicalKeyboardKey.space),
    const LogicalKeyActivator(LogicalKeyboardKey.space),
  ],
  // Cmd+D on macOS/iOS, Ctrl+D elsewhere.
  openDrawerAction: [
    const LogicalKeyActivator(LogicalKeyboardKey.keyD, meta: true),
  ],
  // G then G — Superhuman-style sequence — to launch Gmail.
  launchGmailAction: [
    const LogicalKeyActivator(LogicalKeyboardKey.keyG),
    const LogicalKeyActivator(LogicalKeyboardKey.keyG),
  ],
  printAAction: [const LogicalKeyActivator(LogicalKeyboardKey.keyA)],
  printZAction: [const LogicalKeyActivator(LogicalKeyboardKey.keyZ)],
  printQAction: [const LogicalKeyActivator(LogicalKeyboardKey.keyQ)],
};

// Step 3: Link actions to callbacks in your app. These can be rebound later.
final defaultCallbacks = <Key, TContextCallback>{
  openSomeSnackbarAction: (context, registry) {
    showQuickSnackBar(context, 'Here is some snackbar for you. Enjoy!');
  },
  openDrawerAction: (context, registry) => Scaffold.of(context).openDrawer(),
  launchGmailAction: (context, registry) =>
      launchUrl(Uri.parse('https://mail.google.com/mail/u/0/#inbox')),
  printAAction: (context, registry) {
    showQuickSnackBar(context, 'A');
  },
  printZAction: (context, registry) {
    showQuickSnackBar(context, 'Z');
  },
  printQAction: (context, registry) {
    showQuickSnackBar(context, 'Q/R');
  },
};

// Step 4: One global controller holds every moddable app-wide binding.
// Nested KeyFlowFocus widgets get their own (empty or specialised) controller
// — they inherit the bindings above via the ancestor-walk inside
// KeyFlowControl.handleKeyEvent. No KeyFlowControl is ever constructed
// inline in the widget tree, so every binding is reachable for `remap` from
// the buttons further down.
final parentController = KeyFlowControl(
  mappings: defaultCombinations,
  callbacks: defaultCallbacks,
);

// Drawer-only binding. Lifted out of the widget tree so it's just as
// moddable as the rest.
final closeDrawerAction = UniqueActionKey((context) => 'Close the drawer.');
final drawerController = KeyFlowControl(
  mappings: {
    closeDrawerAction: [const LogicalKeyActivator(LogicalKeyboardKey.keyD)],
  },
  callbacks: {
    closeDrawerAction: (context, registry) => Scaffold.of(context).closeDrawer(),
  },
);

// Empty controller for the "parent box" focus scope. Holds no mappings of
// its own — exists only to create a nested focus level so the FocusBuilder
// can switch between PARENT HAS FOCUS / CHILD HAS FOCUS / UNFOCUSED.
// Keys inherit from `parentController` via the ancestor walk.
final boxController = KeyFlowControl();

// The innermost ("child") scope overrides `printQAction` — pressing Q here
// fires a different snackbar even if the parent has remapped Q -> R.
final childQOverrideController = KeyFlowControl(
  mappings: {
    printQAction: [const LogicalKeyActivator(LogicalKeyboardKey.keyQ)],
  },
  callbacks: {
    printQAction: (context, registry) {
      showQuickSnackBar(context, 'CHILD: Q');
    },
  },
);

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _Example2State extends State<Example2> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        extendBody: true,
        // When the drawer is in focus, allow the D key to close it.
        drawer: KeyFlowFocus(
          autofocus: true,
          control: drawerController,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: const [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue),
                  child: Text('Drawer Header'),
                ),
                ListTile(title: Text('Item 1')),
                ListTile(title: Text('Item 2')),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: KeyFlowFocus(
            // Ensure the root of the app is always focused so that these key
            // mappings are always active. This can be achieved by setting
            // autofocus to true and providing a UniqueKey to force rebuilds.
            key: UniqueKey(),
            autofocus: true,
            control: parentController,

            // Show a green bar at the bottom of the screen when focused.
            child: FocusBuilder(
              hasFocusBuilder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child!,
                    const KeyMapExample(),
                    Container(
                      color: Colors.green,
                      height: 40.0,
                      width: double.infinity,
                      child: const Text(
                        'THE APP IS IN FOCUS - KEY COMBINATIONS WILL WORK IF THE WINDOW IS ALSO IN FOCUS',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
              // Show a red bar at the bottom of the screen when focused.
              hasNoFocusBuilder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child!,
                    const KeyMapExample(),
                    Container(
                      color: Colors.red,
                      height: 40.0,
                      width: double.infinity,
                      child: const Text(
                        'THE APP IS OUT OF FOCUS - KEY COMBINATIONS WILL NOT WORK',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
              child: Builder(
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          [
                            'The app is in focus when the bottom bar is green and not red.',
                            'Press TAB to cycle through elements.',
                            'Some key mappings only work when focused on certain elements. This is completely customizable.',
                            'Press A, Z or Q to print when focused on the box (blue or grreen).',
                            'You can remap Q -> R or R -> Q.',
                            'Tap SPACE twice to show the snackbar when focused on the box (blue or grreen).',
                            'Left Ctrl + D to open the drawer and D again to close it.',
                            'G + G to open to Gmail.',
                          ].join('\n\n'),
                        ),
                        const SizedBox(height: 20.0),
                        FilledButton(
                          onPressed: () {
                            // Remap the Q key to the R key.
                            parentController.remap(printQAction, [
                              const LogicalKeyActivator(LogicalKeyboardKey.keyR),
                            ]);
                            showQuickSnackBar(context, 'REMAP PARENT Q -> R');
                          },
                          child: const Text('REMAP PARENT Q -> R'),
                        ),
                        const SizedBox(height: 20.0),
                        FilledButton(
                          onPressed: () {
                            // Remap the R key to the Q key.
                            parentController.remap(printQAction, [
                              const LogicalKeyActivator(LogicalKeyboardKey.keyQ),
                            ]);
                            showQuickSnackBar(context, 'REMAP PARENT R -> Q');
                          },
                          child: const Text('REMAP PARENT R -> Q'),
                        ),

                        const SizedBox(height: 20.0),
                        // KeyboardFocus widgets can be nested. The child's keybindings will take
                        // precedence over the parent's keybindings. `boxController` is empty
                        // — it exists only as a separate focus scope; the bindings inherit
                        // from `parentController` above via the ancestor walk.
                        KeyFlowFocus(
                          control: boxController,
                          child: FocusBuilder(
                            hasFocusBuilder: (context, _) {
                              // Let's override the Q keybinding for this child.
                              return KeyFlowFocus(
                                control: childQOverrideController,
                                // Build two different widgets depending on focus of the nearest parent.
                                child: FocusBuilder(
                                  hasFocusBuilder: (_, __) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const KeyMapExample(),
                                        Container(
                                          width: 300,
                                          height: 300,
                                          color: Colors.blue,
                                          child: const Text('CHILD HAS FOCUS'),
                                        ),
                                      ],
                                    );
                                  },
                                  hasNoFocusBuilder: (_, __) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const KeyMapExample(),
                                        Container(
                                          width: 300,
                                          height: 300,
                                          color: Colors.green,
                                          child: const Text('PARENT HAS FOCUS'),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                            hasNoFocusBuilder: (_, __) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const KeyMapExample(),
                                  Container(
                                    width: 300,
                                    height: 300,
                                    color: Colors.red,
                                    child: const Text('UNFOCUSED'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void showQuickSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 1)));
}

class Example2 extends StatefulWidget {
  const Example2({super.key});

  @override
  State<Example2> createState() => _Example2State();
}

void main() {
  runApp(const Example2());
}
