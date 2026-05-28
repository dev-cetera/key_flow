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

import 'package:df_pod/df_pod.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A widget that provides access to the nearest [TMappingsMap] up the widget
/// tree via its [builder], or via [control] if provided.
class KeyFlowMappingsBuilder extends StatelessWidget {
  //
  //
  //

  final KeyFlowControl? control;
  final ValueWidgetBuilder<KeyFlowControl> builder;
  final Widget? child;

  //
  //
  //

  const KeyFlowMappingsBuilder({
    super.key,
    this.control,
    required this.builder,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    var test = control;
    if (test == null) {
      final scope = KeyFlowScope.of(context);
      assert(scope != null);
      if (scope == null) {
        return const SizedBox.shrink();
      }
      test = scope.control;
    }
    assert(test != null);
    if (test == null) {
      return const SizedBox.shrink();
    }
    return PodBuilder<TMappingsMap>(
      pod: test.mappingsNotifier,
      builder: (context, snapshot) => builder(context, test!, child),
      child: child,
    );
  }
}
