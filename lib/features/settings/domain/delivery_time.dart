/// A time of day at which held notifications are delivered, in minutes after local midnight.
class DeliveryTime implements Comparable<DeliveryTime> {
  const DeliveryTime(this.minutes);

  const DeliveryTime.at(int hour, [int minute = 0]) : minutes = hour * 60 + minute;

  static const minutesPerDay = 24 * 60;

  /// 09:00, 13:00 and 19:00: morning, lunch and evening.
  static const defaults = [DeliveryTime.at(9), DeliveryTime.at(13), DeliveryTime.at(19)];

  final int minutes;

  int get hour => minutes ~/ 60;

  int get minute => minutes % 60;

  bool get isValid => minutes >= 0 && minutes < minutesPerDay;

  /// Sorted and unique. Falls back to [defaults] when nothing valid is left, because a batch
  /// with no delivery time would never arrive.
  static List<DeliveryTime> normalize(Iterable<DeliveryTime> times) {
    final valid = {
      for (final time in times)
        if (time.isValid) time.minutes,
    }.toList()..sort();
    if (valid.isEmpty) return defaults;
    return [for (final minutes in valid) DeliveryTime(minutes)];
  }

  @override
  int compareTo(DeliveryTime other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) => other is DeliveryTime && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
