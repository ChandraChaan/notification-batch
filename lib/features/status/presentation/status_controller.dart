import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/batch_status.dart';

final statusControllerProvider = AsyncNotifierProvider<StatusController, BatchStatus>(
  StatusController.new,
);

/// Permissions and where the batch stands. Reloads when Android reports a change and when the
/// app comes back to the foreground (the user may have just changed a system setting).
class StatusController extends AsyncNotifier<BatchStatus> {
  @override
  Future<BatchStatus> build() {
    ref.watch(changeTickProvider);
    return ref.watch(batchPlatformProvider).status();
  }

  void refresh() => ref.invalidateSelf();

  Future<bool> openListenerSettings() => ref.read(batchPlatformProvider).openListenerSettings();

  Future<bool> openAppDetails() => ref.read(batchPlatformProvider).openAppDetails();

  Future<void> openExactAlarmSettings() async {
    await ref.read(batchPlatformProvider).openExactAlarmSettings();
  }

  /// Asks Android; once the user has said no twice Android stops asking, so open App info instead.
  Future<void> requestPostNotifications() async {
    final platform = ref.read(batchPlatformProvider);
    if (!await platform.requestPostNotifications()) await platform.openAppDetails();
    if (ref.mounted) refresh();
  }
}

/// Which screen the app should be on.
enum Gate { loading, error, needsAccess, needsSetup, ready }
