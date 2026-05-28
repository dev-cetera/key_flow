import 'package:flutter/material.dart';
import 'package:key_flow/key_flow.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: Example4()));
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class Example4 extends StatefulWidget {
  const Example4({super.key});

  @override
  State<Example4> createState() => _Example3State();
}

class _Example3State extends State<Example4> {
  // Tabs row list
  List<String> tabsList = ['All', 'Read', 'Spam'];
  int selectedIndex = -1; // Track selected tab index
  // Focus list for tabs
  List<FocusNode> tabFocusList = [];


  // to track the focus
  bool isTabFocused = true;
  // pages list
  List<String> pageList = ['Create New', 'Draft'];
  // Focus list for pages
  List<FocusNode> pageFocusList = [];

  @override
  void initState() {
    super.initState();
    tabFocusList = List.generate(tabsList.length, (index) => FocusNode());
    pageFocusList = List.generate(pageList.length, (index) => FocusNode());
  }

  // Key Mappings
  var key1 = const ValueKey('key1');
  var key2 = const ValueKey('key2');
  var key3 = const ValueKey('key3');
  var shiftFocusKey = const ValueKey('ShiftFocusKey');

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
            // Shift + S to shift focus between widgets.
            shiftFocusKey: [
              const LogicalKeyActivator(
                LogicalKeyboardKey.keyS,
                shift: true,
              ),
            ],
          },
          callbacks: {
            key1: (c, context) {
              if (isTabFocused) {
                FocusScope.of(c).requestFocus(tabFocusList[0]);
              } else {
                if (selectedIndex == -1) {
                  return;
                }
                FocusScope.of(c).requestFocus(pageFocusList[0]);
              }
              setState(() {});
            },
            key2: (c, context) {
              if (isTabFocused) {
                FocusScope.of(c).requestFocus(tabFocusList[1]);
              } else {
                FocusScope.of(c).requestFocus(pageFocusList[1]);
              }
              setState(() {});
            },
            key3: (c, context) {
              if (isTabFocused) {
                FocusScope.of(c).requestFocus(tabFocusList[2]);
              } else {
                FocusScope.of(c).requestFocus(pageFocusList[2]);
              }
              setState(() {});
            },
            shiftFocusKey: (c, context) {
              isTabFocused = !isTabFocused;
              if (isTabFocused) {
                FocusScope.of(c).requestFocus(tabFocusList[0]);
              } else {
                FocusScope.of(c).requestFocus(pageFocusList[0]);
              }
              ScaffoldMessenger.of(c).showSnackBar(
                const SnackBar(content: Text('Focus is shift'), duration: Duration(seconds: 1)),
              );
              setState(() {});
            },
          },
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Text(
                'Press digit Key 1, Key 2, Key 3 to switch between these tabs and press ( Shift + S) to shift focus between these widgets',
              ),
              Row(
                children:
                    tabsList.asMap().entries.map((entry) {
                      var index = entry.key;
                      var label = entry.value;
                      return Focus(
                        autofocus: true,
                        focusNode: tabFocusList[index],
                        onFocusChange:
                            (focus) => setState(() {
                              selectedIndex = index;
                            }),
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
              // Show dummy email view for the selected tab
              selectedIndex >= 0
                  ? Expanded(
                    child: EmailListScreen(
                      emails:
                          selectedIndex == 0
                              ? emails
                              : selectedIndex == 1
                              ? emails.where((e) => e.isRead).toList()
                              : emails.where((e) => e.isSpam).toList(),
                    ),
                  )
                  : const SizedBox(),
              const SizedBox(height: 24),
              // bottom view
              selectedIndex >= 0
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ...pageList.map((e) {
                            var index = pageList.indexOf(e);
                            return Focus(
                              focusNode: pageFocusList[index],
                              onFocusChange: (focus) {
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: getPageColor(index),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Center(
                                  child: Text(
                                    e.toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          pageFocusList[index].hasFocus
                                              ? Colors.white
                                              : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Press digit Keys 1,2, to switch between these tabs'),
                    ],
                  )
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

  Color getPageColor(int index) =>
      pageFocusList[index].hasFocus ? Colors.blueAccent : Colors.grey.withAlpha(50);
}

// dummy email ListView view
class EmailListScreen extends StatefulWidget {
  final List<Email> emails;

  const EmailListScreen({super.key, required this.emails});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  List<FocusNode> focusList = [];

  @override
  void initState() {
    super.initState();
    focusList = List.generate(widget.emails.length, (i) => FocusNode());
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.emails.length,
      itemBuilder: (context, index) {
        final email = widget.emails[index];
        return EmailTile(email: email, focusNode: focusList[index]);
      },
    );
  }
}

// email tile widget UI
class EmailTile extends StatefulWidget {
  final Email email;
  final FocusNode focusNode;

  const EmailTile({super.key, required this.email, required this.focusNode});

  @override
  State<EmailTile> createState() => _EmailTileState();
}

class _EmailTileState extends State<EmailTile> {
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focus) {
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 8, top: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            width: 1.0,
            color: widget.focusNode.hasFocus ? Colors.blueAccent : const Color(0xFFD1D1D1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              widget.email.isRead ? Icons.mail_outline : Icons.mail,
              color: widget.email.isRead ? Colors.grey : Colors.blue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.email.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.email.isRead ? Colors.black54 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.email.isSpam)
                  const Row(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Spam', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                Text(
                  DateFormat('MMM d, h:mm a').format(widget.email.dateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// dummy emails list
final List<Email> emails = [
  Email(
    isRead: false,
    title: 'Meeting Reminder',
    content: "Don't forget our meeting at 10 AM.",
    dateTime: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  Email(
    isRead: true,
    title: 'Project Update',
    content: 'The latest project updates are attached.',
    dateTime: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Email(
    isRead: false,
    title: 'New Event Invitation',
    content: "You're invited to our annual event!",
    dateTime: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Email(
    isRead: true,
    title: 'Newsletter',
    content: 'Check out our latest newsletter.',
    dateTime: DateTime.now().subtract(const Duration(days: 5)),
  ),
  Email(
    isRead: true,
    isSpam: true,
    title: 'Suspicious Offer',
    content: "You've won a million dollars! Click here.",
    dateTime: DateTime.now().subtract(const Duration(days: 3)),
  ),
];


class Email {
  final bool isRead;
  final bool isSpam;
  final String title;
  final String content;
  final DateTime dateTime;

  Email({
    required this.isRead,
    required this.title,
    required this.content,
    required this.dateTime,
    this.isSpam = false,
  });
}
