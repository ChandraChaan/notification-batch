/// Why a notification from a batched app was let through. Mirrors `LetThroughReason` in Kotlin.
enum LetThroughReason {
  call,
  alarm,
  fullScreen,
  ongoing,
  media,
  timeSensitive,
  verificationCode,
  urgentWord,
  starredContact,
  nothingToShow;

  /// Kotlin sends `VERIFICATION_CODE`; this is `verificationCode`.
  static LetThroughReason? fromName(String name) {
    final camel = name.toLowerCase().replaceAllMapped(
      RegExp('_([a-z])'),
      (match) => match.group(1)!.toUpperCase(),
    );
    for (final reason in values) {
      if (reason.name == camel) return reason;
    }
    return null;
  }
}

/// A calendar day, without a time or a time zone.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  /// Parses `2026-10-28`.
  factory Day.parse(String text) {
    final parts = text.split('-').map(int.parse).toList();
    if (parts.length != 3) throw FormatException('Not a date', text);
    return Day(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

  /// Calendar arithmetic in UTC, so daylight saving never makes a day 23 or 25 hours long.
  Day minusDays(int days) {
    final date = DateTime.utc(year, month, day - days);
    return Day(date.year, date.month, date.day);
  }

  /// 1 is Monday, 7 is Sunday.
  int get weekday => DateTime.utc(year, month, day).weekday;

  @override
  int compareTo(Day other) => _key.compareTo(other._key);

  int get _key => year * 10000 + month * 100 + day;

  @override
  bool operator ==(Object other) =>
      other is Day && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

class DayStats {
  const DayStats({required this.day, this.held = const {}, this.letThrough = const {}});

  final Day day;

  /// Interruptions saved, per package name.
  final Map<String, int> held;

  final Map<LetThroughReason, int> letThrough;

  int get heldTotal => held.values.fold(0, (sum, count) => sum + count);
}

/// Raw daily counts as stored on the phone.
class StatsSnapshot {
  const StatsSnapshot({required this.today, this.days = const [], this.labels = const {}});

  /// Today in the phone's own calendar, as Android sees it.
  final Day today;
  final List<DayStats> days;

  /// App names by package name.
  final Map<String, String> labels;
}

class AppCount {
  const AppCount({required this.packageName, required this.label, required this.count});

  final String packageName;
  final String label;
  final int count;
}

/// What the stats screen shows.
class StatsSummary {
  const StatsSummary({
    required this.savedToday,
    required this.savedThisWeek,
    required this.lastSevenDays,
    required this.noisiestApps,
    required this.letThroughThisWeek,
  });

  /// "This week" means the last seven days including today, not the calendar week.
  factory StatsSummary.from(StatsSnapshot snapshot, {int topApps = 5}) {
    final byDay = {for (final day in snapshot.days) day.day: day};
    final week = [for (var offset = 6; offset >= 0; offset--) snapshot.today.minusDays(offset)];
    final weekStats = [for (final day in week) byDay[day] ?? DayStats(day: day)];

    final perApp = <String, int>{};
    final letThrough = <LetThroughReason, int>{};
    for (final day in weekStats) {
      day.held.forEach((app, count) => perApp[app] = (perApp[app] ?? 0) + count);
      day.letThrough.forEach(
        (reason, count) => letThrough[reason] = (letThrough[reason] ?? 0) + count,
      );
    }
    final apps = [
      for (final MapEntry(key: app, value: count) in perApp.entries)
        if (count > 0) AppCount(packageName: app, label: snapshot.labels[app] ?? app, count: count),
    ]..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.label.compareTo(b.label));

    return StatsSummary(
      savedToday: weekStats.last.heldTotal,
      savedThisWeek: weekStats.fold(0, (sum, day) => sum + day.heldTotal),
      lastSevenDays: weekStats,
      noisiestApps: apps.take(topApps).toList(),
      letThroughThisWeek: letThrough,
    );
  }

  final int savedToday;
  final int savedThisWeek;

  /// Oldest first, always seven days, today last.
  final List<DayStats> lastSevenDays;

  final List<AppCount> noisiestApps;
  final Map<LetThroughReason, int> letThroughThisWeek;

  bool get isEmpty => savedThisWeek == 0 && letThroughThisWeek.isEmpty;
}
