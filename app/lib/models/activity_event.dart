/// Activity event model — used in the dashboard activity feed.
enum ActivityType {
  newLead,
  smsSent,
  bookingConfirmed,
  dnrAlert,
  leadCompleted,
  satisfactionReceived,
  revenueUpdated,
  costAdded,
}

class ActivityEvent {
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final String? leadId;

  const ActivityEvent({
    required this.type,
    required this.description,
    required this.timestamp,
    this.leadId,
  });

  /// Icon and color mapping for each event type.
  String get emoji {
    switch (type) {
      case ActivityType.newLead: return '🟢';
      case ActivityType.smsSent: return '💬';
      case ActivityType.bookingConfirmed: return '📅';
      case ActivityType.dnrAlert: return '⚠️';
      case ActivityType.leadCompleted: return '✅';
      case ActivityType.satisfactionReceived: return '⭐';
      case ActivityType.revenueUpdated: return '💰';
      case ActivityType.costAdded: return '🧾';
    }
  }
}
