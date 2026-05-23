class Contractor {
  final String id;
  final String businessName;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String twilioPhoneNumber;
  final String numberSetupType;
  final String? calendlyUrl;
  final String? tradeType;
  final double? defaultJobValue;
  final int urgencyThresholdUrgentMin;
  final int urgencyThresholdNormalMin;
  final String workingHoursStart;
  final String workingHoursEnd;
  final List<int> workingDays;
  final String? afterHoursEmergencyPolicy;
  final bool afterHoursRing;
  final String timezone;
  final String tier;
  final int monthlySMSCap;
  final int smsUsedThisMonth;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contractor({
    required this.id,
    required this.businessName,
    required this.contactName,
    required this.contactEmail,
    required this.contactPhone,
    required this.twilioPhoneNumber,
    this.numberSetupType = 'forwarding',
    this.calendlyUrl,
    this.tradeType,
    this.defaultJobValue,
    this.urgencyThresholdUrgentMin = 60,
    this.urgencyThresholdNormalMin = 1440,
    this.workingHoursStart = '08:00',
    this.workingHoursEnd = '18:00',
    this.workingDays = const [1, 2, 3, 4, 5],
    this.afterHoursEmergencyPolicy,
    this.afterHoursRing = false,
    this.timezone = 'Europe/Helsinki',
    this.tier = 'starter',
    this.monthlySMSCap = 50,
    this.smsUsedThisMonth = 0,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Initials for avatar (e.g., "JV" from "Jukka Virtanen").
  String get initials {
    final parts = contactName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return contactName.isNotEmpty ? contactName[0].toUpperCase() : '?';
  }

  /// SMS usage as percentage (0.0 to 1.0).
  double get smsUsagePercent =>
      monthlySMSCap > 0 ? smsUsedThisMonth / monthlySMSCap : 0;

  /// Tier display price per month.
  String get tierPrice {
    switch (tier) {
      case 'starter': return '€149';
      case 'growth': return '€249';
      case 'pro': return '€399';
      default: return '€149';
    }
  }

  factory Contractor.fromJson(Map<String, dynamic> json) {
    return Contractor(
      id: json['id'] as String,
      businessName: json['business_name'] as String,
      contactName: json['contact_name'] as String,
      contactEmail: json['contact_email'] as String,
      contactPhone: json['contact_phone'] as String,
      twilioPhoneNumber: json['twilio_phone_number'] as String,
      numberSetupType: json['number_setup_type'] as String? ?? 'forwarding',
      calendlyUrl: json['calendly_url'] as String?,
      tradeType: json['trade_type'] as String?,
      defaultJobValue: (json['default_job_value'] as num?)?.toDouble(),
      urgencyThresholdUrgentMin: json['urgency_threshold_urgent_min'] as int? ?? 60,
      urgencyThresholdNormalMin: json['urgency_threshold_normal_min'] as int? ?? 1440,
      workingHoursStart: json['working_hours_start'] as String? ?? '08:00',
      workingHoursEnd: json['working_hours_end'] as String? ?? '18:00',
      workingDays: (json['working_days'] as List<dynamic>?)?.cast<int>() ?? [1, 2, 3, 4, 5],
      afterHoursEmergencyPolicy: json['after_hours_emergency_policy'] as String?,
      afterHoursRing: json['after_hours_ring'] as bool? ?? false,
      timezone: json['timezone'] as String? ?? 'Europe/Helsinki',
      tier: json['tier'] as String? ?? 'starter',
      monthlySMSCap: json['monthly_sms_cap'] as int? ?? 50,
      smsUsedThisMonth: json['sms_used_this_month'] as int? ?? 0,
      fcmToken: json['fcm_token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_name': businessName,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'twilio_phone_number': twilioPhoneNumber,
      'number_setup_type': numberSetupType,
      'calendly_url': calendlyUrl,
      'trade_type': tradeType,
      'default_job_value': defaultJobValue,
      'urgency_threshold_urgent_min': urgencyThresholdUrgentMin,
      'urgency_threshold_normal_min': urgencyThresholdNormalMin,
      'working_hours_start': workingHoursStart,
      'working_hours_end': workingHoursEnd,
      'working_days': workingDays,
      'after_hours_emergency_policy': afterHoursEmergencyPolicy,
      'after_hours_ring': afterHoursRing,
      'timezone': timezone,
      'tier': tier,
      'monthly_sms_cap': monthlySMSCap,
      'sms_used_this_month': smsUsedThisMonth,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Contractor copyWith({
    String? id,
    String? businessName,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? twilioPhoneNumber,
    String? numberSetupType,
    String? calendlyUrl,
    String? tradeType,
    double? defaultJobValue,
    int? urgencyThresholdUrgentMin,
    int? urgencyThresholdNormalMin,
    String? workingHoursStart,
    String? workingHoursEnd,
    List<int>? workingDays,
    String? afterHoursEmergencyPolicy,
    bool? afterHoursRing,
    String? timezone,
    String? tier,
    int? monthlySMSCap,
    int? smsUsedThisMonth,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contractor(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      twilioPhoneNumber: twilioPhoneNumber ?? this.twilioPhoneNumber,
      numberSetupType: numberSetupType ?? this.numberSetupType,
      calendlyUrl: calendlyUrl ?? this.calendlyUrl,
      tradeType: tradeType ?? this.tradeType,
      defaultJobValue: defaultJobValue ?? this.defaultJobValue,
      urgencyThresholdUrgentMin: urgencyThresholdUrgentMin ?? this.urgencyThresholdUrgentMin,
      urgencyThresholdNormalMin: urgencyThresholdNormalMin ?? this.urgencyThresholdNormalMin,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
      workingDays: workingDays ?? this.workingDays,
      afterHoursEmergencyPolicy: afterHoursEmergencyPolicy ?? this.afterHoursEmergencyPolicy,
      afterHoursRing: afterHoursRing ?? this.afterHoursRing,
      timezone: timezone ?? this.timezone,
      tier: tier ?? this.tier,
      monthlySMSCap: monthlySMSCap ?? this.monthlySMSCap,
      smsUsedThisMonth: smsUsedThisMonth ?? this.smsUsedThisMonth,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
