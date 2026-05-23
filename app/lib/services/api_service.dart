import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/contractor.dart';
import '../models/lead.dart';
import '../models/message.dart';

// ---------------------------------------------------------------------------
// Pagination model
// ---------------------------------------------------------------------------

class PaginatedLeads {
  final List<Lead> leads;
  final int total;

  const PaginatedLeads({required this.leads, required this.total});
}

// ---------------------------------------------------------------------------
// Stats models
// ---------------------------------------------------------------------------

class MonthStats {
  final String month;
  final int recoveredCount;
  final double totalValue;
  final int responseRate;
  final int totalLeads;

  const MonthStats({
    required this.month,
    required this.recoveredCount,
    required this.totalValue,
    required this.responseRate,
    required this.totalLeads,
  });
}

class StatsResponse {
  final MonthStats current;
  final MonthStats previous;

  const StatsResponse({required this.current, required this.previous});
}

// ---------------------------------------------------------------------------
// API Service — single source of truth for all data operations
// ---------------------------------------------------------------------------

class ApiService {
  // Singleton
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  SupabaseClient get _client => supabase;

  /// The backend API base URL (for server-side operations only).
  /// Override via `--dart-define=BACKEND_URL=https://...` at build time.
  // ignore: unused_field
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Current auth user ID (= contractor ID by design).
  String? get _contractorId => _client.auth.currentUser?.id;

  /// Current auth session access token.
  String? get _accessToken => _client.auth.currentSession?.accessToken;

  // ── Contractor ───────────────────────────────────────

  /// Fetch the current contractor's settings.
  Future<Contractor> fetchContractor() async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    final response = await _client
        .from('contractors')
        .select()
        .eq('id', id)
        .single();

