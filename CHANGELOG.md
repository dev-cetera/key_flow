# CHANGELOG

## [0.3.0]

- feat!: a tree of commands replaces the flat key map: `KeyFlow` at the top, `KeyFlowScope` for each part of the screen, `KeyCommand` and `KeyGroup` nested as deep as needed, merged by id across scopes
- feat: keys written as text (`meta+k`, `g p s`, `?`, `⌘⇧K`); groups with keys open a panel of what to press next that waits until a key, Escape or Backspace
- feat: built-in command palette, shortcut sheet, jump mode and moving between named areas
- feat: `KeyTarget` and `KeyHint` give controls a command's name, keys, state and a focus ring for screen readers and agents; on macOS the shortcut is also the accessibility value
- feat: native macOS menus and drawn menus elsewhere from the same tree (`KeyFlowMenuBar`, `platformMenusOf`, `menuBarChildrenOf`)
- feat: `toCommandList`, `toToolList`, `run`, `runTool` and `onCommandRun` for AI agents and an app's own AI
- feat: `keyOverrides` and `setKeys` for a person's own keys and key profiles
- feat: `findAccessibilityIssues` finds tappable controls with no name or no keyboard way in
- fix: key names no longer depend on debug-only names, so release builds show ⌘K, not an internal name
- fix: a sequence such as `meta+k d` matches the modifiers held for each key
- chore: needs Flutter 3.32; drops `df_pod`
- docs: new example and README

## [0.2.2]

- Merge branch 'main' into prod


## [0.2.1]

- docs: remove Discord, point contributors to issues and email

## [0.2.0]

- chore: standardize README and CI/CD workflows, remove donation links, update contact info and repository links
- chore: resolve analyzer issues

## [0.1.0]

- Initial release
