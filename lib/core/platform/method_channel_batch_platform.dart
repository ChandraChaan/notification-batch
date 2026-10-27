import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/apps/domain/installed_app.dart';
import '../../features/inbox/domain/held_item.dart';
import '../../features/settings/domain/batch_settings.dart';
import '../../features/stats/domain/batch_stats.dart';
import '../../features/status/domain/batch_status.dart';
import 'batch_platform.dart';
import 'platform_codec.dart';

/// Talks to `PlatformBridge.kt`.
class MethodChannelBatchPlatform implements BatchPlatform {
  MethodChannelBatchPlatform({
    this._methods = const MethodChannel('notification_batch/platform'),
    this._events = const EventChannel('notification_batch/changes'),
  });

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  late final Stream<void> changes = _events.receiveBroadcastStream().map((_) {});

  @override
  Future<BatchStatus> status() async => PlatformCodec.status(await _call<Object?>('getStatus'));

  @override
  Future<BatchSettings> settings() async {
    final json = await _call<String>('getSettings');
    if (json == null) throw const BatchPlatformException('no_settings');
    return BatchSettings.fromJson(jsonDecode(json) as Map<String, Object?>);
  }

  @override
  Future<void> saveSettings(BatchSettings settings) =>
      _call<void>('saveSettings', jsonEncode(settings.toJson()));

  @override
  Future<List<HeldItem>> held() async => PlatformCodec.items(await _call<Object?>('getHeld'));

  @override
  Future<List<HeldItem>> delivered() async =>
      PlatformCodec.items(await _call<Object?>('getDelivered'));

  @override
  Future<void> deliverNow() => _call<void>('deliverNow');

  @override
  Future<StatsSnapshot> stats() async => PlatformCodec.stats(await _call<Object?>('getStats'));

  @override
  Future<bool> openItem(String id) async => await _call<bool>('openItem', id) ?? false;

  @override
  Future<List<InstalledApp>> installedApps() async =>
      PlatformCodec.apps(await _call<Object?>('getInstalledApps'));

  @override
  Future<Uint8List?> appIcon(String packageName) => _call<Uint8List>('getAppIcon', packageName);

  @override
  Future<bool> openListenerSettings() async => await _call<bool>('openListenerSettings') ?? false;

  @override
  Future<bool> openAppDetails() async => await _call<bool>('openAppDetails') ?? false;

  @override
  Future<bool> openExactAlarmSettings() async =>
      await _call<bool>('openExactAlarmSettings') ?? false;

  @override
  Future<bool> requestPostNotifications() async =>
      await _call<bool>('requestPostNotifications') ?? false;

  @override
  Future<bool> requestContacts() async => await _call<bool>('requestContacts') ?? false;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _methods.invokeMethod<T>(method, arguments).timeout(const Duration(seconds: 20));
    } on PlatformException catch (error, stack) {
      debugPrint('Notification Batch: $method failed with ${error.code}\n$stack');
      throw BatchPlatformException(error.code);
    } on MissingPluginException {
      throw const BatchPlatformException('unavailable');
    }
  }
}
