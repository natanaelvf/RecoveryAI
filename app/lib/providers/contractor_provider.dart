import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contractor.dart';
import '../services/api_service.dart';

// ---------------------------------------------------------------------------
// Contractor provider — async, Supabase-backed
// ---------------------------------------------------------------------------

final _api = ApiService();

/// The contractor notifier. Fetches the contractor row from Supabase on init,
/// exposes loading/error/data states via AsyncValue.
class ContractorNotifier extends AsyncNotifier<Contractor> {
  @override
  Future<Contractor> build() async {
    return _api.fetchContractor();
  }

  /// Update contractor settings. Sends to Supabase, then updates local state.
  /// NOTE: We intentionally do NOT set AsyncLoading here. Setting loading
  /// would cause isOnboardingCompleteProvider to momentarily return false
  /// (since whenOrNull yields null during loading), which triggers the
  /// router redirect to /onboarding — a critical bug.
  Future<void> updateSettings(Map<String, dynamic> fields) async {
    final previous = state.valueOrNull;
    try {
      final updated = await _api.updateContractorSettings(fields);
      state = AsyncData(updated);
    } catch (e) {
      // Restore previous data if available, but surface the error.
      if (previous != null) {
        state = AsyncData(previous);
      }
      debugPrint('Failed to update contractor settings: $e');
      rethrow;
    }
  }

  /// Save onboarding data — called when the wizard completes.
  /// NOTE: We intentionally do NOT set AsyncLoading here. Setting loading
  /// would cause isOnboardingCompleteProvider to momentarily return false
  /// (since there's no previous value on first onboarding), which triggers
  /// the router redirect to /onboarding — the exact bug we're fixing.
  Future<void> saveOnboarding({
    required String businessName,
    required String contactName,
    required String contactEmail,
    required String contactPhone,
    required String twilioPhoneNumber,
    required String numberSetupType,
    String? tradeType,
    String? calendlyUrl,
    required List<int> workingDays,
    required String workingHoursStart,
    required String workingHoursEnd,
    required int urgencyThresholdUrgentMin,
    required int urgencyThresholdNormalMin,
    required double defaultJobValue,
  }) async {
    try {
      final updated = await _api.saveOnboarding(
        businessName: businessName,
        contactName: contactName,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        twilioPhoneNumber: twilioPhoneNumber,
        numberSetupType: numberSetupType,
        tradeType: tradeType,
        calendlyUrl: calendlyUrl,
        workingDays: workingDays,
        workingHoursStart: workingHoursStart,
        workingHoursEnd: workingHoursEnd,
        urgencyThresholdUrgentMin: urgencyThresholdUrgentMin,
        urgencyThresholdNormalMin: urgencyThresholdNormalMin,
        defaultJobValue: defaultJobValue,
      );
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Force refresh from Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.fetchContractor());
  }
}

final contractorProvider =
    AsyncNotifierProvider<ContractorNotifier, Contractor>(
  ContractorNotifier.new,
);

/// Whether onboarding is complete — derived from contractor data.
/// True when business_name and twilio_phone_number are non-empty.
/// IMPORTANT: During loading/error, if we already have a previous value,
/// preserve the onboarding-complete status to avoid spurious redirects.
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  final contractorAsync = ref.watch(contractorProvider);
  return contractorAsync.when(
    data: (c) => c.businessName.isNotEmpty && c.twilioPhoneNumber.isNotEmpty,
    loading: () => contractorAsync.hasValue
        ? (contractorAsync.value!.businessName.isNotEmpty &&
            contractorAsync.value!.twilioPhoneNumber.isNotEmpty)
        : false,
    error: (_, __) => contractorAsync.hasValue
        ? (contractorAsync.value!.businessName.isNotEmpty &&
            contractorAsync.value!.twilioPhoneNumber.isNotEmpty)
        : false,
  );
});

