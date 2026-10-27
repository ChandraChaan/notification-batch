import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/core/format.dart';

void main() {
  final now = DateTime(2026, 10, 27, 22, 30);

  test('later the same day is today', () {
    expect(deliveryDay(DateTime(2026, 10, 27, 23), now), DeliveryDay.today);
  });

  test('just after midnight is tomorrow', () {
    expect(deliveryDay(DateTime(2026, 10, 28, 0, 1), now), DeliveryDay.tomorrow);
  });

  test('across the end of a month and a year', () {
    expect(deliveryDay(DateTime(2026, 11, 1, 9), DateTime(2026, 10, 31, 20)), DeliveryDay.tomorrow);
    expect(deliveryDay(DateTime(2027, 1, 1, 9), DateTime(2026, 12, 31, 20)), DeliveryDay.tomorrow);
  });

  test('two days away is later', () {
    expect(deliveryDay(DateTime(2026, 10, 29, 9), now), DeliveryDay.later);
  });

  test('accepts UTC times and compares them in local time', () {
    final next = DateTime(2026, 10, 28, 9).toUtc();
    expect(deliveryDay(next, now), DeliveryDay.tomorrow);
  });
}
