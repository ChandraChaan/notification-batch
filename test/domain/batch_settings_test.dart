import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/settings/domain/delivery_time.dart';

void main() {
  group('BatchSettings', () {
    test('reads the settings file that the Kotlin side also reads', () {
      // spec/settings.json is shared with the Kotlin tests so both sides agree on the format.
      final json =
          jsonDecode(File('spec/settings.json').readAsStringSync()) as Map<String, Object?>;
      final settings = BatchSettings.fromJson(json);
      expect(settings.batchedPackages, {'com.example.games', 'com.example.shop'});
      expect(settings.deliveryTimes, const [
        DeliveryTime.at(9),
        DeliveryTime.at(13),
        DeliveryTime.at(19),
      ]);
      expect(settings.urgentWords, ['flight', 'delivered']);
      expect(settings.letStarredContactsThrough, isTrue);
      expect(settings.setupDone, isTrue);
      expect(settings.paused, isFalse);
      expect(settings.toJson(), json);
    });

    test('survives a JSON round trip', () {
      final settings = const BatchSettings().copyWith(
        batchedPackages: {'b', 'a'},
        deliveryTimes: const [DeliveryTime.at(20, 30)],
        paused: true,
        urgentWords: ['Gate'],
      );
      expect(BatchSettings.fromJson(settings.toJson()), settings);
    });

    test('ignores values of the wrong type and keeps safe defaults', () {
      final settings = BatchSettings.fromJson({
        'batchedPackages': ['ok', 3, null],
        'deliveryMinutes': 'nine',
        'paused': 'yes',
        'urgentWords': [' ', 'bank', 'BANK'],
      });
      expect(settings.batchedPackages, {'ok'});
      expect(settings.deliveryTimes, DeliveryTime.defaults);
      expect(settings.paused, isFalse);
      expect(settings.urgentWords, ['bank']);
    });

    test('adds and removes apps', () {
      final settings = const BatchSettings()
          .withApp('a', batched: true)
          .withApp('b', batched: true);
      expect(settings.batchedPackages, {'a', 'b'});
      expect(settings.withApp('a', batched: false).batchedPackages, {'b'});
    });

    test('keeps delivery times sorted and unique', () {
      final settings = const BatchSettings()
          .withTime(const DeliveryTime.at(7, 30))
          .withTime(const DeliveryTime.at(13));
      expect(settings.deliveryTimes.map((t) => t.toString()), ['07:30', '09:00', '13:00', '19:00']);
    });

    test('never removes the last delivery time', () {
      final one = const BatchSettings().copyWith(deliveryTimes: const [DeliveryTime.at(12)]);
      expect(one.withoutTime(const DeliveryTime.at(12)), one);
      expect(const BatchSettings().withoutTime(const DeliveryTime.at(13)).deliveryTimes, const [
        DeliveryTime.at(9),
        DeliveryTime.at(19),
      ]);
    });

    test('urgent words are trimmed and deduplicated ignoring case', () {
      final settings = const BatchSettings()
          .withUrgentWord(' Flight ')
          .withUrgentWord('flight')
          .withUrgentWord('');
      expect(settings.urgentWords, ['Flight']);
      expect(settings.withoutUrgentWord('Flight').urgentWords, isEmpty);
    });

    test('equality ignores the order of packages', () {
      expect(
        const BatchSettings(batchedPackages: {'a', 'b'}),
        const BatchSettings(batchedPackages: {'b', 'a'}),
      );
      expect(
        const BatchSettings(batchedPackages: {'a', 'b'}).hashCode,
        const BatchSettings(batchedPackages: {'b', 'a'}).hashCode,
      );
    });
  });

  group('DeliveryTime', () {
    test('drops times outside the day and falls back to the defaults', () {
      expect(
        DeliveryTime.normalize(const [DeliveryTime(-1), DeliveryTime(1440)]),
        DeliveryTime.defaults,
      );
      expect(DeliveryTime.normalize(const [DeliveryTime(0), DeliveryTime(1439)]).map((t) => '$t'), [
        '00:00',
        '23:59',
      ]);
    });

    test('splits minutes into hour and minute', () {
      const time = DeliveryTime.at(19, 45);
      expect((time.hour, time.minute, time.minutes), (19, 45, 1185));
    });
  });
}
