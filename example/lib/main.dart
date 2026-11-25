//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// A small projects app, run entirely from the keyboard:
//
//   ⌘K        search every command          ?  or ⌘/   every shortcut
//   ⌘J        jump to any control            F6         next area
//   G P 1     go to the first project        G N        go to the notes
//   ⌘R ⌘.     run and stop the project       F2         rename it
//   ↑ ↓       move through the projects      View ▸ Vim keys: J and K
//   ⌘⇧A       what agents see: the commands as AI tools, live
//   ⌘⇧T       show me around: two cursors play a scripted tour
//
// On the web, `keyFlow.help()` in the browser console lists what a browser
// agent can do: read the commands, run them and play scripts.
//
// Build with --dart-define=KEYFLOW_PANEL=palette (or help, jump, go, tour) to
// open a panel or start the tour at start, for screenshots and agent checks.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

void main() => runApp(const ExampleApp());

const _startPanel = String.fromEnvironment('KEYFLOW_PANEL');

class Project {
  final String id;
  String name;
  bool running = false;

  Project(this.id, this.name);
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _keys = KeyFlowController();
  final _navigator = GlobalKey<NavigatorState>();
  final _notes = FocusNode(debugLabel: 'Notes');
  final _projects = [
    Project('shop', 'My Shop'),
    Project('consulting', 'Consulting'),
    Project('blog', 'Blog'),
  ];
  var _open = 0;
  var _sidebar = true;
  var _agentView = false;
  var _vimKeys = false;
  var _status = 'Press ⌘K to search, ? for every shortcut.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (_startPanel) {
        case 'palette':
          _keys.showPalette();
        case 'help':
          _keys.showHelp();
        case 'jump':
          _keys.startJump();
        case 'go':
          _keys.openGroup('go');
        case 'tour':
          _showAround();
      }
    });
  }

  @override
  void dispose() {
    _keys.dispose();
    _notes.dispose();
    super.dispose();
  }

  Project get _project => _projects[_open];

  void _newProject([String? name]) {
    setState(() {
      final n = _projects.length + 1;
      _projects.add(Project('project-$n', name ?? 'Project $n'));
      _open = _projects.length - 1;
    });
  }

  /// Plays a tour of the app: two cursors press, type and use the keys for
  /// real, with captions. Escape, or a click of your own, stops it.
  Future<void> _showAround() async {
    final end = await _keys.play(
      const KeyScript(
        cursors: [
          KeyCursor(
            id: 'ana',
            kind: KeyCursorKind.mouse,
            label: 'Ana',
            color: Color(0xFFE91E63),
          ),
          KeyCursor(
            id: 'ben',
            kind: KeyCursorKind.touch,
            label: 'Ben',
            color: Color(0xFF00897B),
          ),
        ],
        steps: [
          KeyStep.caption('A scripted tour: real presses and real typing'),
          KeyStep.tap('project-consulting'),
          KeyStep.tap('run'),
          KeyStep.caption('Shortcuts show as they are pressed'),
          KeyStep.keys('g p 1'),
          KeyStep.caption('Typing goes into the real field'),
          KeyStep.type('Send the invoice on Friday', at: 'notes'),
          KeyStep.caption('Two people at once'),
          KeyStep.together([
            KeyStep.point('rename', cursor: 'ana'),
            KeyStep.tap('project-blog', cursor: 'ben'),
          ]),
          KeyStep.caption('An agent runs a command with values'),
          KeyStep.run('file.add', args: {'name': 'Garden'}),
          KeyStep.wait(Duration(milliseconds: 800)),
        ],
      ),
    );
    setState(() => _status = 'The tour ${end.name}.');
  }

  Future<void> _rename() async {
    final context = _navigator.currentContext;
    if (context == null) return;
    final name = TextEditingController(text: _project.name);
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (text) => Navigator.pop(context, text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    if (saved != null && saved.trim().isNotEmpty) {
      setState(() => _project.name = saved.trim());
    }
  }

  /// What the whole app can do, wherever the focus is.
  List<KeyNode> get _appCommands => [
    KeyGroup(
      id: 'file',
      label: 'File',
      inMenuBar: true,
      children: [
        KeyCommand(
          id: 'new',
          label: 'New project',
          keys: const ['meta+n'],
          onRun: (_) => _newProject(),
        ),
        // Needs a name, which only code and agents give.
        KeyCommand(
          id: 'add',
          label: 'Add a project by name',
          params: const [KeyParam(name: 'name', description: 'Its name')],
          onRunWithArgs: (_, args) => _newProject(args.string('name')),
          hiddenFrom: const {
            KeySurface.menuBar,
            KeySurface.palette,
            KeySurface.helpSheet,
          },
        ),
      ],
    ),
    KeyGroup(
      id: 'help',
      label: 'Help',
      inMenuBar: true,
      children: [
        KeyCommand(
          id: 'tour',
          label: 'Show me around',
          description: 'Two cursors show what the app does',
          keys: const ['meta+shift+t'],
          enabled: !_keys.isPlaying,
          onRun: (_) => _showAround(),
          hiddenFrom: const {KeySurface.agents},
        ),
      ],
    ),
    KeyGroup(
      id: 'view',
      label: 'View',
      inMenuBar: true,
      children: [
        KeyCommand(
          id: 'sidebar',
          label: 'Sidebar',
          keys: const ['meta+b'],
          checked: _sidebar,
          onRun: (_) => setState(() => _sidebar = !_sidebar),
        ),
        KeyCommand(
          id: 'agents',
          label: 'What agents see',
          description: 'The commands in force, as an AI model gets them',
          keys: const ['meta+shift+a'],
          checked: _agentView,
          onRun: (_) => setState(() => _agentView = !_agentView),
        ),
        KeyCommand(
          id: 'vim',
          label: 'Vim keys',
          description: 'J and K move through the projects',
          checked: _vimKeys,
          onRun: (_) => setState(() => _vimKeys = !_vimKeys),
        ),
        const KeyDivider(),
        KeyCommand(
          id: 'palette',
          label: 'Search commands',
          onRun: (_) => _keys.showPalette(),
          hiddenFrom: const {KeySurface.palette, KeySurface.agents},
        ),
        KeyCommand(
          id: 'shortcuts',
          label: 'Keyboard shortcuts',
          onRun: (_) => _keys.showHelp(),
          hiddenFrom: const {KeySurface.palette, KeySurface.agents},
        ),
      ],
    ),
    KeyGroup(
      id: 'go',
      label: 'Go to',
      keys: const ['g'],
      children: [
        KeyGroup(
          id: 'project',
          label: 'Project',
          keys: const ['p'],
          children: [
            for (final (i, project) in _projects.indexed)
              KeyCommand(
                id: project.id,
                label: project.name,
                keys: [if (i < 9) '${i + 1}'],
                onRun: (_) => setState(() => _open = i),
              ),
          ],
        ),
        KeyCommand(
          id: 'notes',
          label: 'Notes',
          keys: const ['n'],
          onRun: (_) => _notes.requestFocus(),
        ),
      ],
    ),
  ];

  /// What the list of projects adds while the focus is in it.
  List<KeyNode> get _sidebarCommands => [
    KeyCommand(
      id: 'previous',
      label: 'Previous project',
      keys: const ['up'],
      enabled: _open > 0,
      onRun: (_) => setState(() => _open--),
    ),
    KeyCommand(
      id: 'next',
      label: 'Next project',
      keys: const ['down'],
      enabled: _open < _projects.length - 1,
      onRun: (_) => setState(() => _open++),
    ),
  ];

  /// What the open project adds while the focus is in it.
  List<KeyNode> get _projectCommands => [
    KeyCommand(
      id: 'run',
      label: 'Run',
      description: 'Starts the project',
      keys: const ['meta+r'],
      enabled: !_project.running,
      onRun: (_) => setState(() => _project.running = true),
    ),
    KeyCommand(
      id: 'stop',
      label: 'Stop',
      description: 'Stops the project',
      keys: const ['meta+.'],
      enabled: _project.running,
      onRun: (_) => setState(() => _project.running = false),
    ),
    KeyCommand(
      id: 'rename',
      label: 'Rename',
      keys: const ['f2'],
      onRun: (_) => _rename(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'key_flow example',
      navigatorKey: _navigator,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      builder: (context, child) => KeyFlow(
        controller: _keys,
        commands: _appCommands,
        // A demo: any script in the page may drive it.
        webBridge: 'keyFlow',
        keyOverrides: _vimKeys
            ? const {
                'next': ['j', 'down'],
                'previous': ['k', 'up'],
              }
            : const {},
        onCommandRun: (command) =>
            setState(() => _status = 'Ran ${command.path.join(' › ')}'),
        child: KeyFlowMenuBar(drawOnOtherPlatforms: true, child: child!),
      ),
      home: Scaffold(
        body: Row(
          children: [
            if (_sidebar) SizedBox(width: 240, child: _buildSidebar()),
            if (_sidebar) const VerticalDivider(width: 1),
            Expanded(child: _buildProject()),
            if (_agentView) const VerticalDivider(width: 1),
            if (_agentView) const SizedBox(width: 360, child: _AgentView()),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(child: Text(_status, textAlign: TextAlign.center)),
              Builder(
                builder: (context) => KeyHint(
                  command: 'help.tour',
                  child: TextButton(
                    onPressed: KeyFlow.of(
                      context,
                    ).callbackFor(context, 'help.tour'),
                    child: const Text('Show me around'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return KeyFlowScope(
      region: 'Projects',
      commands: _sidebarCommands,
      child: ListView(
        children: [
          for (final (i, project) in _projects.indexed)
            KeyAnchor(
              id: 'project-${project.id}',
              label: project.name,
              child: ListTile(
                title: Text(project.name),
                subtitle: Text(project.running ? 'Running' : 'Stopped'),
                selected: i == _open,
                onTap: () => setState(() => _open = i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProject() {
    return KeyFlowScope(
      region: 'Project',
      commands: _projectCommands,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Builder(
          builder: (context) {
            final keys = KeyFlow.of(context);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _project.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    // A control that is already a button: KeyHint names it.
                    KeyHint(
                      command: 'run',
                      child: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: keys.callbackFor(context, 'run'),
                      ),
                    ),
                    KeyHint(
                      command: 'stop',
                      child: IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: keys.callbackFor(context, 'stop'),
                      ),
                    ),
                    // A control drawn by hand: KeyTarget makes it one.
                    KeyTarget(
                      command: 'rename',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Rename'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(_project.running ? 'Running' : 'Stopped'),
                const SizedBox(height: 16),
                KeyAnchor(
                  id: 'notes',
                  label: 'Notes',
                  child: TextField(
                    focusNode: _notes,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Letters type here; ⌘ shortcuts still work.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The commands in force where the focus is, as an AI model is given them.
class _AgentView extends StatelessWidget {
  const _AgentView();

  @override
  Widget build(BuildContext context) {
    final keys = KeyFlow.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([keys, FocusManager.instance]),
      builder: (context, _) {
        final tools = keys.currentTree.toToolList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'What agents see: ${tools.length} tools',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SelectableText(
              const JsonEncoder.withIndent('  ').convert(tools),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}
