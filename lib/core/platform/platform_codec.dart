import '../../features/apps/domain/installed_app.dart';
import '../../features/inbox/domain/held_item.dart';
import '../../features/stats/domain/batch_stats.dart';
import '../../features/status/domain/batch_status.dart';
import 'batch_platform.dart';

/// Turns the maps that come over the platform channel into models. Unknown or missing values
/// fall back to safe defaults; a value of the wrong type is a bug on the Kotlin side.
abstract final class PlatformCodec {
  static BatchStatus status(Object? raw) {
    final map = _map(raw);
    return BatchStatus(
      listenerEnabled: map['listenerEnabled'] == true,
      listenerConnected: map['listenerConnected'] == true,
      notificationsAllowed: map['notificationsAllowed'] != false,
      contactsAllowed: map['contactsAllowed'] == true,
      exactAlarmsAllowed: map['exactAlarmsAllowed'] != false,
      nextDeliveryAt: _time(map['nextDeliveryAt']),
      heldCount: (map['heldCount'] as num?)?.toInt() ?? 0,
      lastDeliveryAt: _time(map['lastDeliveryAt']),
    );
  }

  static List<HeldItem> items(Object? raw) => [for (final item in _list(raw)) heldItem(item)];

  static HeldItem heldItem(Object? raw) {
    final map = _map(raw);
    final packageName = map['packageName'] as String? ?? '';
    return HeldItem(
      id: map['id'] as String? ?? '',
      packageName: packageName,
      appLabel: map['appLabel'] as String? ?? packageName,
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postedAt: _time(map['postedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static List<InstalledApp> apps(Object? raw) => [
    for (final item in _list(raw))
      if (_map(item) case final map)
        InstalledApp(
          packageName: map['packageName'] as String? ?? '',
          label: map['label'] as String? ?? map['packageName'] as String? ?? '',
          category: AppCategory.fromAndroid((map['category'] as num?)?.toInt()),
          isSystem: map['isSystem'] == true,
          isDefaultSms: map['isDefaultSms'] == true,
          isDefaultDialer: map['isDefaultDialer'] == true,
        ),
  ];

  static StatsSnapshot stats(Object? raw) {
    final map = _map(raw);
    try {
      return StatsSnapshot(
        today: Day.parse(map['today'] as String? ?? ''),
        days: [
          for (final item in _list(map['days']))
            if (_map(item) case final day)
              DayStats(
                day: Day.parse(day['date'] as String? ?? ''),
                held: _counts(day['held']),
                letThrough: {
                  for (final MapEntry(key: name, value: count) in _counts(
                    day['letThrough'],
                  ).entries)
                    ?LetThroughReason.fromName(name): count,
                },
              ),
        ],
        labels: {
          for (final MapEntry(:key, :value) in (map['labels'] as Map? ?? const {}).entries)
            if (key is String && value is String) key: value,
        },
      );
    } on FormatException {
      throw const BatchPlatformException('unexpected_reply');
    }
  }

  static Map<String, int> _counts(Object? raw) => {
    if (raw is Map)
      for (final MapEntry(:key, :value) in raw.entries)
        if (key is String && value is num) key: value.toInt(),
  };

  static DateTime? _time(Object? millis) =>
      millis is num ? DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true) : null;

  static Map<Object?, Object?> _map(Object? raw) {
    if (raw is Map) return raw;
    throw const BatchPlatformException('unexpected_reply');
  }

  static List<Object?> _list(Object? raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    throw const BatchPlatformException('unexpected_reply');
  }
}
