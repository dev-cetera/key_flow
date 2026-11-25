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

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'key_flow_web_bridge.dart';

/// Puts [bridge] on `window` as [name]; returns what takes it off again.
void Function() openWebBridge(KeyFlowWebBridge bridge, String name) {
  final api = JSObject();
  api['help'] = (() => bridge.help(name).toJS).toJS;
  api['commands'] = (() => bridge.commands().jsify()).toJS;
  api['tools'] = (() => bridge.tools().jsify()).toJS;
  api['spots'] = (() => bridge.spots().jsify()).toJS;
  api['run'] = ((JSString id, JSAny? args) {
    return _promise(() async {
      await bridge.run(id.toDart, args.dartify());
      return null;
    });
  }).toJS;
  api['runTool'] = ((JSString tool, JSAny? args) {
    return _promise(() async {
      await bridge.runTool(tool.toDart, args.dartify());
      return null;
    });
  }).toJS;
  api['play'] = ((JSAny? script) {
    return _promise(() async => (await bridge.play(script.dartify())).toJS);
  }).toJS;
  api['stop'] = bridge.stop.toJS;
  globalContext[name] = api;
  return () {
    if (identical(globalContext[name], api)) globalContext.delete(name.toJS);
  };
}

/// Runs [body] as a promise that rejects with an `Error` whose message says
/// what went wrong, which a browser agent can read. (`Future.toJS` rejects
/// with a generic message and the Dart error boxed out of reach.)
JSPromise<JSAny?> _promise(Future<JSAny?> Function() body) {
  return JSPromise<JSAny?>(
    (JSFunction resolve, JSFunction reject) {
      Future.sync(body).then(
        (value) {
          resolve.callAsFunction(null, value);
        },
        onError: (Object error) {
          final errorType = globalContext['Error']! as JSFunction;
          reject.callAsFunction(
            null,
            errorType.callAsConstructor<JSObject>('$error'.toJS),
          );
        },
      );
    }.toJS,
  );
}
