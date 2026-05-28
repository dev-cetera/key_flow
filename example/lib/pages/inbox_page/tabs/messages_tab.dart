import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _MessagesTabState extends State<MessagesTab> {
  int _selectedIndex = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyFlowFocus(
      autofocus: true,
      control: MessagesControl().merge(
        callbacks: {
          NextMessageAction(): (context, _) {
            if (_selectedIndex < mockEmails.length - 1) {
              setState(() {
                _selectedIndex++;
              });
              _scrollToSelected();
            } else {
              // Already at the last email — escape focus downward.
              FocusManager.instance.primaryFocus?.focusInDirection(
                TraversalDirection.down,
              );
            }
          },
          PreviousMessageAction(): (context, _) {
            if (_selectedIndex > 0) {
              setState(() {
                _selectedIndex--;
              });
              _scrollToSelected();
            } else {
              // Already at the first email — escape focus upward into
              // the tab bar.
              FocusManager.instance.primaryFocus?.focusInDirection(
                TraversalDirection.up,
              );
            }
          },
          OpenMessage1Action(): (context, _) {
            final email = mockEmails[_selectedIndex];
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Opening (1): ${email.subject}')));
          },
          OpenMessage2Action(): (context, _) {
            final email = mockEmails[_selectedIndex];
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Opening (2): ${email.subject}')));
          },
          DeleteMessageAction(): (context, registry) {
            Email? deleted;
            setState(() {
              deleted = mockEmails.removeAt(_selectedIndex);
            });
            registry.call(context, PreviousMessageAction());
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Deleting: ${deleted?.subject}')));
          },
        },
      ),
      child: FocusHighlighter(
        child: ListView.builder(
          controller: _scrollController,
          itemCount: mockEmails.length,
          itemBuilder: (context, index) {
            final email = mockEmails[index];
            final isSelected = index == _selectedIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  ),
                ),
                child: Row(
                  spacing: 20.0,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Text(email.sender[0].toUpperCase())),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          spacing: 4.0,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              email.sender,
                              style: TextStyle(
                                fontWeight:
                                    email.isRead && !isSelected
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                            Text(
                              email.subject,
                              style: TextStyle(
                                fontWeight:
                                    email.isRead && !isSelected
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                            Text(
                              email.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      _formatTimestamp(email.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _scrollToSelected() {
    // Estimate the item height (adjust this based on your ListTile height)
    const itemHeight = 72.0; // Typical ListTile height, tweak as needed
    final targetOffset = _selectedIndex * itemHeight;

    // Ensure the target offset is within bounds
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final scrollOffset = targetOffset.clamp(0.0, maxScrollExtent);

    // Animate to the selected item, centering it where possible
    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }
}

final List<Email> mockEmails = List.generate(
  20,
  (index) => Email(
    sender: 'sender$index@example.com',
    subject: 'Subject Line $index',
    preview: 'This is a preview of email $index...',
    timestamp: DateTime.now().subtract(Duration(hours: index * 2)),
    isRead: index % 3 != 0,
  ),
);
