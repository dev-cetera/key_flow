[![pub](https://img.shields.io/pub/v/key_flow.svg)](https://pub.dev/packages/key_flow)
[![tag](https://img.shields.io/badge/Tag-v0.2.0-purple?logo=github)](https://github.com/dev-cetera/key_flow/tree/v0.2.0)
[![instagram](https://img.shields.io/badge/Instagram-E4405F?logo=instagram&logoColor=white)](https://www.instagram.com/dev_cetera/)
[![license](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

# key_flow

[![Pub Version](https://img.shields.io/pub/v/key_flow)](https://pub.dev/packages/key_flow)

Keyboard-first Flutter apps that screen readers and AI agents can use too.

Declare what your app can do once, as a tree of commands nested as deep as you like. key_flow turns it into:

- **Shortcuts**, including keys pressed one after another (`G P 1`). After the first key a panel shows what to press next, and it waits until you choose: no one has to be quick, an agent included.
- **A command palette** (⌘K), **a sheet of every shortcut** (`?` or ⌘/), **jump mode** (⌘J puts letters on every control; type them to press it) and **moving between areas** (F6). Nothing needs a mouse.
- **Menus**: the macOS menu bar, or a bar drawn in the window on Windows, Linux and the web.
- **Accessible controls**: anything linked to a command gets its name, keys, enabled and on/off state, and a focus ring.
- **Plain data for AI**: the commands in force as a list, or as tool definitions for a model, and a way to run them by id.

## Quick start

```dart
MaterialApp(
  builder: (context, child) => KeyFlow(
    commands: [
      KeyCommand(id: 'new', label: 'New project', keys: ['meta+n'],
          onRun: (context) => newProject()),
      KeyGroup(id: 'go', label: 'Go to', keys: ['g'], children: [
        KeyCommand(id: 'inbox', label: 'Inbox', keys: ['i'],
            onRun: (context) => openInbox()),
        KeyGroup(id: 'project', label: 'Project', keys: ['p'], children: [
          for (final (i, p) in projects.indexed)
            KeyCommand(id: p.id, label: p.name, keys: ['${i + 1}'],
                onRun: (context) => open(p)),
        ]),
      ]),
    ],
    child: KeyFlowMenuBar(drawOnOtherPlatforms: true, child: child!),
  ),
  home: const HomePage(),
);
```

Put `KeyFlow` in `MaterialApp.builder` (or `WidgetsApp.builder`) so it covers every route and dialog.

## Nesting

Two kinds of nesting work together.

**By where the person is.** Wrap each part of the screen that has commands of its own in a `KeyFlowScope`. The commands in force are the app's, then each scope's around the focused widget; the nearest wins when two use the same keys. A click inside a scope moves the focus into it.

```dart
Row(children: [
  KeyFlowScope(
    region: 'Sidebar',                       // F6 moves between named areas
    commands: [KeyCommand(id: 'next', label: 'Next', keys: ['down'], onRun: ...)],
    child: const ProjectList(),
  ),
  KeyFlowScope(
    region: 'Editor',
    commands: [
      KeyCommand(id: 'run', label: 'Run', keys: ['meta+r'], onRun: ...),
      KeyGroup(id: 'step', label: 'Step', keys: ['s'], children: [   // S, then:
        KeyCommand(id: 'add', label: 'Add step', keys: ['a'], onRun: ...),
        KeyCommand(id: 'delete', label: 'Delete step', keys: ['d'], onRun: ...),
      ]),
    ],
    child: const Editor(),
  ),
]);
```

**Inside the keys.** A `KeyGroup` with `keys` is a step: its children's keys come after its own (`G` then `P` then `1`). A group without keys only gathers commands under a name, for a menu, the palette or the shortcut sheet, and its children's keys work as if it were not there.

- Full ids join the groups' ids with dots: `go.project.shop`. Ids use letters, digits, `-` and `_` and are never translated.
- A group with the same id in an inner scope is the same group: the scope adds children to it and replaces those with the same id. A page can add itself to the app's "Go to" group by declaring `KeyGroup(id: 'go', children: [...])` with only its own children.
- `KeyDivider()` draws a line in menus and panels.
- Keys that could mean two things in the same scope are printed in debug builds; between scopes the nearer one deliberately wins.

## Writing keys

| Text | Means |
|---|---|
| `meta+k` | ⌘K on macOS and iOS, Ctrl+K elsewhere |
| `ctrl+k` | Ctrl+K everywhere |
| `alt+shift+enter`, `f5`, `escape`, `up`, `space`, `meta++` | as written |
| `g` | the G key alone (left to text fields while someone types) |
| `?`, `/` | whatever key types that character on the person's layout |
| `g p 1` | G, then P, then 1 |
| `⌘⇧K`, `G P 1` | what the panels show reads back the same |

`KeyBinding.parse` and `KeyActivator.parse` read them; `toSpec()` and `describe()` write them back.

## Linking controls

`KeyTarget` makes anything a control for a command: Tab reaches it, Enter or Space presses it, a click runs it, hovering shows its keys, and a screen reader or agent reads it by the command's name. It greys out when the command cannot run and shows on or off for a switch (`checked`).

```dart
KeyTarget(command: 'run', child: MyRunButtonLook())
```

For a control that is already a button, `KeyHint` adds the command's name, keys and tooltip, and `callbackFor` greys it out with the command:

```dart
KeyHint(
  command: 'run',
  child: IconButton(
    icon: const Icon(Icons.play_arrow),
    onPressed: KeyFlow.of(context).callbackFor(context, 'run'),
  ),
)
```

## Panels and how they look

key_flow adds a `keyflow` group with the palette (⌘K), the shortcut sheet (`?`, ⌘/), jump mode (⌘J) and moving between areas (F6, ⇧F6). Change their names and keys with `KeyFlowBuiltIns`, their words with `KeyFlowStrings`, and their colours with `KeyFlowStyle` (taken from the app's `Theme` by default). `panelBuilder` wraps or replaces any panel; `KeyFlow.of(context)` gives a custom panel everything it needs.

Hide a command from a place with `hiddenFrom: {KeySurface.palette}` (or `menuBar`, `helpSheet`, `prefixPanel`, `agents`). Wrap controls only the person should press, such as approving what an agent asks for, in `KeyJumpExclude`, and give their commands no keys and `hiddenFrom: {KeySurface.agents}`.

## Menus

Mark top-level groups `inMenuBar: true` (File, Edit, View) and put `KeyFlowMenuBar` inside the `KeyFlow`. On macOS the groups become the native menu bar, kept in step with where the focus is, after the standard app menu (About, Hide, Quit; replace it with `leading`); `trailing` adds Window or Help. With `drawOnOtherPlatforms: true`, other platforms get the same menus drawn above the app. An app with its own menu bar can use `platformMenusOf` or `menuBarChildrenOf`.

## People's own keys

Pass `keyOverrides` (full id to keys) to change any command's keys, built-ins included, and save what `onKeyOverridesChanged` reports after `controller.setKeys(id, keys)`. Swapping whole maps gives key profiles:

```dart
KeyFlow(
  keyOverrides: vim ? {'next': ['j', 'down'], 'previous': ['k', 'up']} : {},
  ...
)
```

## AI agents

The same commands reach an agent three ways.

**An app's own AI.** Give the model the commands in force as tools and run the one it calls:

```dart
final keys = KeyFlow.of(context);
final tools = keys.currentTree.toToolList();   // [{name, description, parameters}]
// ... the model calls a tool by name ...
await keys.runTool(toolCall.name);
```

`toCommandList()` gives the same commands as plain data (id, label, path, keys from the top, shortcuts as shown, enabled, checked). `run(id)` runs a command or opens a group; `onCommandRun` tells the app, and so its AI, what the person just did.

**An agent driving the app from outside** (through accessibility and the keyboard, such as apprentice). Every linked control and panel line is a named button. On macOS its value is its shortcut, since macOS drops the accessibility hint, so an agent reads `button "Run" value="⌘R"` and can press the key. The palette and the shortcut sheet are readable text, and native menus show each shortcut.

On macOS, Flutter shows its controls to accessibility clients other than VoiceOver only once the window says a screen reader started. Add this to `macos/Runner/MainFlutterWindow.swift`, after `RegisterGeneratedPlugins` (key_flow reminds you in debug builds):

```swift
DispatchQueue.main.async {
  NotificationCenter.default.post(
    name: NSNotification.Name("NSApplicationDidChangeAccessibilityEnhancedUserInterfaceNotification"),
    object: NSApp, userInfo: ["AXEnhancedUserInterface": true])
}
```

Flutter on macOS does not pass on a text field's label; put a visible label next to each field.

## Checking accessibility in tests

```dart
final handle = tester.ensureSemantics();
final view = tester.binding.renderViews.first;
final root = view.owner!.semanticsOwner!.rootSemanticsNode!;
expect(findAccessibilityIssues(root), isEmpty);   // unnamed, or no keyboard way in
handle.dispose();
```

## Upgrading from 0.2

0.3 replaces the flat map of keys with the command tree.

| 0.2 | 0.3 |
|---|---|
| `KeyFlowControl(mappings:, callbacks:)` | `KeyCommand`s and `KeyGroup`s in `KeyFlow(commands:)` or `KeyFlowScope(commands:)` |
| `UniqueActionKey((c) => 'Label')` | `KeyCommand(id: 'x', label: 'Label')` |
| `KeyFlowFocus(control:)` | `KeyFlowScope(commands:)` |
| `[KeyActivator.logical(keyG), KeyActivator.logical(keyI)]` | `keys: ['g i']`, or a `KeyGroup` on `g` |
| `control.remap(key, …)` | `KeyFlow.of(context).setKeys('id', [...])` |
| `FocusHighlighter` | the focus ring of `KeyTarget` |
| help overlay and palette from the examples | built in |

`KeyActivator` and `FocusBuilder` stay. `KeyActivator` can also match a typed character, prints Enter as ↩ on Apple platforms, and its `toString()` shows the text form (`meta+enter`).

## Example

[example/lib/main.dart](https://github.com/dev-cetera/key_flow/blob/main/example/lib/main.dart): a projects app run entirely from the keyboard, with menus, nested groups, two areas, linked controls, a text field, Vim keys as a profile, and a panel showing what agents see, live.

## License

MIT, see [LICENSE](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE).

<!-- END _README_CONTENT -->

---

🔍 For more information, refer to the [API reference](https://pub.dev/documentation/key_flow/).

---

## 💬 Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### ☝️ Ways you can contribute

- **Raise a ticket:** Open an issue on the [GitHub repository](https://github.com/dev-cetera/key_flow/issues) for questions, bugs and feature requests.
- **Get in touch:** Email [hello@robertsolves.com.au](mailto:hello@robertsolves.com.au) if you would like to contribute or collaborate.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

## 👤 Author & Contact

- Website: [robertsolves.com.au](https://robertsolves.com.au)
- Organization: [dev-cetera.com](https://dev-cetera.com)
- Email: [robert@dev-cetera.com](mailto:robert@dev-cetera.com) or [hello@robertsolves.com.au](mailto:hello@robertsolves.com.au)

## LICENSE

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/key_flow/main/LICENSE) for more information.
