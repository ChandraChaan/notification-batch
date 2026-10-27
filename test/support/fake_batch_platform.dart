import 'dart:async';
import 'dart:typed_data';

import 'package:notification_batch/core/platform/batch_platform.dart';
import 'package:notification_batch/features/apps/domain/installed_app.dart';
import 'package:notification_batch/features/inbox/domain/held_item.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/stats/domain/batch_stats.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';

/// An in-memory Android. Set fields to shape what the UI sees; read the logs to check calls.
class FakeBatchPlatform implements BatchPlatform {
  FakeBatchPlatform({
    this.currentStatus = const BatchStatus(listenerEnabled: true, listenerConnected: true),
    this.currentSettings = const BatchSettings(setupDone: true),
    this.heldItems = const [],
    this.deliveredItems = const [],
    this.apps = const [],
    StatsSnapshot? statsSnapshot,
  }) : statsSnapshot = statsSnapshot ?? StatsSnapshot(today: Day.parse('2026-10-27'));

  BatchStatus currentStatus;
  BatchSettings currentSettings;
  List<HeldItem> heldItems;
  List<HeldItem> deliveredItems;
  List<InstalledApp> apps;
  StatsSnapshot statsSnapshot;

  /// When set, every call fails with this code.
  String? failWith;

  /// When set, only saving fails.
  bool failSaves = false;

  bool grantContacts = true;
  bool grantNotifications = true;
  bool canOpenItems = true;

  final saved = <BatchSettings>[];
  final opened = <String>[];
  final calls = <String>[];
  final _changes = StreamController<void>.broadcast();

  void emitChange() => _changes.add(null);

  Future<T> _answer<T>(String name, T Function() value) async {
    calls.add(name);
    final code = failWith;
    if (code != null) throw BatchPlatformException(code);
    return value();
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<BatchStatus> status() => _answer('status', () => currentStatus);

  @override
  Future<BatchSettings> settings() => _answer('settings', () => currentSettings);

  @override
  Future<void> saveSettings(BatchSettings settings) => _answer('saveSettings', () {
    if (failSaves) throw const BatchPlatformException('save_failed');
    saved.add(settings);
    currentSettings = settings;
  });

  @override
  Future<List<HeldItem>> held() => _answer('held', () => heldItems);

  @override
  Future<List<HeldItem>> delivered() => _answer('delivered', () => deliveredItems);

  @override
  Future<void> deliverNow() => _answer('deliverNow', () {
    deliveredItems = [...heldItems, ...deliveredItems];
    heldItems = const [];
  });

  @override
  Future<StatsSnapshot> stats() => _answer('stats', () => statsSnapshot);

  @override
  Future<bool> openItem(String id) => _answer('openItem', () {
    opened.add(id);
    return canOpenItems;
  });

  @override
  Future<List<InstalledApp>> installedApps() => _answer('installedApps', () => apps);

  @override
  Future<Uint8List?> appIcon(String packageName) => _answer('appIcon', () => null);

  @override
  Future<bool> openListenerSettings() => _answer('openListenerSettings', () => true);

  @override
  Future<bool> openAppDetails() => _answer('openAppDetails', () => true);

  @override
  Future<bool> openExactAlarmSettings() => _answer('openExactAlarmSettings', () => true);

  @override
  Future<bool> requestPostNotifications() =>
      _answer('requestPostNotifications', () => grantNotifications);

  @override
  Future<bool> requestContacts() => _answer('requestContacts', () => grantContacts);

  Future<void> close() => _changes.close();
}
