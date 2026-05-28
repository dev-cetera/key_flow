import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Example3()));
}
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Example3 extends StatefulWidget {
  const Example3({super.key});

  @override
  State<Example3> createState() => _Example2State();
}

class _Example2State extends State<Example3> {
  // Tab row list
  List<String> tabsList = ['All', 'Read', 'Spam'];
  int selectedIndex = -1; // Track selected tab index

  // Focus list for tabs
  List<FocusNode> tabFocusList = [];

  @override
  void initState() {
    super.initState();
    tabFocusList = List.generate(tabsList.length, (index) => FocusNode());
  }

  // Key Mappings
  var key1 = const ValueKey('key1');
  var key2 = const ValueKey('key2');
  var key3 = const ValueKey('key3');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example 2'), centerTitle: true),
      body: KeyFlowFocus(
        autofocus: true,
        control: KeyFlowControl(
          mappings: {
            key1: [const LogicalKeyActivator(LogicalKeyboardKey.digit1)],
            key2: [const LogicalKeyActivator(LogicalKeyboardKey.digit2)],
            key3: [const LogicalKeyActivator(LogicalKeyboardKey.digit3)],
          },
          callbacks: {
            key1: (c, context) {
              FocusScope.of(c).requestFocus(tabFocusList[0]);
              setState(() {});
            },
            key2: (c, context) {
              FocusScope.of(c).requestFocus(tabFocusList[1]);
              setState(() {});
            },
            key3: (c, context) {
              FocusScope.of(c).requestFocus(tabFocusList[2]);
              setState(() {});
            },
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Text('Press digit Key 1, Key 2, Key 3 to switch between these tabs'),
              Row(
                children:
                    tabsList.asMap().entries.map((entry) {
                      var index = entry.key;
                      var label = entry.value;

                      return Focus(
                        autofocus: true,
                        focusNode: tabFocusList[index],
                        onFocusChange: (focus) => setState(() {}),
                        child: Container(
                          margin: const EdgeInsets.only(left: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: getTabColor(index),
                            border: Border.all(width: 1.0, color: getTabBorderColor(index)),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: getTabTextColor(index),
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              // Show AllView for the selected tab
              selectedIndex >= 0
                  ? Expanded(child: AllView(label: tabsList[selectedIndex]))
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  // to get the highlight colors
  Color getTabColor(int index) => tabFocusList[index].hasFocus ? Colors.blueAccent : Colors.white;

  Color getTabBorderColor(int index) =>
      tabFocusList[index].hasFocus ? Colors.white : const Color(0xffD1D1D1);

  Color getTabTextColor(int index) => tabFocusList[index].hasFocus ? Colors.white : Colors.grey;
}

// Dummy view
class AllView extends StatelessWidget {
  final String label;

  const AllView({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _getBackgroundColor(label),
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _getBackgroundColor(String label) {
    switch (label) {
      case 'All':
        return Colors.blue.shade100;
      case 'Read':
        return Colors.green.shade100;
      case 'Spam':
        return Colors.red.shade100;
      default:
        return Colors.white;
    }
  }
}
