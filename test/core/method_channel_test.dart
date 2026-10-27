import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/core/platform/batch_platform.dart';
import 'package:notification_batch/core/platform/method_channel_batch_platform.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('notification_batch/platform');
  final calls = <MethodCall>[];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'getSettings' => jsonEncode(const BatchSettings(paused: true).toJson()),
        'getHeld' => [
          {'id': '1', 'packageName': 'p', 'postedAt': 0},
        ],
        'openItem' => true,
        'deliverNow' => null,
        'saveSettings' => null,
        _ => throw PlatformException(code: 'failed'),
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('settings travel as the shared JSON format', () async {
    final platform = MethodChannelBatchPlatform();
    expect((await platform.settings()).paused, isTrue);
    await platform.saveSettings(const BatchSettings(batchedPackages: {'x'}));
    final sent = jsonDecode(calls.last.arguments as String) as Map<String, Object?>;
    expect(sent['batchedPackages'], ['x']);
    expect(sent['version'], 1);
  });

  test('passes arguments and reads replies', () async {
    final platform = MethodChannelBatchPlatform();
    expect((await platform.held()).single.id, '1');
    expect(await platform.openItem('1'), isTrue);
    expect(calls.last.arguments, '1');
    await platform.deliverNow();
    expect(calls.last.method, 'deliverNow');
  });

  test('platform errors become typed exceptions', () async {
    final platform = MethodChannelBatchPlatform();
    await expectLater(
      platform.status(),
      throwsA(isA<BatchPlatformException>().having((e) => e.code, 'code', 'failed')),
    );
  });
}
