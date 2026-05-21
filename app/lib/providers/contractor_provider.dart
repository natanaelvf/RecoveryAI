import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mock_data.dart';
import '../models/contractor.dart';

/// Contractor state — initialized with mock data.
class ContractorNotifier extends ChangeNotifier {
  Contractor _contractor = mockContractor;

  Contractor get contractor => _contractor;

  void updateSettings({
    String? businessName,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? tradeType,
    String? workingHoursStart,
    String? workingHoursEnd,
    List<int>? workingDays,
    int? urgencyThresholdUrgentMin,
    int? urgencyThresholdNormalMin,
    double? defaultJobValue,
    String? calendlyUrl,
  }) {
    _contractor = _contractor.copyWith(
      businessName: businessName,
      contactName: contactName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      tradeType: tradeType,
      workingHoursStart: workingHoursStart,
      workingHoursEnd: workingHoursEnd,
      workingDays: workingDays,
      urgencyThresholdUrgentMin: urgencyThresholdUrgentMin,
      urgencyThresholdNormalMin: urgencyThresholdNormalMin,
      defaultJobValue: defaultJobValue,
      calendlyUrl: calendlyUrl,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }
}

final contractorProvider = ChangeNotifierProvider<ContractorNotifier>((ref) {
  return ContractorNotifier();
});
