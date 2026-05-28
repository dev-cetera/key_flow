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

import 'package:flutter/material.dart';

import '/key_flow.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class KeyMapExample extends StatelessWidget {
  //
  //
  //

  final KeyFlowControl? control;

  //
  //
  //

  const KeyMapExample({
    super.key,
    this.control,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return KeyFlowMappingsBuilder(
      control: control,
      builder: (context, control, child) {
        final items = control.mappings.entries.toList();
        final style = Theme.of(context).textTheme.bodyLarge;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final key = item.key;
            final debugName = item.value.debugName;
            return Card(
              child: KeyFlowKeyNameBuilder(
                mappingKey: key,
                builder: (context, name, child) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      children: [
                        Text(
                          '$debugName: ',
                          style: style?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          name,
                          style: style,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
