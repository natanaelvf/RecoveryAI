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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
