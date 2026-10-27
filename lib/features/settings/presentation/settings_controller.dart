import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/batch_platform.dart';
import '../../../core/providers.dart';
import '../../status/presentation/status_controller.dart';
import '../domain/batch_settings.dart';
import '../domain/delivery_time.dart';

final settingsControllerProvider = AsyncNotifierProvider<SettingsController, BatchSettings>(
  SettingsController.new,
);

/// The user's choices. Changes show immediately and are rolled back if Android can't save them.
class SettingsController extends AsyncNotifier<BatchSettings> {
  BatchPlatform get _platform => ref.read(batchPlatformProvider);

  @override
  Future<BatchSettings> build() => ref.watch(batchPlatformProvider).settings();

  Future<void> setPaused(bool paused) => _save((s) => s.copyWith(paused: paused));

  Future<void> setBatched(String packageName, {required bool batched}) =>
      _save((s) => s.withApp(packageName, batched: batched));

  Future<void> batchAll(Iterable<String> packageNames) =>
      _save((s) => s.copyWith(batchedPackages: {...s.batchedPackages, ...packageNames}));

  /// Finishes the first-run picker and asks for permission to post the batch summary.
  Future<void> completeSetup(Set<String> packageNames) async {
    await _save(
      (s) => s.copyWith(batchedPackages: {...s.batchedPackages, ...packageNames}, setupDone: true),
    );
    await _platform.requestPostNotifications();
  }

  Future<void> addTime(DeliveryTime time) => _save((s) => s.withTime(time));

  Future<void> removeTime(DeliveryTime time) => _save((s) => s.withoutTime(time));

  Future<void> addUrgentWord(String word) => _save((s) => s.withUrgentWord(word));

  Future<void> removeUrgentWord(String word) => _save((s) => s.withoutUrgentWord(word));

  /// Turning it on asks for contacts access first. Returns false if access was refused.
  Future<bool> setStarredContacts(bool on) async {
    if (on && !await _platform.requestContacts()) return false;
    await _save((s) => s.copyWith(letStarredContactsThrough: on));
    ref.invalidate(statusControllerProvider);
    return true;
  }

  Future<void> _save(BatchSettings Function(BatchSettings) change) async {
    final current = await future;
    final next = change(current);
    if (next == current) return;
    state = AsyncData(next);
    try {
      await _platform.saveSettings(next);
    } on BatchPlatformException {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}

/// Decides between the welcome screen, the first-run picker and the app itself.
final gateProvider = Provider<Gate>((ref) {
  final status = ref.watch(statusControllerProvider);
  final settings = ref.watch(settingsControllerProvider);
  final statusValue = status.value;
  final settingsValue = settings.value;
  if ((status.hasError && statusValue == null) || (settings.hasError && settingsValue == null)) {
    return Gate.error;
  }
  if (statusValue == null || settingsValue == null) return Gate.loading;
  if (!statusValue.listenerEnabled) return Gate.needsAccess;
  if (!settingsValue.setupDone) return Gate.needsSetup;
  return Gate.ready;
});
