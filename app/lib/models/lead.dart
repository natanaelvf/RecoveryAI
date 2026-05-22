/// Lead status progression:
/// missed → consent_sent → opted_in → qualifying → booking_sent → booked → completed → followed_up
/// Side branches: dnr_alert, no_consent
enum LeadStatus {
  missed,
  consentSent,
  optedIn,
  qualifying,
  qualifyingIssue,
  qualifyingUrgency,
  qualifyingName,
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
      case qualifyingIssue: return 'qualifying_issue';
      case qualifyingUrgency: return 'qualifying_urgency';
      case qualifyingName: return 'qualifying_name';
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
      case 'qualifying_issue': return qualifyingIssue;
      case 'qualifying_urgency': return qualifyingUrgency;
      case 'qualifying_name': return qualifyingName;
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
      case qualifyingIssue:
      case qualifyingUrgency:
      case qualifyingName:
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
      case qualifyingIssue:
      case qualifyingUrgency:
      case qualifyingName:
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

  /// Create a Lead from a JSON map (e.g., from the REST API).
  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String,
      contractorId: json['contractor_id'] as String,
      callerPhone: json['caller_phone'] as String,
      callerName: json['caller_name'] as String?,
      issueDescription: json['issue_description'] as String?,
      urgency: Urgency.fromString(json['urgency'] as String? ?? 'unknown'),
      status: LeadStatus.fromString(json['status'] as String? ?? 'missed'),
      consentGiven: json['consent_given'] as bool? ?? false,
      consentGivenAt: json['consent_given_at'] != null
          ? DateTime.parse(json['consent_given_at'] as String)
          : null,
      callCount: json['call_count'] as int? ?? 1,
      estimatedValue: (json['estimated_value'] as num?)?.toDouble(),
      bookingTime: json['booking_time'] != null
          ? DateTime.parse(json['booking_time'] as String)
          : null,
      calendlyEventId: json['calendly_event_id'] as String?,
      dnrAlertSent: json['dnr_alert_sent'] as bool? ?? false,
      dnrAlertSentAt: json['dnr_alert_sent_at'] != null
          ? DateTime.parse(json['dnr_alert_sent_at'] as String)
          : null,
      satisfactionScore: json['satisfaction_score'] as int?,
      satisfactionFeedback: json['satisfaction_feedback'] as String?,
      calledDuringAfterHours: json['called_during_after_hours'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Serialize to JSON map for API requests.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractor_id': contractorId,
      'caller_phone': callerPhone,
      'caller_name': callerName,
      'issue_description': issueDescription,
      'urgency': urgency.name,
      'status': status.value,
      'consent_given': consentGiven,
      'consent_given_at': consentGivenAt?.toIso8601String(),
      'call_count': callCount,
      'estimated_value': estimatedValue,
      'booking_time': bookingTime?.toIso8601String(),
      'calendly_event_id': calendlyEventId,
      'dnr_alert_sent': dnrAlertSent,
      'dnr_alert_sent_at': dnrAlertSentAt?.toIso8601String(),
      'satisfaction_score': satisfactionScore,
      'satisfaction_feedback': satisfactionFeedback,
      'called_during_after_hours': calledDuringAfterHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

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
