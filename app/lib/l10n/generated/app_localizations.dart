import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fi')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get appName;

  /// No description provided for @appNameHighlight.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get appNameHighlight;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Missed calls recovered. Revenue restored.'**
  String get appTagline;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get navLeads;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get navLogout;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get loginTitle;

  /// No description provided for @loginTitleHighlight.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get loginTitleHighlight;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Contractor Dashboard'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'you@company.fi'**
  String get loginEmailPlaceholder;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordPlaceholder;

  /// No description provided for @loginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSubmit;

  /// No description provided for @loginForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgot;

  /// No description provided for @loginGoogleButton.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogleButton;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or sign in with email'**
  String get loginOrDivider;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get loginCreateAccount;

  /// No description provided for @loginBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get loginBackToSignIn;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginSignUp;

  /// No description provided for @loginPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters, 1 uppercase, 1 number'**
  String get loginPasswordRequirements;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardRecoveredRevenue.
  ///
  /// In en, this message translates to:
  /// **'Recovered Revenue'**
  String get dashboardRecoveredRevenue;

  /// No description provided for @dashboardLeadsRecovered.
  ///
  /// In en, this message translates to:
  /// **'Leads Recovered'**
  String get dashboardLeadsRecovered;

  /// No description provided for @dashboardRecoveryRate.
  ///
  /// In en, this message translates to:
  /// **'Recovery Rate'**
  String get dashboardRecoveryRate;

  /// No description provided for @dashboardAvgResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Response Time'**
  String get dashboardAvgResponseTime;

  /// No description provided for @dashboardRevenueChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Revenue — Last 30 Days'**
  String get dashboardRevenueChartTitle;

  /// No description provided for @dashboardRecentWins.
  ///
  /// In en, this message translates to:
  /// **'Recent Wins'**
  String get dashboardRecentWins;

  /// No description provided for @dashboardNoWinsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed leads yet'**
  String get dashboardNoWinsYet;

  /// No description provided for @dashboardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get dashboardThisMonth;

  /// No description provided for @dashboardTrendUp.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get dashboardTrendUp;

  /// No description provided for @leadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get leadsTitle;

  /// No description provided for @leadsSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get leadsSearchPlaceholder;

  /// No description provided for @leadsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get leadsFilterAll;

  /// No description provided for @leadsFilterMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get leadsFilterMissed;

  /// No description provided for @leadsFilterContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get leadsFilterContacted;

  /// No description provided for @leadsFilterBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get leadsFilterBooked;

  /// No description provided for @leadsFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get leadsFilterCompleted;

  /// No description provided for @leadsCalledTimes.
  ///
  /// In en, this message translates to:
  /// **'Called {count}x'**
  String leadsCalledTimes(int count);

  /// No description provided for @leadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No leads yet'**
  String get leadsEmptyTitle;

  /// No description provided for @leadsEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Missed calls will appear here automatically'**
  String get leadsEmptyDesc;

  /// No description provided for @leadsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No leads match your filters'**
  String get leadsNoResults;

  /// No description provided for @leadDetailBack.
  ///
  /// In en, this message translates to:
  /// **'Back to leads'**
  String get leadDetailBack;

  /// No description provided for @leadDetailPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get leadDetailPhone;

  /// No description provided for @leadDetailName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get leadDetailName;

  /// No description provided for @leadDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get leadDetailStatus;

  /// No description provided for @leadDetailUrgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get leadDetailUrgency;

  /// No description provided for @leadDetailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get leadDetailCreated;

  /// No description provided for @leadDetailBookingTime.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get leadDetailBookingTime;

  /// No description provided for @leadDetailEstimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Est. Value'**
  String get leadDetailEstimatedValue;

  /// No description provided for @leadDetailCallCount.
  ///
  /// In en, this message translates to:
  /// **'Call Count'**
  String get leadDetailCallCount;

  /// No description provided for @leadDetailSatisfaction.
  ///
  /// In en, this message translates to:
  /// **'Satisfaction'**
  String get leadDetailSatisfaction;

  /// No description provided for @leadDetailConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get leadDetailConversation;

  /// No description provided for @leadDetailNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get leadDetailNoMessages;

  /// No description provided for @leadDetailMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get leadDetailMarkComplete;

  /// No description provided for @leadDetailCallLead.
  ///
  /// In en, this message translates to:
  /// **'Call Lead'**
  String get leadDetailCallLead;

  /// No description provided for @leadDetailAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get leadDetailAddNote;

  /// No description provided for @leadDetailAfterHours.
  ///
  /// In en, this message translates to:
  /// **'After Hours'**
  String get leadDetailAfterHours;

  /// No description provided for @leadDetailIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get leadDetailIssue;

  /// No description provided for @leadDetailFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get leadDetailFeedback;

  /// No description provided for @leadDetailLeadInfo.
  ///
  /// In en, this message translates to:
  /// **'Lead Info'**
  String get leadDetailLeadInfo;

  /// No description provided for @leadDetailCosts.
  ///
  /// In en, this message translates to:
  /// **'Costs'**
  String get leadDetailCosts;

  /// No description provided for @leadDetailTotalCosts.
  ///
  /// In en, this message translates to:
  /// **'Total Costs'**
  String get leadDetailTotalCosts;

  /// No description provided for @leadDetailNetRevenue.
  ///
  /// In en, this message translates to:
  /// **'Net Revenue'**
  String get leadDetailNetRevenue;

  /// No description provided for @leadDetailAddCost.
  ///
  /// In en, this message translates to:
  /// **'Add Cost'**
  String get leadDetailAddCost;

  /// No description provided for @leadDetailCostDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get leadDetailCostDescription;

  /// No description provided for @leadDetailCostAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get leadDetailCostAmount;

  /// No description provided for @leadDetailNoCosts.
  ///
  /// In en, this message translates to:
  /// **'No costs recorded yet'**
  String get leadDetailNoCosts;

  /// No description provided for @leadDetailEditValue.
  ///
  /// In en, this message translates to:
  /// **'Edit Expected Revenue'**
  String get leadDetailEditValue;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBusinessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get settingsBusinessInfo;

  /// No description provided for @settingsBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get settingsBusinessName;

  /// No description provided for @settingsContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get settingsContactName;

  /// No description provided for @settingsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Email'**
  String get settingsContactEmail;

  /// No description provided for @settingsContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get settingsContactPhone;

  /// No description provided for @settingsTradeType.
  ///
  /// In en, this message translates to:
  /// **'Trade Type'**
  String get settingsTradeType;

  /// No description provided for @settingsWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get settingsWorkingHours;

  /// No description provided for @settingsWorkingDays.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get settingsWorkingDays;

  /// No description provided for @settingsStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get settingsStartTime;

  /// No description provided for @settingsEndTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get settingsEndTime;

  /// No description provided for @settingsRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery Settings'**
  String get settingsRecovery;

  /// No description provided for @settingsUrgentThreshold.
  ///
  /// In en, this message translates to:
  /// **'Urgent Threshold (min)'**
  String get settingsUrgentThreshold;

  /// No description provided for @settingsNormalThreshold.
  ///
  /// In en, this message translates to:
  /// **'Normal Threshold (min)'**
  String get settingsNormalThreshold;

  /// No description provided for @settingsDefaultJobValue.
  ///
  /// In en, this message translates to:
  /// **'Default Job Value (€)'**
  String get settingsDefaultJobValue;

  /// No description provided for @settingsCalendlyUrl.
  ///
  /// In en, this message translates to:
  /// **'Calendly URL'**
  String get settingsCalendlyUrl;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsTier.
  ///
  /// In en, this message translates to:
  /// **'Subscription Tier'**
  String get settingsTier;

  /// No description provided for @settingsSmsUsage.
  ///
  /// In en, this message translates to:
  /// **'SMS Usage'**
  String get settingsSmsUsage;

  /// No description provided for @settingsSmsUsedOf.
  ///
  /// In en, this message translates to:
  /// **'{used} of {cap} used'**
  String settingsSmsUsedOf(int used, int cap);

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get settingsSave;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get profileVersion;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get profileLogoutConfirm;

  /// No description provided for @urgencyEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get urgencyEmergency;

  /// No description provided for @urgencyHigh.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyHigh;

  /// No description provided for @urgencyMedium.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get urgencyMedium;

  /// No description provided for @urgencyLow.
  ///
  /// In en, this message translates to:
  /// **'Not Urgent'**
  String get urgencyLow;

  /// No description provided for @urgencyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get urgencyUnknown;

  /// No description provided for @statusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statusMissed;

  /// No description provided for @statusConsentSent.
  ///
  /// In en, this message translates to:
  /// **'Consent Sent'**
  String get statusConsentSent;

  /// No description provided for @statusOptedIn.
  ///
  /// In en, this message translates to:
  /// **'Opted In'**
  String get statusOptedIn;

  /// No description provided for @statusQualifying.
  ///
  /// In en, this message translates to:
  /// **'Qualifying'**
  String get statusQualifying;

  /// No description provided for @statusBookingSent.
  ///
  /// In en, this message translates to:
  /// **'Booking Sent'**
  String get statusBookingSent;

  /// No description provided for @statusBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get statusBooked;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFollowedUp.
  ///
  /// In en, this message translates to:
  /// **'Followed Up'**
  String get statusFollowedUp;

  /// No description provided for @statusDnrAlert.
  ///
  /// In en, this message translates to:
  /// **'DNR Alert'**
  String get statusDnrAlert;

  /// No description provided for @statusNoConsent.
  ///
  /// In en, this message translates to:
  /// **'No Consent'**
  String get statusNoConsent;

  /// No description provided for @statusContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get statusContacted;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @toastLeadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lead marked as completed!'**
  String get toastLeadCompleted;

  /// No description provided for @toastSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get toastSettingsSaved;

  /// No description provided for @toastNewLead.
  ///
  /// In en, this message translates to:
  /// **'New missed call from {phone}'**
  String toastNewLead(String phone);

  /// No description provided for @toastCostAdded.
  ///
  /// In en, this message translates to:
  /// **'Cost added'**
  String get toastCostAdded;

  /// No description provided for @toastValueUpdated.
  ///
  /// In en, this message translates to:
  /// **'Revenue updated'**
  String get toastValueUpdated;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String timeWeeksAgo(int count);

  /// No description provided for @waitingForResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for response...'**
  String get waitingForResponse;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fi': return AppLocalizationsFi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
