import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Batch'**
  String get appTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong talking to Android.'**
  String get errorGeneric;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get navApps;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navRules.
  ///
  /// In en, this message translates to:
  /// **'Let through'**
  String get navRules;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fewer pings, nothing missed'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Notification Batch quietly holds notifications from the apps you pick, like shopping, food delivery and games, and delivers them together a few times a day.'**
  String get welcomeBody;

  /// No description provided for @welcomeAlwaysThrough.
  ///
  /// In en, this message translates to:
  /// **'Calls, alarms, one-time codes and anything you mark as urgent always come through straight away.'**
  String get welcomeAlwaysThrough;

  /// No description provided for @accessTitle.
  ///
  /// In en, this message translates to:
  /// **'Why it needs notification access'**
  String get accessTitle;

  /// No description provided for @accessBody.
  ///
  /// In en, this message translates to:
  /// **'To hold a notification the app has to see it arrive. Android calls this \"notification access\". With it, the app can read the notifications on this phone and remove them from the shade.'**
  String get accessBody;

  /// No description provided for @accessPromiseOnly.
  ///
  /// In en, this message translates to:
  /// **'It only holds notifications from apps you choose. Everything else is left alone.'**
  String get accessPromiseOnly;

  /// No description provided for @accessPromiseLocal.
  ///
  /// In en, this message translates to:
  /// **'Held notifications are stored on this phone only. The app has no internet permission, no ads and no analytics, so nothing can leave the device.'**
  String get accessPromiseLocal;

  /// No description provided for @accessPromiseUndo.
  ///
  /// In en, this message translates to:
  /// **'You can turn access off at any time in Android settings, and everything comes back to normal.'**
  String get accessPromiseUndo;

  /// No description provided for @accessButton.
  ///
  /// In en, this message translates to:
  /// **'Open notification access settings'**
  String get accessButton;

  /// No description provided for @accessRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Android says \"Restricted setting\"?'**
  String get accessRestrictedTitle;

  /// No description provided for @accessRestrictedBody.
  ///
  /// In en, this message translates to:
  /// **'Android protects this switch for apps installed outside an app store. Open App info, tap the three-dot menu, choose \"Allow restricted settings\", then come back and try again.'**
  String get accessRestrictedBody;

  /// No description provided for @accessRestrictedButton.
  ///
  /// In en, this message translates to:
  /// **'Open App info'**
  String get accessRestrictedButton;

  /// No description provided for @accessSettingsMissing.
  ///
  /// In en, this message translates to:
  /// **'This phone has no notification access screen the app can open. Look for \"Notification access\" in Settings.'**
  String get accessSettingsMissing;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose apps to batch'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'These look like apps whose notifications can wait. Untick anything you want to keep hearing about right away.'**
  String get setupBody;

  /// No description provided for @setupNone.
  ///
  /// In en, this message translates to:
  /// **'No obvious candidates on this phone. You can pick apps any time in the Apps tab.'**
  String get setupNone;

  /// No description provided for @setupHint.
  ///
  /// In en, this message translates to:
  /// **'Messaging, banking, calendar and clock apps are never suggested.'**
  String get setupHint;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Start batching'**
  String get setupStart;

  /// No description provided for @setupSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get setupSkip;

  /// No description provided for @setupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No apps selected} =1{1 app selected} other{{count} apps selected}}'**
  String setupCount(int count);

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Batching is paused'**
  String get statusPaused;

  /// No description provided for @statusPausedBody.
  ///
  /// In en, this message translates to:
  /// **'New notifications come through as usual. Held ones still arrive at the next delivery.'**
  String get statusPausedBody;

  /// No description provided for @statusNextToday.
  ///
  /// In en, this message translates to:
  /// **'Next delivery at {time}'**
  String statusNextToday(String time);

  /// No description provided for @statusNextTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Next delivery tomorrow at {time}'**
  String statusNextTomorrow(String time);

  /// No description provided for @statusNextLater.
  ///
  /// In en, this message translates to:
  /// **'Next delivery {day} at {time}'**
  String statusNextLater(String day, String time);

  /// No description provided for @statusHeld.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing held right now} =1{1 notification held} other{{count} notifications held}}'**
  String statusHeld(int count);

  /// No description provided for @statusBatching.
  ///
  /// In en, this message translates to:
  /// **'Batching'**
  String get statusBatching;

  /// No description provided for @statusNoApps.
  ///
  /// In en, this message translates to:
  /// **'No apps are batched yet.'**
  String get statusNoApps;

  /// No description provided for @statusChooseApps.
  ///
  /// In en, this message translates to:
  /// **'Choose apps'**
  String get statusChooseApps;

  /// No description provided for @deliverNow.
  ///
  /// In en, this message translates to:
  /// **'Deliver now'**
  String get deliverNow;

  /// No description provided for @delivering.
  ///
  /// In en, this message translates to:
  /// **'Delivered.'**
  String get delivering;

  /// No description provided for @notificationsOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Batches can\'t be shown'**
  String get notificationsOffTitle;

  /// No description provided for @notificationsOffBody.
  ///
  /// In en, this message translates to:
  /// **'Allow Notification Batch to post notifications, or held items will only appear in this app.'**
  String get notificationsOffBody;

  /// No description provided for @notificationsOffButton.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get notificationsOffButton;

  /// No description provided for @listenerWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Android to connect the listener. This usually takes a second.'**
  String get listenerWaiting;

  /// No description provided for @inboxHeld.
  ///
  /// In en, this message translates to:
  /// **'Held'**
  String get inboxHeld;

  /// No description provided for @inboxDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get inboxDelivered;

  /// No description provided for @inboxEmptyHeldTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing held'**
  String get inboxEmptyHeldTitle;

  /// No description provided for @inboxEmptyHeldBody.
  ///
  /// In en, this message translates to:
  /// **'Notifications from batched apps will wait here until the next delivery.'**
  String get inboxEmptyHeldBody;

  /// No description provided for @inboxEmptyDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing delivered yet'**
  String get inboxEmptyDeliveredTitle;

  /// No description provided for @inboxEmptyDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Batches from the last two days show up here.'**
  String get inboxEmptyDeliveredBody;

  /// No description provided for @inboxOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'That app can\'t be opened any more.'**
  String get inboxOpenFailed;

  /// No description provided for @itemOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get itemOpen;

  /// No description provided for @itemStopBatching.
  ///
  /// In en, this message translates to:
  /// **'Stop batching {app}'**
  String itemStopBatching(String app);

  /// No description provided for @itemStoppedBatching.
  ///
  /// In en, this message translates to:
  /// **'{app} is no longer batched.'**
  String itemStoppedBatching(String app);

  /// No description provided for @itemMarkUrgent.
  ///
  /// In en, this message translates to:
  /// **'Mark as urgent…'**
  String get itemMarkUrgent;

  /// No description provided for @itemMarkUrgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Let notifications like this through'**
  String get itemMarkUrgentTitle;

  /// No description provided for @itemMarkUrgentBody.
  ///
  /// In en, this message translates to:
  /// **'Any notification containing this word or phrase will skip the batch.'**
  String get itemMarkUrgentBody;

  /// No description provided for @itemMarkUrgentAdded.
  ///
  /// In en, this message translates to:
  /// **'\"{word}\" will be let through.'**
  String itemMarkUrgentAdded(String word);

  /// No description provided for @groupCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 notification} other{{count} notifications}}'**
  String groupCount(int count);

  /// No description provided for @itemOptions.
  ///
  /// In en, this message translates to:
  /// **'Options for this notification'**
  String get itemOptions;

  /// No description provided for @appsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get appsTitle;

  /// No description provided for @appsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get appsSearch;

  /// No description provided for @appsBatched.
  ///
  /// In en, this message translates to:
  /// **'Batched'**
  String get appsBatched;

  /// No description provided for @appsNotBatched.
  ///
  /// In en, this message translates to:
  /// **'Not batched'**
  String get appsNotBatched;

  /// No description provided for @appsEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No apps match \"{query}\".'**
  String appsEmptySearch(String query);

  /// No description provided for @appsBatchSuggested.
  ///
  /// In en, this message translates to:
  /// **'Batch suggested apps'**
  String get appsBatchSuggested;

  /// No description provided for @kindShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get kindShopping;

  /// No description provided for @kindFood.
  ///
  /// In en, this message translates to:
  /// **'Food and groceries'**
  String get kindFood;

  /// No description provided for @kindGames.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get kindGames;

  /// No description provided for @kindSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get kindSocial;

  /// No description provided for @kindMessaging.
  ///
  /// In en, this message translates to:
  /// **'Messages from people: best left alone'**
  String get kindMessaging;

  /// No description provided for @kindImportant.
  ///
  /// In en, this message translates to:
  /// **'Usually important: best left alone'**
  String get kindImportant;

  /// No description provided for @batchApp.
  ///
  /// In en, this message translates to:
  /// **'Batch {app}'**
  String batchApp(String app);

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery times'**
  String get scheduleTitle;

  /// No description provided for @scheduleBody.
  ///
  /// In en, this message translates to:
  /// **'Held notifications arrive together as one summary at these times.'**
  String get scheduleBody;

  /// No description provided for @scheduleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a time'**
  String get scheduleAdd;

  /// No description provided for @scheduleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {time}'**
  String scheduleRemove(String time);

  /// No description provided for @scheduleLastOne.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one delivery time.'**
  String get scheduleLastOne;

  /// No description provided for @scheduleExactTitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver on the minute'**
  String get scheduleExactTitle;

  /// No description provided for @scheduleExactBody.
  ///
  /// In en, this message translates to:
  /// **'Without the \"Alarms & reminders\" permission Android may deliver a batch up to 10 minutes late.'**
  String get scheduleExactBody;

  /// No description provided for @scheduleExactButton.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get scheduleExactButton;

  /// No description provided for @scheduleTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Times follow the phone\'s clock, including time zone and daylight saving changes.'**
  String get scheduleTimeZone;

  /// No description provided for @rulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Always let through'**
  String get rulesTitle;

  /// No description provided for @rulesBody.
  ///
  /// In en, this message translates to:
  /// **'These skip the batch even when they come from a batched app. When the app can\'t tell, it lets the notification through.'**
  String get rulesBody;

  /// No description provided for @ruleCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls and alarms'**
  String get ruleCalls;

  /// No description provided for @ruleCallsBody.
  ///
  /// In en, this message translates to:
  /// **'Including anything that opens full screen.'**
  String get ruleCallsBody;

  /// No description provided for @ruleCodes.
  ///
  /// In en, this message translates to:
  /// **'One-time codes'**
  String get ruleCodes;

  /// No description provided for @ruleCodesBody.
  ///
  /// In en, this message translates to:
  /// **'Verification codes, OTPs and login PINs.'**
  String get ruleCodesBody;

  /// No description provided for @ruleOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing things'**
  String get ruleOngoing;

  /// No description provided for @ruleOngoingBody.
  ///
  /// In en, this message translates to:
  /// **'Music, navigation, downloads, timers and reminders.'**
  String get ruleOngoingBody;

  /// No description provided for @ruleOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Apps you don\'t batch'**
  String get ruleOtherApps;

  /// No description provided for @ruleOtherAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Messaging apps are never batched unless you pick them.'**
  String get ruleOtherAppsBody;

  /// No description provided for @ruleStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred contacts'**
  String get ruleStarred;

  /// No description provided for @ruleStarredBody.
  ///
  /// In en, this message translates to:
  /// **'Messages from people you starred in Contacts, even in a batched app. Needs contacts access, which stays on the phone.'**
  String get ruleStarredBody;

  /// No description provided for @ruleStarredDenied.
  ///
  /// In en, this message translates to:
  /// **'Contacts access was not granted.'**
  String get ruleStarredDenied;

  /// No description provided for @urgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent words'**
  String get urgentTitle;

  /// No description provided for @urgentBody.
  ///
  /// In en, this message translates to:
  /// **'A notification containing any of these words is let through right away.'**
  String get urgentBody;

  /// No description provided for @urgentAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a word or phrase'**
  String get urgentAdd;

  /// No description provided for @urgentAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get urgentAddButton;

  /// No description provided for @urgentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {word}'**
  String urgentRemove(String word);

  /// No description provided for @urgentEmpty.
  ///
  /// In en, this message translates to:
  /// **'None yet. Try \"delivered\", \"gate\" or a name.'**
  String get urgentEmpty;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get saveFailed;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// No description provided for @statsSavedToday.
  ///
  /// In en, this message translates to:
  /// **'Saved today'**
  String get statsSavedToday;

  /// No description provided for @statsSavedWeek.
  ///
  /// In en, this message translates to:
  /// **'Saved this week'**
  String get statsSavedWeek;

  /// No description provided for @statsInterruptions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{interruption} other{interruptions}}'**
  String statsInterruptions(int count);

  /// No description provided for @statsLastSeven.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get statsLastSeven;

  /// No description provided for @statsDayBar.
  ///
  /// In en, this message translates to:
  /// **'{day}: {count, plural, =1{1 held} other{{count} held}}'**
  String statsDayBar(String day, int count);

  /// No description provided for @statsNoisiest.
  ///
  /// In en, this message translates to:
  /// **'Noisiest apps this week'**
  String get statsNoisiest;

  /// No description provided for @statsAppCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 held} other{{count} held}}'**
  String statsAppCount(int count);

  /// No description provided for @statsLetThrough.
  ///
  /// In en, this message translates to:
  /// **'Let through this week'**
  String get statsLetThrough;

  /// No description provided for @statsLetThroughBody.
  ///
  /// In en, this message translates to:
  /// **'From batched apps, delivered straight away.'**
  String get statsLetThroughBody;

  /// No description provided for @statsLetThroughNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing from batched apps needed to skip the batch.'**
  String get statsLetThroughNone;

  /// No description provided for @statsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No numbers yet'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once batched apps send notifications, you\'ll see how many interruptions were saved.'**
  String get statsEmptyBody;

  /// No description provided for @statsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Counts stay on this phone for five weeks: only numbers and app names, never what a notification said.'**
  String get statsPrivacy;

  /// No description provided for @reasonCall.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get reasonCall;

  /// No description provided for @reasonAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get reasonAlarm;

  /// No description provided for @reasonFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get reasonFullScreen;

  /// No description provided for @reasonOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get reasonOngoing;

  /// No description provided for @reasonMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get reasonMedia;

  /// No description provided for @reasonTimeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Reminders and events'**
  String get reasonTimeSensitive;

  /// No description provided for @reasonVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'One-time codes'**
  String get reasonVerificationCode;

  /// No description provided for @reasonUrgentWord.
  ///
  /// In en, this message translates to:
  /// **'Urgent words'**
  String get reasonUrgentWord;

  /// No description provided for @reasonStarredContact.
  ///
  /// In en, this message translates to:
  /// **'Starred contacts'**
  String get reasonStarredContact;

  /// No description provided for @reasonNothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Empty notifications'**
  String get reasonNothingToShow;

  /// No description provided for @reasonCount.
  ///
  /// In en, this message translates to:
  /// **'{reason}: {count}'**
  String reasonCount(String reason, int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
