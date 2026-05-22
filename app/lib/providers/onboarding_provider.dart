import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding state — tracks wizard progress and collected data.
class OnboardingNotifier extends ChangeNotifier {
  int _currentStep = 0;
  bool _isComplete = false;

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
  bool get isComplete => _isComplete;
  int get totalSteps => 4;

  /// Can advance from current step (basic validation).
  bool get canAdvance {
    switch (_currentStep) {
      case 0: return businessName.trim().isNotEmpty && tradeType != null;
      case 1: return contactName.trim().isNotEmpty
          && contactEmail.trim().isNotEmpty
          && contactPhone.trim().isNotEmpty;
      case 2: return phoneNumber.trim().isNotEmpty;
      case 3: return workingDays.isNotEmpty;
      default: return false;
    }
  }

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

  void complete() {
    _isComplete = true;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _isComplete = false;
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
