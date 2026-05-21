/// Lead status progression:
/// missed → consent_sent → opted_in → qualifying → booking_sent → booked → completed → followed_up
/// Side branches: dnr_alert, no_consent
enum LeadStatus {
  missed,
  consentSent,
  optedIn,
  qualifying,
  bookingSent,
  booked,
  completed,
  followedUp,
  dnrAlert,
  noConsent;

  String get value {
    switch (this) {
      case missed: return 'missed';
      case consentSent: return 'consent_sent';
      case optedIn: return 'opted_in';
      case qualifying: return 'qualifying';
      case bookingSent: return 'booking_sent';
      case booked: return 'booked';
      case completed: return 'completed';
      case followedUp: return 'followed_up';
      case dnrAlert: return 'dnr_alert';
      case noConsent: return 'no_consent';
    }
  }

  static LeadStatus fromString(String s) {
    switch (s) {
      case 'missed': return missed;
      case 'consent_sent': return consentSent;
      case 'opted_in': return optedIn;
      case 'qualifying': return qualifying;
      case 'booking_sent': return bookingSent;
      case 'booked': return booked;
      case 'completed': return completed;
      case 'followed_up': return followedUp;
      case 'dnr_alert': return dnrAlert;
      case 'no_consent': return noConsent;
      default: return missed;
    }
  }

  /// Pipeline stage index (0-4). Returns -1 for no_consent.
  int get pipelineStage {
    switch (this) {
      case missed:
      case consentSent:
        return 0;
      case optedIn:
      case qualifying:
      case bookingSent:
      case dnrAlert:
        return 1;
      case booked:
        return 2;
      case completed:
        return 3;
      case followedUp:
        return 4;
      case noConsent:
        return -1;
    }
  }

  /// Which filter category this status belongs to.
  String get filterCategory {
    switch (this) {
      case missed:
      case consentSent:
        return 'missed';
      case optedIn:
      case qualifying:
      case bookingSent:
      case dnrAlert:
        return 'contacted';
      case booked:
        return 'booked';
      case completed:
      case followedUp:
        return 'completed';
      case noConsent:
        return 'missed';
    }
  }
}

enum Urgency {
  unknown,
  low,
  medium,
  high,
  emergency;

  static Urgency fromString(String s) {
    switch (s) {
      case 'low': return low;
      case 'medium': return medium;
      case 'high': return high;
      case 'emergency': return emergency;
      default: return unknown;
    }
  }
}

class Lead {
  final String id;
  final String contractorId;
  final String callerPhone;
  final String? callerName;
  final String? issueDescription;
  final Urgency urgency;
  final LeadStatus status;
  final bool consentGiven;
  final DateTime? consentGivenAt;
  final int callCount;
  final double? estimatedValue;
  final DateTime? bookingTime;
  final String? calendlyEventId;
  final bool dnrAlertSent;
  final DateTime? dnrAlertSentAt;
  final int? satisfactionScore;
  final String? satisfactionFeedback;
  final bool calledDuringAfterHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Lead({
    required this.id,
    required this.contractorId,
    required this.callerPhone,
    this.callerName,
    this.issueDescription,
    this.urgency = Urgency.unknown,
    this.status = LeadStatus.missed,
    this.consentGiven = false,
    this.consentGivenAt,
    this.callCount = 1,
    this.estimatedValue,
    this.bookingTime,
    this.calendlyEventId,
    this.dnrAlertSent = false,
    this.dnrAlertSentAt,
    this.satisfactionScore,
    this.satisfactionFeedback,
    this.calledDuringAfterHours = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name: caller name if available, else phone number.
  String get displayName => callerName ?? callerPhone;

  Lead copyWith({
    String? id,
    String? contractorId,
    String? callerPhone,
    String? callerName,
    String? issueDescription,
    Urgency? urgency,
    LeadStatus? status,
    bool? consentGiven,
    DateTime? consentGivenAt,
    int? callCount,
    double? estimatedValue,
    DateTime? bookingTime,
    String? calendlyEventId,
    bool? dnrAlertSent,
    DateTime? dnrAlertSentAt,
    int? satisfactionScore,
    String? satisfactionFeedback,
    bool? calledDuringAfterHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lead(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      callerPhone: callerPhone ?? this.callerPhone,
      callerName: callerName ?? this.callerName,
      issueDescription: issueDescription ?? this.issueDescription,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      consentGiven: consentGiven ?? this.consentGiven,
      consentGivenAt: consentGivenAt ?? this.consentGivenAt,
      callCount: callCount ?? this.callCount,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      bookingTime: bookingTime ?? this.bookingTime,
      calendlyEventId: calendlyEventId ?? this.calendlyEventId,
      dnrAlertSent: dnrAlertSent ?? this.dnrAlertSent,
      dnrAlertSentAt: dnrAlertSentAt ?? this.dnrAlertSentAt,
      satisfactionScore: satisfactionScore ?? this.satisfactionScore,
      satisfactionFeedback: satisfactionFeedback ?? this.satisfactionFeedback,
      calledDuringAfterHours: calledDuringAfterHours ?? this.calledDuringAfterHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
