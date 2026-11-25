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

import 'dart:convert';

import '/key_flow.dart';
import '_web_bridge_stub.dart'
    if (dart.library.js_interop) '_web_bridge_web.dart'
    as platform;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// What [KeyFlow.webBridge] puts on `window` on the web, so a browser agent
/// (such as Claude in Chrome) or a person at the console can drive the app by
/// its commands and anchors instead of guessing at pixels:
///
/// ```js
/// keyFlow.help()                       // this list, as text
/// keyFlow.commands()                   // what can run here: ids, labels, keys
/// keyFlow.tools()                      // the same as model tool definitions
/// keyFlow.spots()                      // anchors on screen: place, label, rect
/// await keyFlow.run('go.inbox')        // runs a command, with args if any
/// await keyFlow.runTool('add', {text: 'Milk'})
/// await keyFlow.play({steps: [{do: 'tap', at: 'add'}]})  // 'finished'
/// keyFlow.stop()                       // stops a playing script
/// await keyFlow.record()               // writes down what happens next
/// await keyFlow.note('Tick things off')  // a caption in the recording
/// await keyFlow.stopRecording()        // {script, misses}
/// ```
///
/// Scripts and args are given as objects or JSON text. A failure rejects the
/// promise with an Error saying what went wrong.
final class KeyFlowWebBridge {
  /// The controller it drives.
  final KeyFlowController controller;

  KeyFlowWebBridge(this.controller);

  /// Puts a bridge to [controller] on `window` as [name], on the web; does
  /// nothing elsewhere. Returns what takes it away again.
  static VoidCallback open(
    KeyFlowController controller, {
    required String name,
  }) {
    return platform.openWebBridge(KeyFlowWebBridge(controller), name);
  }

  /// How to use it.
  String help(String name) {
    return [
      '$name.commands()  what can run here (id, label, keys, params)',
      '$name.tools()  the same as model tool definitions',
      '$name.spots()  anchors on screen (place, label, rect, reachable)',
      '$name.run(id, args?)  runs a command; resolves when done',
      '$name.runTool(name, args?)  runs a tool from tools()',
      '$name.play(script)  plays a script; resolves "finished" or "stopped"',
      '$name.stop()  stops a playing script',
      '$name.record()  starts recording presses, keys, typing, commands and '
          'played steps',
      '$name.note(text)  adds a caption to the recording',
      '$name.recording()  the recording so far: {script, misses}, or null',
      '$name.stopRecording()  stops it; returns {script, misses}, the script '
          'ready for play()',
      'A script: {cursors?: [{id, kind: "mouse"|"touch", label?, color?}], '
          'speed?: 1, steps: [...]}',
      'Steps: {do: "point"|"tap", at}, {do: "hold", at, ms?}, '
          '{do: "drag", at, to | by: [dx, dy], holdMs?}, '
          '{do: "type", text, at?, submit?}, {do: "keys", keys: "meta+k"}, '
          '{do: "run", command, args?}, {do: "caption", text}, '
          '{do: "wait", ms}, {do: "waitFor", at, ms?}, '
          '{do: "scrollTo", at, within}, '
          '{do: "together", steps}; each acting step takes cursor?',
      'A place ("at"): an anchor id from spots(), "row-2/tick" for the one '
          'inside "row-2", or "tick[1]" for the second in reading order',
    ].join('\n');
  }

  /// What can run here; see [KeyTree.toCommandList].
  List<Map<String, Object?>> commands() {
    return controller.currentTree.toCommandList();
  }

  /// The commands as tool definitions; see [KeyTree.toToolList].
  List<Map<String, Object?>> tools() => controller.currentTree.toToolList();

  /// The anchors on screen; see [KeyFlowController.spots].
  List<Map<String, Object?>> spots() {
    return [for (final spot in controller.spots) spot.toJson()];
  }

  /// Runs a command; see [KeyFlowController.run].
  Future<void> run(String id, Object? args) {
    return controller.run(id, args: _args(args));
  }

  /// Runs a tool; see [KeyFlowController.runTool].
  Future<void> runTool(String name, Object? args) {
    return controller.runTool(name, args: _args(args));
  }

  /// Plays a script given as an object or JSON text, and says how it ended.
  Future<String> play(Object? script) async {
    final parsed = switch (script) {
      String() => KeyScript.parse(script),
      Map() => KeyScript.fromJson(_map(script, 'a script')),
      _ => throw FormatException('Expected a script', script),
    };
    final end = await controller.play(parsed);
    return end.name;
  }

  /// Stops a playing script.
  void stop() => controller.stopPlaying();

  /// Starts a recording; see [KeyFlowController.startRecording].
  void record() => controller.startRecording();

  /// Adds a caption to the recording running.
  void note(String text) {
    final recording = controller.recording;
    if (recording == null) throw StateError('No recording is running');
    recording.note(text);
  }

  /// The recording running, as plain data, or null.
  Map<String, Object?>? recording() => controller.recording?.toJson();

  /// Stops the recording and returns it as plain data.
  Map<String, Object?> stopRecording() {
    return controller.stopRecording().toJson();
  }

  static Map<String, Object?> _args(Object? args) {
    return switch (args) {
      null => const {},
      String() => _map(jsonDecode(args), 'args'),
      Map() => _map(args, 'args'),
      _ => throw FormatException('Expected args as an object', args),
    };
  }

  static Map<String, Object?> _map(Object? value, String what) {
    if (value is! Map) throw FormatException('Expected $what as an object');
    return {for (final MapEntry(:key, :value) in value.entries) '$key': value};
  }
}
