import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/platform/batch_platform.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/batch_settings.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../status/domain/batch_status.dart';
import '../../status/presentation/status_controller.dart';
import 'inbox_controller.dart';

/// Next delivery, how much is held, the pause switch and "Deliver now".
class StatusCard extends ConsumerWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusControllerProvider).value;
    final settings = ref.watch(settingsControllerProvider).value;
    if (status == null || settings == null) return const SizedBox.shrink();
    return Column(
      children: [
        _Summary(status: status, settings: settings),
        if (!status.notificationsAllowed) const _NotificationsOffBanner(),
      ],
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.status, required this.settings});

  final BatchStatus status;
  final BatchSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final headline = settings.paused ? l10n.statusPaused : _nextDelivery(context, ref);
    return Card.filled(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: settings.paused ? scheme.surfaceContainerHighest : scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headline, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        settings.paused ? l10n.statusPausedBody : l10n.statusHeld(status.heldCount),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: l10n.statusBatching,
                  child: Switch(
                    value: !settings.paused,
                    onChanged: (on) => _setPaused(context, ref, paused: !on),
                  ),
                ),
              ],
            ),
            if (settings.batchedPackages.isEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(l10n.statusNoApps),
                  TextButton(
                    onPressed: () => context.go('/apps'),
                    child: Text(l10n.statusChooseApps),
                  ),
                ],
              ),
            ],
            if (!status.listenerConnected) ...[
              const SizedBox(height: 8),
              Text(l10n.listenerWaiting, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: status.heldCount == 0 ? null : () => _deliverNow(context, ref),
              icon: const Icon(Icons.send),
              label: Text(l10n.deliverNow),
            ),
          ],
        ),
      ),
    );
  }

  String _nextDelivery(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final next = status.nextDeliveryAt;
    if (next == null) return l10n.statusHeld(status.heldCount);
    final time = formatTime(context, next);
    return switch (deliveryDay(next, ref.read(clockProvider)())) {
      DeliveryDay.today => l10n.statusNextToday(time),
      DeliveryDay.tomorrow => l10n.statusNextTomorrow(time),
      DeliveryDay.later => l10n.statusNextLater(formatWeekday(context, next), time),
    };
  }

  Future<void> _setPaused(BuildContext context, WidgetRef ref, {required bool paused}) async {
    final failed = AppLocalizations.of(context).saveFailed;
    try {
      await ref.read(settingsControllerProvider.notifier).setPaused(paused);
    } on BatchPlatformException {
      if (context.mounted) showMessage(context, failed);
    }
  }

  Future<void> _deliverNow(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(inboxControllerProvider.notifier).deliverNow();
      if (context.mounted) showMessage(context, l10n.delivering);
    } on BatchPlatformException {
      if (context.mounted) showMessage(context, l10n.errorGeneric);
    }
  }
}

class _NotificationsOffBanner extends ConsumerWidget {
  const _NotificationsOffBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card.filled(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.notifications_off_outlined, color: scheme.onErrorContainer),
        title: Text(l10n.notificationsOffTitle, style: TextStyle(color: scheme.onErrorContainer)),
        subtitle: Text(l10n.notificationsOffBody, style: TextStyle(color: scheme.onErrorContainer)),
        trailing: TextButton(
          onPressed: ref.read(statusControllerProvider.notifier).requestPostNotifications,
          child: Text(l10n.notificationsOffButton),
        ),
      ),
    );
  }
}
