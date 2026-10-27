import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/batch_stats.dart';

final statsControllerProvider = AsyncNotifierProvider<StatsController, StatsSummary>(
  StatsController.new,
);

class StatsController extends AsyncNotifier<StatsSummary> {
  @override
  Future<StatsSummary> build() async {
    ref.watch(changeTickProvider);
    return StatsSummary.from(await ref.watch(batchPlatformProvider).stats());
  }

  void refresh() => ref.invalidateSelf();
}
