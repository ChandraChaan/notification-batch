import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/core/platform/batch_platform.dart';
import 'package:notification_batch/core/platform/platform_codec.dart';
import 'package:notification_batch/features/apps/domain/installed_app.dart';
import 'package:notification_batch/features/stats/domain/batch_stats.dart';

void main() {
  test('reads a full status', () {
    final status = PlatformCodec.status({
      'listenerEnabled': true,
      'listenerConnected': true,
      'notificationsAllowed': false,
      'contactsAllowed': true,
      'exactAlarmsAllowed': false,
      'nextDeliveryAt': 1793088000000,
      'heldCount': 4,
      'lastDeliveryAt': null,
    });
    expect(status.listenerEnabled, isTrue);
    expect(status.notificationsAllowed, isFalse);
    expect(status.exactAlarmsAllowed, isFalse);
    expect(status.nextDeliveryAt, DateTime.fromMillisecondsSinceEpoch(1793088000000, isUtc: true));
    expect(status.heldCount, 4);
    expect(status.lastDeliveryAt, isNull);
  });

  test('missing status fields fall back to safe values', () {
    final status = PlatformCodec.status(<String, Object?>{});
    expect(status.listenerEnabled, isFalse);
    expect(status.notificationsAllowed, isTrue);
    expect(status.heldCount, 0);
  });

  test('reads held items with UTC times', () {
    final items = PlatformCodec.items([
      {
        'id': '1:key',
        'packageName': 'com.example.shop',
        'appLabel': 'Shop',
        'title': 'Sale',
        'text': 'Today only',
        'postedAt': 0,
      },
      {'id': '2', 'packageName': 'com.example.food'},
    ]);
    expect(items.first.title, 'Sale');
    expect(items.first.postedAt.isUtc, isTrue);
    expect(items.last.appLabel, 'com.example.food');
    expect(items.last.text, '');
  });

  test('reads installed apps', () {
    final apps = PlatformCodec.apps([
      {'packageName': 'a', 'label': 'A', 'category': 0, 'isSystem': true, 'isDefaultSms': false},
      {'packageName': 'b', 'category': 99},
    ]);
    expect(apps.first.category, AppCategory.game);
    expect(apps.first.isSystem, isTrue);
    expect(apps.last.label, 'b');
    expect(apps.last.category, AppCategory.undefined);
  });

  test('a reply of the wrong shape is a typed error', () {
    expect(() => PlatformCodec.status('nope'), throwsA(isA<BatchPlatformException>()));
    expect(() => PlatformCodec.items(42), throwsA(isA<BatchPlatformException>()));
    expect(PlatformCodec.items(null), isEmpty);
  });

  test('reads stats and skips reasons it does not know', () {
    final stats = PlatformCodec.stats({
      'today': '2026-10-28',
      'days': [
        {
          'date': '2026-10-28',
          'held': {'com.example.shop': 3},
          'letThrough': {'VERIFICATION_CODE': 2, 'FROM_THE_FUTURE': 1},
        },
      ],
      'labels': {'com.example.shop': 'Shop'},
    });
    expect(stats.today, Day.parse('2026-10-28'));
    expect(stats.days.single.held, {'com.example.shop': 3});
    expect(stats.days.single.letThrough, {LetThroughReason.verificationCode: 2});
    expect(stats.labels, {'com.example.shop': 'Shop'});
  });

  test('a stats reply with a bad date is a typed error', () {
    expect(
      () => PlatformCodec.stats({'today': 'soon', 'days': <Object?>[]}),
      throwsA(isA<BatchPlatformException>()),
    );
  });
}
