// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Recovery';

  @override
  String get appNameHighlight => 'AI';

  @override
  String get appTagline => 'Missed calls recovered. Revenue restored.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navLeads => 'Leads';

  @override
  String get navSettings => 'Settings';

  @override
  String get navProfile => 'Profile';

  @override
  String get navLogout => 'Log Out';

  @override
  String get loginTitle => 'Recovery';

  @override
  String get loginTitleHighlight => 'AI';

  @override
  String get loginSubtitle => 'Contractor Dashboard';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailPlaceholder => 'you@company.fi';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordPlaceholder => 'Enter your password';

  @override
  String get loginSubmit => 'Sign In';

  @override
  String get loginForgot => 'Forgot password?';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardRecoveredRevenue => 'Recovered Revenue';

  @override
  String get dashboardLeadsRecovered => 'Leads Recovered';

  @override
  String get dashboardRecoveryRate => 'Recovery Rate';

  @override
  String get dashboardAvgResponseTime => 'Avg Response Time';

  @override
  String get dashboardRevenueChartTitle => 'Revenue — Last 30 Days';

  @override
  String get dashboardRecentWins => 'Recent Wins';

  @override
  String get dashboardNoWinsYet => 'No completed leads yet';

  @override
  String get dashboardThisMonth => 'this month';

  @override
  String get dashboardTrendUp => 'vs last month';

  @override
  String get leadsTitle => 'Leads';

  @override
  String get leadsSearchPlaceholder => 'Search by name or phone...';

  @override
  String get leadsFilterAll => 'All';

  @override
  String get leadsFilterMissed => 'Missed';

  @override
  String get leadsFilterContacted => 'Contacted';

  @override
  String get leadsFilterBooked => 'Booked';

  @override
  String get leadsFilterCompleted => 'Completed';

  @override
  String leadsCalledTimes(int count) {
    return 'Called ${count}x';
  }

  @override
  String get leadsEmptyTitle => 'No leads yet';

  @override
  String get leadsEmptyDesc => 'Missed calls will appear here automatically';

  @override
  String get leadsNoResults => 'No leads match your filters';

  @override
  String get leadDetailBack => 'Back to leads';

  @override
  String get leadDetailPhone => 'Phone';

  @override
  String get leadDetailName => 'Name';

  @override
  String get leadDetailStatus => 'Status';

  @override
  String get leadDetailUrgency => 'Urgency';

  @override
  String get leadDetailCreated => 'Created';

  @override
  String get leadDetailBookingTime => 'Booking';

  @override
  String get leadDetailEstimatedValue => 'Est. Value';

  @override
  String get leadDetailCallCount => 'Call Count';

  @override
  String get leadDetailSatisfaction => 'Satisfaction';

  @override
  String get leadDetailConversation => 'Conversation';

  @override
  String get leadDetailNoMessages => 'No messages yet';

  @override
  String get leadDetailMarkComplete => 'Mark Complete';

  @override
  String get leadDetailCallLead => 'Call Lead';

  @override
  String get leadDetailAddNote => 'Add Note';

  @override
  String get leadDetailAfterHours => 'After Hours';

  @override
  String get leadDetailIssue => 'Issue';

  @override
  String get leadDetailFeedback => 'Feedback';

  @override
  String get leadDetailLeadInfo => 'Lead Info';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBusinessInfo => 'Business Information';

  @override
  String get settingsBusinessName => 'Business Name';

  @override
  String get settingsContactName => 'Contact Name';

  @override
  String get settingsContactEmail => 'Contact Email';

  @override
  String get settingsContactPhone => 'Contact Phone';

  @override
  String get settingsTradeType => 'Trade Type';

  @override
  String get settingsWorkingHours => 'Working Hours';

  @override
  String get settingsWorkingDays => 'Working Days';

  @override
  String get settingsStartTime => 'Start Time';

  @override
  String get settingsEndTime => 'End Time';

  @override
  String get settingsRecovery => 'Recovery Settings';

  @override
  String get settingsUrgentThreshold => 'Urgent Threshold (min)';

  @override
  String get settingsNormalThreshold => 'Normal Threshold (min)';

  @override
  String get settingsDefaultJobValue => 'Default Job Value (€)';

  @override
  String get settingsCalendlyUrl => 'Calendly URL';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsTier => 'Subscription Tier';

  @override
  String get settingsSmsUsage => 'SMS Usage';

  @override
  String settingsSmsUsedOf(int used, int cap) {
    return '$used of $cap used';
  }

  @override
  String get settingsSave => 'Save Changes';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileVersion => 'App Version';

  @override
  String get profileLogout => 'Log Out';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get urgencyEmergency => 'Emergency';

  @override
  String get urgencyHigh => 'Urgent';

  @override
  String get urgencyMedium => 'This Week';

  @override
  String get urgencyLow => 'Not Urgent';

  @override
  String get urgencyUnknown => 'Unknown';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusConsentSent => 'Consent Sent';

  @override
  String get statusOptedIn => 'Opted In';

  @override
  String get statusQualifying => 'Qualifying';

  @override
  String get statusBookingSent => 'Booking Sent';

  @override
  String get statusBooked => 'Booked';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFollowedUp => 'Followed Up';

  @override
  String get statusDnrAlert => 'DNR Alert';

  @override
  String get statusNoConsent => 'No Consent';

  @override
  String get statusContacted => 'Contacted';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get toastLeadCompleted => 'Lead marked as completed!';

  @override
  String get toastSettingsSaved => 'Settings saved successfully';

  @override
  String toastNewLead(String phone) {
    return 'New missed call from $phone';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String get waitingForResponse => 'Waiting for response...';
}
