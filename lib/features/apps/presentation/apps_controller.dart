import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/installed_app.dart';

final appsControllerProvider = AsyncNotifierProvider<AppsController, List<InstalledApp>>(
  AppsController.new,
);

/// Apps with a launcher icon, sorted by name.
class AppsController extends AsyncNotifier<List<InstalledApp>> {
  @override
  Future<List<InstalledApp>> build() async {
    final apps = await ref.watch(batchPlatformProvider).installedApps();
    return [...apps]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  void refresh() => ref.invalidateSelf();
}

final appIconProvider = FutureProvider.family<Uint8List?, String>(
  (ref, packageName) => ref.watch(batchPlatformProvider).appIcon(packageName),
);
