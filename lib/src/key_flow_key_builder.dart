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

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A widget that extracts the String representation (the "name") of a
/// [mappingKey] passes this information to it's [builder].
class KeyFlowKeyNameBuilder<TKey extends Key> extends StatelessWidget {
  //
  //
  //

  final TKey mappingKey;
  final Widget Function(BuildContext context, String name, Widget? child) builder;
  final Widget? child;

  //
  //
  //

  const KeyFlowKeyNameBuilder({
    super.key,
    required this.mappingKey,
    required this.builder,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final name = mappingKey is DescriptiveKey
        ? (mappingKey as DescriptiveKey).description(context)
        : mappingKey.toString();
    return builder(context, name, child);
  }
}