    return Contractor.fromJson(response);
  }

  /// Update contractor settings. Only non-null fields are sent.
  Future<Contractor> updateContractorSettings(
      Map<String, dynamic> fields) async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    fields['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('contractors')
        .update(fields)
        .eq('id', id)
        .select()
        .single();

    return Contractor.fromJson(response);
  }

  /// Save onboarding data to the contractor row.
  Future<Contractor> saveOnboarding({
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
    return updateContractorSettings({
      'business_name': businessName,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'twilio_phone_number': twilioPhoneNumber,
      'number_setup_type': numberSetupType,
      'trade_type': tradeType,
      'calendly_url': calendlyUrl,
      'working_days': workingDays,
      'working_hours_start': workingHoursStart,
      'working_hours_end': workingHoursEnd,
      'urgency_threshold_urgent_min': urgencyThresholdUrgentMin,
      'urgency_threshold_normal_min': urgencyThresholdNormalMin,
      'default_job_value': defaultJobValue,
    });
  }

  // ── Leads ────────────────────────────────────────────

  /// Fetch leads for the current contractor, with optional status filter.
  /// Sorted by created_at DESC. Supports pagination with accurate total count.
  Future<PaginatedLeads> fetchLeads({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    final offset = (page - 1) * limit;

    // Build the data query
    var query = _client
        .from('leads')
        .select()
        .eq('contractor_id', id);

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final leads = (response as List)
        .map((row) => Lead.fromJson(row as Map<String, dynamic>))
        .toList();

    // Build a separate count query for accurate total
    var countQuery = _client
        .from('leads')
        .select()
        .eq('contractor_id', id);

    if (status != null && status.isNotEmpty) {
      countQuery = countQuery.eq('status', status);
    }

    final countResponse = await countQuery;
    final total = (countResponse as List).length;

    return PaginatedLeads(leads: leads, total: total);
  }

  /// Fetch all leads (no pagination) for derived computations (stats, calendar).
  Future<List<Lead>> fetchAllLeads() async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    final response = await _client
        .from('leads')
        .select()
        .eq('contractor_id', id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => Lead.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single lead by ID.
  Future<Lead> fetchLead(String leadId) async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    final response = await _client
        .from('leads')
        .select()
        .eq('id', leadId)
        .eq('contractor_id', id)
        .single();

    return Lead.fromJson(response);
  }

  /// Fetch messages for a specific lead.
  Future<List<Message>> fetchMessages(String leadId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('lead_id', leadId)
        .order('sent_at', ascending: true);

    return (response as List)
        .map((row) => Message.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Fetch job costs for a specific lead.
  Future<List<JobCost>> fetchJobCosts(String leadId) async {
    final response = await _client
        .from('job_costs')
        .select()
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => JobCost.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Update lead fields directly via Supabase (for simple field updates).
  Future<Lead> updateLead(String leadId, Map<String, dynamic> fields) async {
    fields['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from('leads')
        .update(fields)
        .eq('id', leadId)
        .select()
        .single();

    return Lead.fromJson(response);
  }

  /// Mark a lead as completed. This goes through the backend API because
  /// the backend schedules a satisfaction follow-up task.
  Future<Lead> markLeadComplete(String leadId) async {
    final token = _accessToken;
    if (token == null) throw Exception('Not authenticated');

    // Use Supabase's built-in HTTP capabilities to call the backend.
    // We need an actual HTTP call to the backend here.
    // For simplicity, we do the update + task scheduling directly via Supabase.
    // This avoids needing Dio as a dependency.

    // 1. Update lead status
    final lead = await updateLead(leadId, {'status': 'completed'});

    // 2. Schedule satisfaction follow-up (24 hours from now)
    final followupTime = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 24))
        .toIso8601String();

    await _client.from('scheduled_tasks').insert({
      'lead_id': leadId,
      'task_type': 'satisfaction_followup',
      'execute_at': followupTime,
      'executed': false,
    });

    return lead;
  }

  /// Add a cost entry to a lead.
  Future<JobCost> addCost(
      String leadId, String description, double amount) async {
    final response = await _client
        .from('job_costs')
        .insert({
          'lead_id': leadId,
          'description': description,
          'amount': amount,
        })
        .select()
        .single();

    return JobCost.fromJson(response);
  }

  /// Add a lead manually.
  Future<Lead> addLeadManually({
    required String phone,
    String? name,
    String? description,
    String urgency = 'unknown',
    double? estimatedValue,
  }) async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    final response = await _client
        .from('leads')
        .insert({
          'contractor_id': id,
          'caller_phone': phone,
          'caller_name': name,
          'issue_description': description,
          'urgency': urgency,
          'status': 'missed',
          'consent_given': false,
          'call_count': 1,
          'called_during_after_hours': false,
          'estimated_value': estimatedValue,
        })
        .select()
        .single();

    return Lead.fromJson(response);
  }

  /// Delete a lead (GDPR). Uses Supabase directly — cascading deletes
  /// handle messages and scheduled_tasks via FK ON DELETE CASCADE.
  /// Also inserts an audit_log entry.
  Future<void> deleteLeadGdpr(String leadId) async {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    // Delete job_costs (no cascade FK)
    await _client.from('job_costs').delete().eq('lead_id', leadId);

    // Delete messages (cascade would handle this, but be explicit)
    await _client.from('messages').delete().eq('lead_id', leadId);

    // Delete scheduled_tasks
    await _client.from('scheduled_tasks').delete().eq('lead_id', leadId);

    // Delete the lead
    await _client.from('leads').delete().eq('id', leadId);

    // Audit log (no PII)
    await _client.from('audit_log').insert({
      'action': 'gdpr_deletion',
      'entity_type': 'lead',
      'entity_id': leadId,
      'performed_by': id,
    });
  }

  // ── Realtime ─────────────────────────────────────────

  /// Subscribe to lead changes for the current contractor.
  /// Returns a RealtimeChannel that the caller can unsubscribe from.
  RealtimeChannel subscribeToLeads({
    required void Function(Map<String, dynamic> newRecord) onInsert,
    required void Function(Map<String, dynamic> newRecord) onUpdate,
    required void Function(Map<String, dynamic> oldRecord) onDelete,
  }) {
    final id = _contractorId;
    if (id == null) throw Exception('Not authenticated');

    final channel = _client.channel('leads-realtime-${DateTime.now().millisecondsSinceEpoch}').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'leads',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'contractor_id',
        value: id,
      ),
      callback: (payload) {
        debugPrint('[realtime] Lead INSERT: ${payload.newRecord}');
        onInsert(payload.newRecord);
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'leads',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'contractor_id',
        value: id,
      ),
      callback: (payload) {
        debugPrint('[realtime] Lead UPDATE: ${payload.newRecord}');
        onUpdate(payload.newRecord);
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'leads',
      callback: (payload) {
        debugPrint('[realtime] Lead DELETE: ${payload.oldRecord}');
        onDelete(payload.oldRecord);
      },
    );

    channel.subscribe((status, [error]) {
      debugPrint('[realtime] Channel status: $status${error != null ? ' error: $error' : ''}');
    });
    return channel;
  }

  /// Unsubscribe from a Realtime channel.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
