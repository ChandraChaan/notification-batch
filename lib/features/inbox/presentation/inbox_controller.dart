import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/held_item.dart';

class InboxState {
  const InboxState({required this.held, required this.delivered});

  final List<HeldItem> held;
  final List<HeldItem> delivered;
}

final inboxControllerProvider = AsyncNotifierProvider<InboxController, InboxState>(
  InboxController.new,
);

class InboxController extends AsyncNotifier<InboxState> {
  @override
  Future<InboxState> build() async {
    ref.watch(changeTickProvider);
    final platform = ref.watch(batchPlatformProvider);
    final (held, delivered) = await (platform.held(), platform.delivered()).wait;
    return InboxState(held: held, delivered: delivered);
  }

  void refresh() => ref.invalidateSelf();

  Future<void> deliverNow() => ref.read(batchPlatformProvider).deliverNow();

  /// False if neither the notification's own action nor its app can be opened.
  Future<bool> open(HeldItem item) => ref.read(batchPlatformProvider).openItem(item.id);
}
