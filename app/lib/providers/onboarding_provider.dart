import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contractor_provider.dart';

/// Onboarding state — tracks wizard progress and collected data.
/// On completion, persists all collected data to the contractors table
/// via the ContractorNotifier.
class OnboardingNotifier extends ChangeNotifier {
  int _currentStep = 0;
  bool _isSaving = false;
  String? _error;

  // Step 1: Business Info
  String businessName = '';
  String? tradeType;

  // Step 2: Contact Details
  String contactName = '';
  String contactEmail = '';
  String contactPhone = '';

  // Step 3: Phone Setup
  String phoneNumber = '';
  String numberSetupType = 'forwarding'; // 'forwarding' | 'new_number'

  // Step 4: Schedule & Preferences
  List<int> workingDays = [1, 2, 3, 4, 5];
  String workingHoursStart = '08:00';
  String workingHoursEnd = '18:00';
  int urgencyThresholdUrgentMin = 60;
  int urgencyThresholdNormalMin = 1440;
  double defaultJobValue = 350;
  String calendlyUrl = '';

  int get currentStep => _currentStep;
  bool get isSaving => _isSaving;
  String? get error => _error;
  int get totalSteps => 4;

  /// Whether onboarding is complete is now derived from the contractor row.
  /// This getter is kept for backward compatibility with the router,
  /// but the real source of truth is `isOnboardingCompleteProvider`.
  bool get isComplete => false; // Always false here; router checks provider.

  /// Can advance from current step.
  bool get canAdvance => true;

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  /// Save onboarding data to Supabase and mark as complete.
  /// Called by the onboarding screen's "Complete" button.
  /// The [contractorNotifier] is passed in from the widget (via ref).
  Future<bool> complete(ContractorNotifier contractorNotifier) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await contractorNotifier.saveOnboarding(
        businessName: businessName,
        contactName: contactName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        twilioPhoneNumber: phoneNumber,
        numberSetupType: numberSetupType,
        tradeType: tradeType,
        calendlyUrl: calendlyUrl.isNotEmpty ? calendlyUrl : null,
        workingDays: workingDays,
        workingHoursStart: workingHoursStart,
        workingHoursEnd: workingHoursEnd,
        urgencyThresholdUrgentMin: urgencyThresholdUrgentMin,
        urgencyThresholdNormalMin: urgencyThresholdNormalMin,
        defaultJobValue: defaultJobValue,
      );

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _error = 'Failed to save: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _isSaving = false;
    _error = null;
    businessName = '';
    tradeType = null;
    contactName = '';
    contactEmail = '';
    contactPhone = '';
    phoneNumber = '';
    numberSetupType = 'forwarding';
    workingDays = [1, 2, 3, 4, 5];
    workingHoursStart = '08:00';
    workingHoursEnd = '18:00';
    urgencyThresholdUrgentMin = 60;
    urgencyThresholdNormalMin = 1440;
    defaultJobValue = 350;
    calendlyUrl = '';
    notifyListeners();
  }
}

final onboardingProvider = ChangeNotifierProvider<OnboardingNotifier>((ref) {
  return OnboardingNotifier();
});
