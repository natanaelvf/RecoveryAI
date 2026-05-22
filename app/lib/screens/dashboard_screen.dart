import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:missed_lead_recovery/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../data/mock_data.dart';
import '../models/lead.dart';
import '../providers/stats_provider.dart';
import '../providers/leads_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/month_calendar.dart';
import '../widgets/pipeline_funnel.dart';
import '../widgets/activity_feed.dart';
import '../widgets/week_strip_calendar.dart';
import '../widgets/schedule_card.dart';
import '../widgets/urgent_attention_card.dart';
import '../widgets/sms_usage_gauge.dart';

/// Enhanced dashboard screen — greeting, urgent attention, calendar schedule,
/// stats, pipeline funnel, SMS gauge, chart, activity feed.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final stats = ref.watch(statsProvider);
    final pipelineCounts = ref.watch(pipelineCountsProvider);
    final activityEvents = ref.watch(activityEventsProvider);
    final urgentLeads = ref.watch(urgentLeadsProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final eventCounts = ref.watch(calendarEventCountsProvider);
    final scheduledLeads = ref.watch(
      scheduledLeadsForDateProvider(selectedDate),
    );
    final smsUsage = ref.watch(smsUsageProvider);
    final displayMonth = ref.watch(displayMonthProvider);
    final calendarDayData = ref.watch(calendarDayDataProvider);
    final calendarLeads = ref.watch(leadsForCalendarDateProvider(selectedDate));

    final now = DateTime.now();
    final greeting = _greeting(now);

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: CustomScrollView(
        slivers: [
          // ── Greeting App Bar ────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            snap: true,
            backgroundColor: colors.bgSurface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$greeting, ${mockContractor.contactName.split(' ').first} 👋',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateString(now),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Urgent Attention ───────────────────
                if (urgentLeads.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.warning_amber_rounded,
                    iconColor: colors.accentDanger,
                    title: 'NEEDS ATTENTION',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentDangerMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${urgentLeads.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.accentDanger,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...urgentLeads
                      .take(3)
                      .map(
                        (lead) => UrgentAttentionCard(
                          lead: lead,
                          onTap: () => context.push('/leads/${lead.id}'),
                        ),
                      ),
                  if (urgentLeads.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(statusFilterProvider.notifier).state =
                              'missed';
                          context.go('/leads');
                        },
                        child: Text(
                          'View ${urgentLeads.length - 3} more →',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.accentPrimary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],

                // ── Stats grid — 2x2 ─────────────────
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1.65,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      label: l10n.dashboardRecoveredRevenue,
                      targetValue: stats.recoveredRevenue,
                      prefix: '€',
                      emoji: '💰',
                      accentColor: colors.accentSuccess,
                    ),
                    StatCard(
                      label: l10n.dashboardLeadsRecovered,
                      targetValue: stats.leadsRecovered.toDouble(),
                      emoji: '📞',
                      accentColor: colors.accentPrimary,
                    ),
                    StatCard(
                      label: l10n.dashboardRecoveryRate,
                      targetValue: stats.recoveryRate.toDouble(),
                      suffix: '%',
                      emoji: '📈',
                      accentColor: colors.accentInfo,
                    ),
                    StatCard(
                      label: l10n.dashboardAvgResponseTime,
                      targetValue: 12,
                      suffix: ' min',
                      emoji: '⚡',
                      accentColor: colors.accentDanger,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Schedule / Calendar ────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.calendar_today_rounded,
                        iconColor: colors.accentInfo,
                        title: 'SCHEDULE',
                      ),
                      const SizedBox(height: 12),

                      // Week strip
                      WeekStripCalendar(
                        selectedDate: selectedDate,
                        eventCounts: eventCounts,
                        onDateSelected:
                            (date) =>
                                ref
                                    .read(selectedCalendarDateProvider.notifier)
                                    .state = date,
                      ),

                      const SizedBox(height: 16),

                      // Appointments for selected date
                      if (scheduledLeads.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  '📅',
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: colors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No appointments',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.textTertiary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '${scheduledLeads.length} appointment${scheduledLeads.length > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ...scheduledLeads.map(
                          (lead) => ScheduleCard(
                            lead: lead,
                            onTap: () => context.push('/leads/${lead.id}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Pipeline Funnel + SMS Usage side by side ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pipeline
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(
                              icon: Icons.filter_alt_rounded,
                              iconColor: colors.accentPrimary,
                              title: 'PIPELINE',
                            ),
                            const SizedBox(height: 14),
                            PipelineFunnel(
                              stageCounts: pipelineCounts,
                              onStageTap: (stage) {
                                ref.read(statusFilterProvider.notifier).state =
                                    stage;
                                context.go('/leads');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── SMS Usage ─────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.sms_rounded,
                        iconColor: colors.accentSuccess,
                        title: 'SMS USAGE',
                      ),
                      const SizedBox(height: 14),
                      SmsUsageGauge(used: smsUsage.used, cap: smsUsage.cap),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Leads & Bookings Calendar ─────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(
                        icon: Icons.event_available_rounded,
                        iconColor: colors.accentSuccess,
                        title: 'LEADS & BOOKINGS',
                      ),
                      const SizedBox(height: 16),
                      MonthCalendar(
                        displayMonth: displayMonth,
                        selectedDate: selectedDate,
                        dayData: calendarDayData,
                        onDateSelected:
                            (date) =>
                                ref
                                    .read(selectedCalendarDateProvider.notifier)
                                    .state = date,
                        onPreviousMonth: () {
                          final current = ref.read(displayMonthProvider);
                          ref.read(displayMonthProvider.notifier).state =
                              DateTime(current.year, current.month - 1, 1);
                        },
                        onNextMonth: () {
                          final current = ref.read(displayMonthProvider);
                          ref.read(displayMonthProvider.notifier).state =
                              DateTime(current.year, current.month + 1, 1);
                        },
                      ),

                      // ── Leads for selected day ──
                      if (calendarLeads.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(color: colors.borderSubtle, height: 1),
                        const SizedBox(height: 12),
                        Text(
                          '${calendarLeads.length} lead${calendarLeads.length > 1 ? 's' : ''} on ${selectedDate.day}.${selectedDate.month}.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ...calendarLeads.map(
                          (lead) => _CalendarLeadTile(
                            lead: lead,
                            onTap: () => context.push('/leads/${lead.id}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Activity Feed ─────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionHeader(
                              icon: Icons.timeline_rounded,
                              iconColor: colors.accentInfo,
                              title: 'RECENT ACTIVITY',
                            ),
                            Text(
                              '${activityEvents.length} events',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ActivityFeed(
                        events: activityEvents,
                        onEventTap: (event) {
                          if (event.leadId != null) {
                            context.push('/leads/${event.leadId}');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateString(DateTime now) {
    final weekday =
        [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ][now.weekday - 1];
    final month =
        [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][now.month - 1];
    return '$weekday, ${now.day} $month ${now.year}';
  }
}

/// Reusable section header with icon + title.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Compact lead tile for the calendar day detail view.
class _CalendarLeadTile extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;

  const _CalendarLeadTile({required this.lead, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor(lead.status, colors),
              ),
            ),
            const SizedBox(width: 10),

            // Name & description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lead.issueDescription != null)
                    Text(
                      lead.issueDescription!,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Value
            if (lead.estimatedValue != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentSuccessMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '€${lead.estimatedValue!.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.accentSuccess,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(LeadStatus status, AppColors colors) {
    switch (status) {
      case LeadStatus.missed:
      case LeadStatus.consentSent:
        return colors.statusMissed;
      case LeadStatus.dnrAlert:
        return colors.statusDnr;
      case LeadStatus.noConsent:
        return colors.statusNoConsent;
      case LeadStatus.booked:
        return colors.statusBooked;
      case LeadStatus.completed:
      case LeadStatus.followedUp:
        return colors.statusCompleted;
      default:
        return colors.statusActive;
    }
  }
}
