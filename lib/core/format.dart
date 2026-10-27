import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Where a delivery falls relative to today, in local time.
enum DeliveryDay { today, tomorrow, later }

DeliveryDay deliveryDay(DateTime next, DateTime now) {
  final nextLocal = next.toLocal();
  final nowLocal = now.toLocal();
  final nextDate = DateTime(nextLocal.year, nextLocal.month, nextLocal.day);
  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  // Calendar arithmetic, not 24-hour steps, so daylight saving days count as one day.
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  if (nextDate == today) return DeliveryDay.today;
  if (nextDate == tomorrow) return DeliveryDay.tomorrow;
  return DeliveryDay.later;
}

/// "13:00" or "1:00 PM", following the phone's 24-hour setting.
String formatTime(BuildContext context, DateTime time) {
  final local = time.toLocal();
  return formatTimeOfDay(context, TimeOfDay(hour: local.hour, minute: local.minute));
}

String formatTimeOfDay(BuildContext context, TimeOfDay time) => MaterialLocalizations.of(
  context,
).formatTimeOfDay(time, alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));

String formatWeekday(BuildContext context, DateTime time) =>
    DateFormat.EEEE(Localizations.localeOf(context).toLanguageTag()).format(time.toLocal());
