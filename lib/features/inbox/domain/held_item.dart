/// A notification that was taken out of the shade and kept for a delivery.
class HeldItem {
  const HeldItem({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.title,
    required this.text,
    required this.postedAt,
  });

  final String id;
  final String packageName;
  final String appLabel;
  final String title;
  final String text;

  /// UTC.
  final DateTime postedAt;

  @override
  bool operator ==(Object other) =>
      other is HeldItem &&
      other.id == id &&
      other.packageName == packageName &&
      other.appLabel == appLabel &&
      other.title == title &&
      other.text == text &&
      other.postedAt == postedAt;

  @override
  int get hashCode => Object.hash(id, packageName, appLabel, title, text, postedAt);
}

/// Held items from one app, newest first.
class AppGroup {
  const AppGroup({required this.packageName, required this.appLabel, required this.items});

  final String packageName;
  final String appLabel;
  final List<HeldItem> items;

  DateTime get latest => items.first.postedAt;
}

/// Groups items by app. The app with the most recent notification comes first.
List<AppGroup> groupByApp(Iterable<HeldItem> items) {
  final byApp = <String, List<HeldItem>>{};
  for (final item in items) {
    byApp.putIfAbsent(item.packageName, () => []).add(item);
  }
  final groups = [
    for (final entry in byApp.entries)
      AppGroup(
        packageName: entry.key,
        appLabel: entry.value.first.appLabel,
        items: entry.value..sort((a, b) => b.postedAt.compareTo(a.postedAt)),
      ),
  ];
  return groups..sort((a, b) {
    final byTime = b.latest.compareTo(a.latest);
    return byTime != 0 ? byTime : a.appLabel.compareTo(b.appLabel);
  });
}
