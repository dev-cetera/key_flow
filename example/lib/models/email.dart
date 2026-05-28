class Email {
  final String sender;
  final String subject;
  final String preview;
  final DateTime timestamp;
  final bool isRead;

  Email({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.timestamp,
    this.isRead = false,
  });
}
