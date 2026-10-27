import 'dart:typed_data';

import '../../features/apps/domain/installed_app.dart';
import '../../features/inbox/domain/held_item.dart';
import '../../features/settings/domain/batch_settings.dart';
import '../../features/status/domain/batch_status.dart';

/// Everything the app needs from Android. The notification listener, the store and the alarms
/// live in Kotlin because they must keep working while this UI is closed.
///
/// The real implementation is `MethodChannelBatchPlatform`; tests use a fake.
abstract interface class BatchPlatform {
  Future<BatchStatus> status();

  Future<BatchSettings> settings();

  Future<void> saveSettings(BatchSettings settings);

  /// Waiting for the next delivery, newest first.
  Future<List<HeldItem>> held();

  /// Delivered in the last two days, newest first.
  Future<List<HeldItem>> delivered();

  Future<void> deliverNow();

  /// Opens what the notification pointed at, or its app. False if neither is possible.
  Future<bool> openItem(String id);

  Future<List<InstalledApp>> installedApps();

  /// A small PNG, or null if the app is gone.
  Future<Uint8List?> appIcon(String packageName);

  Future<bool> openListenerSettings();

  Future<bool> openAppDetails();

  Future<bool> openExactAlarmSettings();

  Future<bool> requestPostNotifications();

  Future<bool> requestContacts();

  /// Fires whenever held items, settings or the listener's state change.
  Stream<void> get changes;
}

/// Android could not do what was asked. [code] is safe to log; it never contains user data.
class BatchPlatformException implements Exception {
  const BatchPlatformException(this.code);

  final String code;

  @override
  String toString() => 'BatchPlatformException($code)';
}
