[![pub](https://img.shields.io/pub/v/key_flow.svg)](https://pub.dev/packages/key_flow)
[![tag](https://img.shields.io/badge/Tag-v0.2.0-purple?logo=github)](https://github.com/dev-cetera/key_flow/tree/v0.2.0)
[![buymeacoffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/dev_cetera)
[![sponsor](https://img.shields.io/badge/Sponsor-grey?logo=github-sponsors&logoColor=pink)](https://github.com/sponsors/dev-cetera)
[![patreon](https://img.shields.io/badge/Patreon-grey?logo=patreon)](https://www.patreon.com/robelator)
[![discord](https://img.shields.io/badge/Discord-5865F2?logo=discord&logoColor=white)](https://discord.gg/gEQ8y2nfyX)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

# key_flow

[![Pub Version](https://img.shields.io/pub/v/key_flow)](https://pub.dev/packages/key_flow)

A Flutter package that simplifies UI navigation by providing abstractions for keyboard shortcuts and keybindings. Whether you're building a desktop app, a web app, or enhancing accessibility in mobile apps, `key_flow` empowers you to create intuitive and efficient keyboard-driven interactions. It abstracts the complexity of managing focus, key events, and keybindings, allowing you to focus on delivering a seamless user experience.

## Simple Example

```dart
// Create a key to identify some action.
final actionKey = UniqueKey();

// Create a control to manage key mappings and callbacks.
final control = KeyFlowControl(
  mappings: {actionKey: [PhysicalKeyboardKey.keyA]},
  callbacks: {
    actionKey: (context, _) => print('You pressed "A" while focused.'),
  },
);

// Wrap any widget with a KeyFlowFocus. When in focus, its actions apply.
Widget build(BuildContext context) {
  return KeyFlowFocus(
    // Automatically focus the widget to receive key events.
    autofocus: true,
    control: control,
    child: Builder(
      builder: (context) {
        final hasFocus =  FocusScope.of(context).hasFocus;
        if (hasFocus) {
          return Text('Press A to print.');
        }
        return Text('Not focused');
      },
    ),
  );
}
```

## Examples

- [Example 0](https://github.com/dev-cetera/key_flow/blob/main/example/lib/): An example of a basic email app supporting keyboard controls.
- [Example 1](https://github.com/dev-cetera/key_flow/blob/main/more_examples/example_1/lib/): TODO...
- [Example 2](https://github.com/dev-cetera/key_flow/blob/main/more_examples/example_2/lib/): TODO...
- [Example 3](https://github.com/dev-cetera/key_flow/blob/main/more_examples/example_3/lib/): A simple example of keyboard navigation and controls for tabs in flutter.
- [Example 4](https://github.com/dev-cetera/key_flow/blob/main/more_examples/example_4/lib/): A simple email app example with keyboard navigation and focus management.
- [Example 5](https://github.com/dev-cetera/key_flow/blob/main/more_examples/example_5/lib/): Full demo with help overlay, command palette, and swappable KeyFlow/Vim/Emacs profiles.

## Why key_flow?

Keyboard navigation is essential for accessibility, productivity, and user satisfaction, especially in desktop and web applications. However, managing keyboard shortcuts and focus in Flutter can be challenging due to the need to handle focus nodes, key events, and dynamic mappings manually. `key_flow` addresses these challenges by providing:

- **Simplified Abstractions:** Define actions, key combinations, and callbacks with minimal boilerplate, making keyboard navigation intuitive and maintainable.
- **Focus Management Made Easy:** KeyFlowFocus handles focus nodes and autofocus behavior, ensuring keybindings work only when intended, enhancing user focus and reducing conflicts.
- **Flexible and Dynamic:** Support for nested keybindings, dynamic remapping, and localization ensures your app can adapt to user preferences and accessibility needs.
- **Accessibility Boost:** By enabling keyboard navigation, your app becomes more accessible to users with disabilities, aligning with WCAG guidelines.
- **Enhanced Productivity:** Users can navigate and perform actions faster, improving the overall usability of your app, especially for power users.
- **Scalable and Maintainable:** The modular design allows you to manage keybindings across different parts of your app, making it easier to scale and maintain as your app grows.

Whether you're adding keyboard shortcuts to a text editor, enabling navigation in a dashboard, or enhancing accessibility in a game, `key_flow` is the tool you need to streamline the process and deliver a polished user experience.

## Features

- **Simplified Keyboard Navigation:** Easily manage keyboard shortcuts and keybindings in your Flutter applications.
- **Focus Management:** Utilize `KeyFlowFocus` to manage focus nodes and key events with customizable autofocus behavior.
- **Flexible Key Mapping:** Define and manage key combinations and their associated actions using `KeyFlowControl`.
- **Inherited Widget Support:** Leverage `KeyFlowScope` for accessing key flow control up the widget tree.
- **Descriptive Keys:** Use `UniqueActionKey` for uniquely identifying actions with descriptive callbacks with access to a `BuildContext` for localization support.
- **Dynamic Key Remapping:** Dynamically remap keys and callbacks at runtime for flexible user experiences.
- **Nested Keybindings:** Support nested `KeyFlowFocus` widgets where child keybindings take precedence over parent keybindings.

---

## Flutter Keys, Focus, and FocusNode: A Quick Refresher

Before diving into `key_flow`, let's refresh your understanding of Flutter's key and focus management concepts, as they are crucial for effective keyboard navigation.

### Flutter Keys

Keys in Flutter are identifiers for widgets, used to preserve state or distinguish between widgets in a list or tree. They are essential for maintaining widget identity across rebuilds. Types of keys include `UniqueKey`, `ValueKey`, and the custom `UniqueActionKey` in `key_flow` which
provides a description of the action associated with the key.

#### Why Keys Matter for Keybindings

Keys uniquely identify actions in your app, ensuring that key combinations and callbacks are associated with the correct actions. Keys should be unique accross your app to avoid conflicts.

#### Focus

The Flutter `Focus` widget determines which widget in the UI can receive input events, such as keyboard presses. Many widgets in Flutter incorporate focus management to handle user interactions such as the `TextField`, `FilledButton`, `Checkbox` and more. `key_flow` internally uses `Focus` to manage focus for keybindings. The `Focus` widget has an `autofocus` property that automatically focuses the widget when it is built. Setting `autofocus: true` ensures the widget receives key events without requiring manual focus management.

#### FocusNode

A `FocusNode` is an object that manages focus for a widget such as a `Focus`. It tracks whether a widget is focused and handles focus-related events. The `FocusNode` has several properties and methods to manage focus, such as:

- `hasFocus`: Indicates if the node currently has focus.
- `requestFocus()`: Requests focus for the node.
- `unfocus()`: Removes focus from the node.
- `onKeyEvent`: A callback for handling key events when the node is focused..

### Focus and FocusNode Example

```dart
final focusNode = FocusNode();
Focus(
  autofocus: true,
  focusNode: focusNode,
  onKeyEvent: (node, event) {
  if (event is KeyDownEvent && event.logicalKey == PhysicalKeyboardKey.keyA) {
    print('A pressed');
    return KeyEventResult.handled;
  }
    return KeyEventResult.ignored;
  },
  child: Builder(
    builder: (context) {
      final hasFocus =  FocusScope.of(context).hasFocus;
      if (hasFocus) {
        return Text('Press A to print.');
      }
      return Text('Not focused');
    },
  ),
);
```

### Why Focus Matters for Keybindings

Keybindings only work when the associated widget is focused. `key_flow` simplifies focus management, ensuring key events are handled correctly based on focus state. To automatically focus a widget, use `autofocus: true` in `KeyFlowFocus`. For manual focus management, use the `focusNode` property.

Understanding all the concepts above will help you leverage `key_flow` effectively, as it builds on Flutter's focus and key systems to provide a streamlined keyboard navigation experience.

---

## Usage

Now that you have a good understanding of Flutter keys, focus, and focus nodes, let's explore how to use `key_flow` to enhance keyboard navigation in your Flutter app...

### Step 1: Define Action Keys

Define unique keys to identify actions in your app. Actions are associated with callbacks that are triggered when the corresponding key combination is pressed.

```dart
import 'package:key_flow/key_flow.dart';

// Prefer using `UniqueActionKey` for descriptive and localizable action identifiers:
final openSomeSnackbarAction = UniqueActionKey((context) => 'Opens some snack bar.');
final openDrawerAction = UniqueActionKey((context) => 'Opens the drawer.');
final printAAction = UniqueActionKey((context) => 'Prints "A"');
final printZAction = UniqueActionKey((context) => 'Prints "Z"');
final printQAction = UniqueActionKey((context) => 'Prints "Q"');
final launchGmailAction = UniqueActionKey((context) => 'Launches Gmail');

// Normal Flutter keys can also be used, but they don't provide descriptive information:
final printInfoAction = UniqueKey();
final exitAppAction = ValueKey('exit-app');
```

### Step 2: Define Default Key Mappings

Link key sequences to actions. These can be rebound later.

```dart
final defaultMappings = {
  openSomeSnackbarAction: [PhysicalKeyboardKey.space, PhysicalKeyboardKey.space],
  printAAction: [PhysicalKeyboardKey.keyA],
  printZAction: [PhysicalKeyboardKey.keyZ],
  printQAction: [PhysicalKeyboardKey.keyQ],
};
```

### Step 3: Define Default Callbacks

Link actions to callbacks. These can also be rebound later.

```dart
final defaultCallbacks = <Key, TContextCallback>{
  openSomeSnackbarAction: (context, registry) {
    showQuickSnackBar(context, 'Here is some snackbar for you. Enjoy!');
  },
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
```

### Step 4: Create a Control

Create a `KeyFlowControl` instance to manage key events for specific focus areas in the widget tree.

```dart
final defaultControl = KeyFlowControl(
  mappings: defaultMappings,
  callbacks: defaultCallbacks,
);
```

### Step 5: Integrate with Widgets

Use `KeyFlowFocus` to integrate key flow control into your widget tree. Ensure proper focus management for keybindings to work.

```dart
KeyFlowFocus(
  key: UniqueKey(),
  // Automatically focus the widget on build to receive key events.
  autofocus: true,
  // Alternatively, use `focusNode` to manage focus manually.
  //focusNode: FocusNode(),
  // Pass a control to manage key events and actions.
  control: defaultControl,
  // Your widget tree here...
  child: // ...
),
```

---

## Testing

The package ships with a comprehensive test suite (200+ tests) that exercises every component — `KeyActivator` matching across platforms and modifiers, `KeyFlowControl` lifecycle and dispatch logic, every widget (`KeyFlowFocus`, `KeyFlowScope`, `KeyFlowMappingsBuilder`, `ControlMappingsBuilder`, `FocusBuilder`, `FocusHighlighter`), and integration scenarios:

- **Multi-step sequences** — Superhuman-style "g i" sequences, timeouts, buffer resets, completion-then-restart.
- **Cross-scope shortcuts** — child controls walking the ancestor chain to fire root-declared bindings; child bindings taking precedence; deduping of shared singleton controls referenced from multiple scopes.
- **Text-field suppression** — bare keys suppressed inside `TextField`s, modifier chords passing through, and sequences refusing to start.
- **Repeat events** — single-key activators fire on `KeyRepeatEvent` (for held arrow-keys etc.), sequences do not advance on repeats, `KeyUpEvent` is always ignored.
- **Lifecycle & stress** — dispose mid-sequence (no leaked timers), rapid input (100 presses in a row), large mapping sets (500+ bindings), and runtime mutation (add/remove/replace) during active focus.

```sh
flutter test               # run everything
flutter test test/unit     # fast unit tests only
flutter test test/widget   # widget-level tests
flutter test test/integration   # end-to-end scenarios
```

## Contributions and Feedback

Contributions, feedback, and feature requests are welcome! If you encounter any issues or have suggestions for improving `key_flow`, please open an issue on the GitHub repository.

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE) for more information.

<!-- END _README_CONTENT -->

---

🔍 For more information, refer to the [API reference](https://pub.dev/documentation/key_flow/).

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### ☕ We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## LICENSE

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE) for more information.
