/// A single SMS message in a lead's conversation thread.
class Message {
  final String id;
  final String leadId;
  final MessageDirection direction;
  final String body;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.leadId,
    required this.direction,
    required this.body,
    required this.sentAt,
  });

  bool get isOutbound => direction == MessageDirection.outbound;
  bool get isInbound => direction == MessageDirection.inbound;
}

enum MessageDirection {
  inbound,
  outbound;

  static MessageDirection fromString(String s) {
    return s == 'outbound' ? outbound : inbound;
  }
}
