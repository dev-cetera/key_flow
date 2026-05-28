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

class ControlMappingsBuilder extends StatelessWidget {
  //
  //
  //

  final Widget? child;
  final List<KeyFlowControl> controls;
  final ValueWidgetBuilder<Map<Key, List<KeyActivator>>> builder;

  //
  //
  //

  const ControlMappingsBuilder({
    super.key,
    required this.controls,
    required this.builder,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return PodListBuilder(
      podList: controls.map((e) => e.mappingsNotifier),
      builder: (context, snapshot) {
        // FocusManager.instance is a ChangeNotifier that fires on every
        // focus tree change. Without listening to it, this builder only
        // rebuilds when a mappingsNotifier changes — which means initial
        // build runs *before* autofocus has settled, every control reports
        // hasFocus == false, and the panel stays empty forever.
        return ListenableBuilder(
          listenable: FocusManager.instance,
          builder: (context, _) {
            final withFocus = controls
                .where((e) => e.focusNode?.hasFocus == true)
                .toList();
            final combined = <Key, List<KeyActivator>>{};
            for (final e in withFocus) {
              for (final entry in e.mappings.entries) {
                combined[entry.key] = entry.value;
              }
            }
            return builder(context, combined, snapshot.child);
          },
        );
      },
      child: child,
    );
  }
}
