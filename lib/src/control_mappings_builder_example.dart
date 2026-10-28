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

class ControlMappingsBuilderExample extends StatelessWidget {
  //
  //
  //

  final List<KeyFlowControl> controls;

  //
  //
  //

  const ControlMappingsBuilderExample({
    super.key,
    required this.controls,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return ControlMappingsBuilder(
      controls: controls,
      builder: (context, mappings, child) {
        return SizedBox(
          height: 100,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in mappings.entries)
                    Container(
                      color: Colors.blue,
                      child: Builder(
                        builder: (context) {
                          final key = entry.key;
                          final description = key is DescriptiveKey
                              ? key.description(context)
                              : key.toString();
                          return Text(
                            '[${entry.value.map((e) => e.debugName).join(', ')}] $description',
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
