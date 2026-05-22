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

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      direction: MessageDirection.fromString(json['direction'] as String? ?? 'inbound'),
      body: json['body'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'direction': direction.name,
      'body': body,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}

enum MessageDirection {
  inbound,
  outbound;

  static MessageDirection fromString(String s) {
    return s == 'outbound' ? outbound : inbound;
  }
}
