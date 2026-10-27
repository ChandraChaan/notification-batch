/// Android's own app categories (`ApplicationInfo.category`).
enum AppCategory {
  game(0),
  audio(1),
  video(2),
  image(3),
  social(4),
  news(5),
  maps(6),
  productivity(7),
  accessibility(8),
  undefined(-1);

  const AppCategory(this.androidValue);

  final int androidValue;

  static AppCategory fromAndroid(int? value) =>
      values.firstWhere((c) => c.androidValue == value, orElse: () => undefined);
}

/// An app with a launcher icon on the phone.
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    this.category = AppCategory.undefined,
    this.isSystem = false,
    this.isDefaultSms = false,
    this.isDefaultDialer = false,
  });

  final String packageName;
  final String label;
  final AppCategory category;
  final bool isSystem;
  final bool isDefaultSms;
  final bool isDefaultDialer;

  @override
  bool operator ==(Object other) =>
      other is InstalledApp &&
      other.packageName == packageName &&
      other.label == label &&
      other.category == category &&
      other.isSystem == isSystem &&
      other.isDefaultSms == isDefaultSms &&
      other.isDefaultDialer == isDefaultDialer;

  @override
  int get hashCode =>
      Object.hash(packageName, label, category, isSystem, isDefaultSms, isDefaultDialer);
}
