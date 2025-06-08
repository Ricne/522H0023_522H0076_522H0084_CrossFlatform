class Reply {
  final String body;
  final String from;
  final String subject;
  final String time;
  final String to;
  final String attachments;

  Reply({
    required this.body,
    required this.from,
    required this.subject,
    required this.time,
    required this.to,
    this.attachments = '',
  });
}
