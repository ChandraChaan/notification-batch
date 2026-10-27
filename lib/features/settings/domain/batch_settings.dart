import 'delivery_time.dart';

/// What the user chose. The Android listener reads the same JSON (see `spec/settings.json`).
class BatchSettings {
  const BatchSettings({
    this.batchedPackages = const {},
    this.deliveryTimes = DeliveryTime.defaults,
    this.paused = false,
    this.urgentWords = const [],
    this.letStarredContactsThrough = false,
    this.setupDone = false,
  });

  factory BatchSettings.fromJson(Map<String, Object?> json) {
    final packages = json['batchedPackages'];
    final minutes = json['deliveryMinutes'];
    final words = json['urgentWords'];
    return BatchSettings(
      batchedPackages: {if (packages is List) ...packages.whereType<String>()},
      deliveryTimes: DeliveryTime.normalize([
        if (minutes is List) ...minutes.whereType<num>().map((m) => DeliveryTime(m.toInt())),
      ]),
      paused: json['paused'] == true,
      urgentWords: normalizeWords([if (words is List) ...words.whereType<String>()]),
      letStarredContactsThrough: json['letStarredContactsThrough'] == true,
      setupDone: json['setupDone'] == true,
    );
  }

  /// Apps whose notifications are held for the next delivery.
  final Set<String> batchedPackages;

  /// Sorted, unique and never empty.
  final List<DeliveryTime> deliveryTimes;

  final bool paused;

  /// A notification that contains any of these words is let through straight away.
  final List<String> urgentWords;

  final bool letStarredContactsThrough;

  /// The first-run app picker has been completed.
  final bool setupDone;

  Map<String, Object?> toJson() => {
    'version': 1,
    'batchedPackages': batchedPackages.toList()..sort(),
    'deliveryMinutes': [for (final time in deliveryTimes) time.minutes],
    'paused': paused,
    'urgentWords': urgentWords,
    'letStarredContactsThrough': letStarredContactsThrough,
    'setupDone': setupDone,
  };

  BatchSettings copyWith({
    Set<String>? batchedPackages,
    List<DeliveryTime>? deliveryTimes,
    bool? paused,
    List<String>? urgentWords,
    bool? letStarredContactsThrough,
    bool? setupDone,
  }) {
    return BatchSettings(
      batchedPackages: batchedPackages ?? this.batchedPackages,
      deliveryTimes: deliveryTimes == null
          ? this.deliveryTimes
          : DeliveryTime.normalize(deliveryTimes),
      paused: paused ?? this.paused,
      urgentWords: urgentWords == null ? this.urgentWords : normalizeWords(urgentWords),
      letStarredContactsThrough: letStarredContactsThrough ?? this.letStarredContactsThrough,
      setupDone: setupDone ?? this.setupDone,
    );
  }

  BatchSettings withApp(String packageName, {required bool batched}) {
    final packages = {...batchedPackages};
    batched ? packages.add(packageName) : packages.remove(packageName);
    return copyWith(batchedPackages: packages);
  }

  BatchSettings withTime(DeliveryTime time) => copyWith(deliveryTimes: [...deliveryTimes, time]);

  /// The last delivery time can't be removed: held notifications would never arrive.
  BatchSettings withoutTime(DeliveryTime time) {
    if (deliveryTimes.length <= 1) return this;
    return copyWith(deliveryTimes: deliveryTimes.where((t) => t != time).toList());
  }

  BatchSettings withUrgentWord(String word) => copyWith(urgentWords: [...urgentWords, word]);

  BatchSettings withoutUrgentWord(String word) =>
      copyWith(urgentWords: urgentWords.where((w) => w != word).toList());

  /// Trimmed, without blanks, and without duplicates that differ only in case.
  static List<String> normalizeWords(Iterable<String> words) {
    final seen = <String>{};
    return [
      for (final word in words.map((w) => w.trim()))
        if (word.isNotEmpty && seen.add(word.toLowerCase())) word,
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is BatchSettings &&
      _sameSet(other.batchedPackages, batchedPackages) &&
      _sameList(other.deliveryTimes, deliveryTimes) &&
      other.paused == paused &&
      _sameList(other.urgentWords, urgentWords) &&
      other.letStarredContactsThrough == letStarredContactsThrough &&
      other.setupDone == setupDone;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(batchedPackages),
    Object.hashAll(deliveryTimes),
    paused,
    Object.hashAll(urgentWords),
    letStarredContactsThrough,
    setupDone,
  );

  static bool _sameSet<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
