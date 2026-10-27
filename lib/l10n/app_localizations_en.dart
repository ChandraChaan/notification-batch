// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Notification Batch';

  @override
  String get retry => 'Try again';

  @override
  String get errorGeneric => 'Something went wrong talking to Android.';

  @override
  String get loading => 'Loading';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navApps => 'Apps';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navRules => 'Let through';

  @override
  String get welcomeTitle => 'Fewer pings, nothing missed';

  @override
  String get welcomeBody =>
      'Notification Batch quietly holds notifications from the apps you pick, like shopping, food delivery and games, and delivers them together a few times a day.';

  @override
  String get welcomeAlwaysThrough =>
      'Calls, alarms, one-time codes and anything you mark as urgent always come through straight away.';

  @override
  String get accessTitle => 'Why it needs notification access';

  @override
  String get accessBody =>
      'To hold a notification the app has to see it arrive. Android calls this \"notification access\". With it, the app can read the notifications on this phone and remove them from the shade.';

  @override
  String get accessPromiseOnly =>
      'It only holds notifications from apps you choose. Everything else is left alone.';

  @override
  String get accessPromiseLocal =>
      'Held notifications are stored on this phone only. The app has no internet permission, no ads and no analytics, so nothing can leave the device.';

  @override
  String get accessPromiseUndo =>
      'You can turn access off at any time in Android settings, and everything comes back to normal.';

  @override
  String get accessButton => 'Open notification access settings';

  @override
  String get accessRestrictedTitle => 'Android says \"Restricted setting\"?';

  @override
  String get accessRestrictedBody =>
      'Android protects this switch for apps installed outside an app store. Open App info, tap the three-dot menu, choose \"Allow restricted settings\", then come back and try again.';

  @override
  String get accessRestrictedButton => 'Open App info';

  @override
  String get accessSettingsMissing =>
      'This phone has no notification access screen the app can open. Look for \"Notification access\" in Settings.';

  @override
  String get setupTitle => 'Choose apps to batch';

  @override
  String get setupBody =>
      'These look like apps whose notifications can wait. Untick anything you want to keep hearing about right away.';

  @override
  String get setupNone =>
      'No obvious candidates on this phone. You can pick apps any time in the Apps tab.';

  @override
  String get setupHint => 'Messaging, banking, calendar and clock apps are never suggested.';

  @override
  String get setupStart => 'Start batching';

  @override
  String get setupSkip => 'Skip for now';

  @override
  String setupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps selected',
      one: '1 app selected',
      zero: 'No apps selected',
    );
    return '$_temp0';
  }

  @override
  String get statusPaused => 'Batching is paused';

  @override
  String get statusPausedBody =>
      'New notifications come through as usual. Held ones still arrive at the next delivery.';

  @override
  String statusNextToday(String time) {
    return 'Next delivery at $time';
  }

  @override
  String statusNextTomorrow(String time) {
    return 'Next delivery tomorrow at $time';
  }

  @override
  String statusNextLater(String day, String time) {
    return 'Next delivery $day at $time';
  }

  @override
  String statusHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications held',
      one: '1 notification held',
      zero: 'Nothing held right now',
    );
    return '$_temp0';
  }

  @override
  String get statusBatching => 'Batching';

  @override
  String get statusNoApps => 'No apps are batched yet.';

  @override
  String get statusChooseApps => 'Choose apps';

  @override
  String get deliverNow => 'Deliver now';

  @override
  String get delivering => 'Delivered.';

  @override
  String get notificationsOffTitle => 'Batches can\'t be shown';

  @override
  String get notificationsOffBody =>
      'Allow Notification Batch to post notifications, or held items will only appear in this app.';

  @override
  String get notificationsOffButton => 'Allow';

  @override
  String get listenerWaiting =>
      'Waiting for Android to connect the listener. This usually takes a second.';

  @override
  String get inboxHeld => 'Held';

  @override
  String get inboxDelivered => 'Delivered';

  @override
  String get inboxEmptyHeldTitle => 'Nothing held';

  @override
  String get inboxEmptyHeldBody =>
      'Notifications from batched apps will wait here until the next delivery.';

  @override
  String get inboxEmptyDeliveredTitle => 'Nothing delivered yet';

  @override
  String get inboxEmptyDeliveredBody => 'Batches from the last two days show up here.';

  @override
  String get inboxOpenFailed => 'That app can\'t be opened any more.';

  @override
  String get itemOpen => 'Open';

  @override
  String itemStopBatching(String app) {
    return 'Stop batching $app';
  }

  @override
  String itemStoppedBatching(String app) {
    return '$app is no longer batched.';
  }

  @override
  String get itemMarkUrgent => 'Mark as urgent…';

  @override
  String get itemMarkUrgentTitle => 'Let notifications like this through';

  @override
  String get itemMarkUrgentBody =>
      'Any notification containing this word or phrase will skip the batch.';

  @override
  String itemMarkUrgentAdded(String word) {
    return '\"$word\" will be let through.';
  }

  @override
  String groupCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notifications',
      one: '1 notification',
    );
    return '$_temp0';
  }

  @override
  String get itemOptions => 'Options for this notification';

  @override
  String get appsTitle => 'Apps';

  @override
  String get appsSearch => 'Search apps';

  @override
  String get appsBatched => 'Batched';

  @override
  String get appsNotBatched => 'Not batched';

  @override
  String appsEmptySearch(String query) {
    return 'No apps match \"$query\".';
  }

  @override
  String get appsBatchSuggested => 'Batch suggested apps';

  @override
  String get kindShopping => 'Shopping';

  @override
  String get kindFood => 'Food and groceries';

  @override
  String get kindGames => 'Game';

  @override
  String get kindSocial => 'Social';

  @override
  String get kindMessaging => 'Messages from people: best left alone';

  @override
  String get kindImportant => 'Money, time or travel: best left alone';

  @override
  String batchApp(String app) {
    return 'Batch $app';
  }

  @override
  String get scheduleTitle => 'Delivery times';

  @override
  String get scheduleBody => 'Held notifications arrive together as one summary at these times.';

  @override
  String get scheduleAdd => 'Add a time';

  @override
  String scheduleRemove(String time) {
    return 'Remove $time';
  }

  @override
  String get scheduleLastOne => 'Keep at least one delivery time.';

  @override
  String get scheduleExactTitle => 'Deliver on the minute';

  @override
  String get scheduleExactBody =>
      'Without the \"Alarms & reminders\" permission Android may deliver a batch up to 10 minutes late.';

  @override
  String get scheduleExactButton => 'Allow';

  @override
  String get scheduleTimeZone =>
      'Times follow the phone\'s clock, including time zone and daylight saving changes.';

  @override
  String get rulesTitle => 'Always let through';

  @override
  String get rulesBody =>
      'These skip the batch even when they come from a batched app. When the app can\'t tell, it lets the notification through.';

  @override
  String get ruleCalls => 'Calls and alarms';

  @override
  String get ruleCallsBody => 'Including anything that opens full screen.';

  @override
  String get ruleCodes => 'One-time codes';

  @override
  String get ruleCodesBody => 'Verification codes, OTPs and login PINs.';

  @override
  String get ruleOngoing => 'Ongoing things';

  @override
  String get ruleOngoingBody => 'Music, navigation, downloads, timers and reminders.';

  @override
  String get ruleOtherApps => 'Apps you don\'t batch';

  @override
  String get ruleOtherAppsBody => 'Messaging apps are never batched unless you pick them.';

  @override
  String get ruleStarred => 'Starred contacts';

  @override
  String get ruleStarredBody =>
      'Messages from people you starred in Contacts, even in a batched app. Needs contacts access, which stays on the phone.';

  @override
  String get ruleStarredDenied => 'Contacts access was not granted.';

  @override
  String get urgentTitle => 'Urgent words';

  @override
  String get urgentBody =>
      'A notification containing any of these words is let through right away.';

  @override
  String get urgentAdd => 'Add a word or phrase';

  @override
  String get urgentAddButton => 'Add';

  @override
  String urgentRemove(String word) {
    return 'Remove $word';
  }

  @override
  String get urgentEmpty => 'None yet. Try \"delivered\", \"gate\" or a name.';

  @override
  String get cancel => 'Cancel';

  @override
  String get saveFailed => 'Couldn\'t save. Please try again.';
}
