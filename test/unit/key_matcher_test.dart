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

import 'package:flutter_test/flutter_test.dart';
import 'package:key_flow/key_flow.dart';

void _noop(BuildContext context) {}

KeyStroke key(LogicalKeyboardKey logical, {bool control = false}) {
  return KeyStroke(
    logical: logical,
    physical: PhysicalKeyboardKey.keyA,
    control: control,
    character: logical.keyLabel.length == 1 && !control
        ? logical.keyLabel.toLowerCase()
        : null,
  );
}

final g = key(LogicalKeyboardKey.keyG);
final p = key(LogicalKeyboardKey.keyP);
final s = key(LogicalKeyboardKey.keyS);
final i = key(LogicalKeyboardKey.keyI);
final x = key(LogicalKeyboardKey.keyX);
final escape = key(LogicalKeyboardKey.escape);
final backspace = key(LogicalKeyboardKey.backspace);

KeyTree tree([List<KeyLayer>? extra]) {
  return KeyTree.merge([
    const KeyLayer([
      KeyCommand(id: 'top', label: 'Top', keys: ['t t'], onRun: _noop),
      KeyGroup(
        id: 'go',
        label: 'Go to',
        keys: ['g'],
        children: [
          KeyCommand(id: 'inbox', label: 'Inbox', keys: ['i'], onRun: _noop),
          KeyGroup(
            id: 'projects',
            label: 'Projects',
            keys: ['p'],
            children: [
              KeyCommand(
                id: 'settings',
                label: 'Settings',
                keys: ['s'],
                onRun: _noop,
              ),
            ],
          ),
          KeyCommand(
            id: 'off',
            label: 'Off',
            keys: ['o'],
            enabled: false,
            onRun: _noop,
          ),
        ],
      ),
      KeyCommand(id: 'down', label: 'Down', keys: ['j'], onRun: _noop),
    ]),
    ...?extra,
  ]);
}

void main() {
  test('G P S walks into nested groups and runs the command', () {
    final t = tree();
    final m = KeyMatcher();
    expect(m.handle(g, t), isA<KeyMatchOpened>());
    expect(m.position.path, ['Go to']);
    expect(m.handle(p, t), isA<KeyMatchOpened>());
    expect(m.position.path, ['Go to', 'Projects']);
    final run = m.handle(s, t);
    expect(run, isA<KeyMatchRun>());
    expect((run as KeyMatchRun).command.id, 'go.projects.settings');
    expect(m.position.isOpen, isFalse);
  });

  test('an open group waits as long as it takes, through unknown keys', () {
    final t = tree();
    final m = KeyMatcher()..handle(g, t);
    expect(m.handle(x, t), isA<KeyMatchWaiting>());
    expect(m.handle(x, t).handled, isTrue, reason: 'a slip types nothing');
    expect(m.position.path, ['Go to']);
    expect(m.handle(i, t), isA<KeyMatchRun>());
  });

  test('nextIn lists what to press next', () {
    final t = tree();
    final m = KeyMatcher()..handle(g, t);
    final next = m.position.nextIn(t);
    expect(next.map((n) => n.item.label), ['Inbox', 'Projects', 'Off']);
    expect(next.map((n) => n.remaining.toSpec()), ['i', 'p', 'o']);
  });

  test('Escape closes; Backspace goes up a level', () {
    final t = tree();
    final m = KeyMatcher()
      ..handle(g, t)
      ..handle(p, t);
    expect(m.handle(backspace, t), isA<KeyMatchWaiting>());
    expect(m.position.path, ['Go to']);
    expect(m.handle(backspace, t), isA<KeyMatchClosed>());
    expect(m.position.isOpen, isFalse);
    m.handle(g, t);
    expect(m.handle(escape, t), isA<KeyMatchClosed>());
    expect(m.position.isOpen, isFalse);
  });

  test('a binding of two keys waits after the first', () {
    final t = tree();
    final m = KeyMatcher();
    final tKey = key(LogicalKeyboardKey.keyT);
    expect(m.handle(tKey, t), isA<KeyMatchWaiting>());
    expect(m.position.pending, hasLength(1));
    expect(m.position.nextIn(t).single.remaining.toSpec(), 't');
    expect(m.handle(backspace, t), isA<KeyMatchWaiting>());
    expect(m.position.pending, isEmpty);
    m.handle(tKey, t);
    expect(m.handle(tKey, t), isA<KeyMatchRun>());
  });

  test('a disabled command does nothing, and stays out of the way', () {
    final t = tree();
    final m = KeyMatcher()..handle(g, t);
    expect(m.handle(key(LogicalKeyboardKey.keyO), t), isA<KeyMatchWaiting>());
    expect(m.position.path, ['Go to']);
  });

  test('a key that is no shortcut at the top is left to the app', () {
    expect(KeyMatcher().handle(x, tree()), isA<KeyMatchIgnored>());
  });

  test('typing in a text field leaves its keys alone', () {
    final t = tree();
    final m = KeyMatcher();
    expect(m.handle(g, t, inTextField: true), isA<KeyMatchIgnored>());
    expect(
      m.handle(key(LogicalKeyboardKey.arrowLeft), t, inTextField: true),
      isA<KeyMatchIgnored>(),
    );
  });

  test('held keys repeat a one-key command only', () {
    final t = tree();
    final m = KeyMatcher();
    expect(
      m.handle(key(LogicalKeyboardKey.keyJ), t, isRepeat: true),
      isA<KeyMatchRun>(),
    );
    expect(m.handle(g, t, isRepeat: true), isA<KeyMatchIgnored>());
  });

  test('the nearer scope wins the same keys', () {
    final t = tree([
      const KeyLayer([
        KeyCommand(id: 'near', label: 'Near', keys: ['j'], onRun: _noop),
      ]),
    ]);
    final run = KeyMatcher().handle(key(LogicalKeyboardKey.keyJ), t);
    expect((run as KeyMatchRun).command.id, 'near');
  });
}
