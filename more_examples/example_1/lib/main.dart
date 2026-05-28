import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

final showSnackbarAction = UniqueKey();

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        // --- PARENT ---
        body: KeyFlowFocus(
          autofocus: true,
          control: KeyFlowControl(
            mappings: {
              showSnackbarAction: [
                const LogicalKeyActivator(LogicalKeyboardKey.space),
              ],
            },
            callbacks: {
              showSnackbarAction: (context, registry) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You pressed D (BIG)!!!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            },
          ),
          child: Column(
            children: [
              const Text('PRESS SPACEBAR TO SHOW SNACKBAR'),
              const Text('PRESS TAB TO CHANGE FOCUS'),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  FocusBuilder(
                    hasFocusBuilder: (context, child) {
                      return Container(
                        color: Colors.amber,
                        padding: const EdgeInsets.all(60.0),
                        child: child,
                      );
                    },
                    hasNoFocusBuilder: (context, child) {
                      return Container(
                        color: Colors.grey,
                        padding: const EdgeInsets.all(60.0),
                        child: child,
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        return Text('BIG!!!', style: Theme.of(context).textTheme.labelMedium);
                      },
                    ),
                  ),
                  // --- CHILD ---
                  KeyFlowFocus(
                    control: KeyFlowControl(
                      callbacks: {
                        showSnackbarAction: (context, registry) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You pressed D (SMALL)!!!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      },
                    ),
                    child: FocusBuilder(
                      hasFocusBuilder: (context, child) {
                        return Container(
                          color: Colors.amber.shade800,
                          padding: const EdgeInsets.all(20.0),
                          child: child,
                        );
                      },
                      hasNoFocusBuilder: (context, child) {
                        return Container(
                          color: Colors.grey.shade800,
                          padding: const EdgeInsets.all(20.0),
                          child: child,
                        );
                      },
                      child: Builder(
                        builder: (context) {
                          return Text('SMALL!!!', style: Theme.of(context).textTheme.labelMedium);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
