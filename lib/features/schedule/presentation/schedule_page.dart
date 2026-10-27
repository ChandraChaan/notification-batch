import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/platform/batch_platform.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/batch_settings.dart';
import '../../settings/domain/delivery_time.dart';
import '../../settings/presentation/settings_controller.dart';
import '../../status/presentation/status_controller.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleTitle)),
      body: switch (settings) {
        AsyncValue(:final value?) => _ScheduleList(settings: value),
        AsyncError() => ErrorView(onRetry: () => ref.invalidate(settingsControllerProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _ScheduleList extends ConsumerWidget {
  const _ScheduleList({required this.settings});

  final BatchSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exactAllowed =
        ref.watch(statusControllerProvider.select((s) => s.value?.exactAlarmsAllowed)) ?? true;
    final times = settings.deliveryTimes;
    final canRemove = times.length > 1;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(l10n.scheduleBody, style: theme.textTheme.bodyLarge),
        ),
        for (final time in times)
          ListTile(
            key: ValueKey(time.minutes),
            leading: const Icon(Icons.schedule),
            title: Text(
              formatTimeOfDay(context, TimeOfDay(hour: time.hour, minute: time.minute)),
              style: theme.textTheme.titleLarge,
            ),
            trailing: IconButton(
              tooltip: canRemove
                  ? l10n.scheduleRemove(
                      formatTimeOfDay(context, TimeOfDay(hour: time.hour, minute: time.minute)),
                    )
                  : l10n.scheduleLastOne,
              icon: const Icon(Icons.delete_outline),
              onPressed: canRemove
                  ? () => _save(context, () => _controller(ref).removeTime(time))
                  : null,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: () => _addTime(context, ref),
              icon: const Icon(Icons.add_alarm),
              label: Text(l10n.scheduleAdd),
            ),
          ),
        ),
        if (!exactAllowed)
          Card.filled(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.scheduleExactTitle),
              subtitle: Text(l10n.scheduleExactBody),
              trailing: TextButton(
                onPressed: ref.read(statusControllerProvider.notifier).openExactAlarmSettings,
                child: Text(l10n.scheduleExactButton),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.scheduleTimeZone,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  SettingsController _controller(WidgetRef ref) => ref.read(settingsControllerProvider.notifier);

  Future<void> _addTime(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked == null || !context.mounted) return;
    await _save(
      context,
      () => _controller(ref).addTime(DeliveryTime.at(picked.hour, picked.minute)),
    );
  }

  Future<void> _save(BuildContext context, Future<void> Function() change) async {
    final failed = AppLocalizations.of(context).saveFailed;
    try {
      await change();
    } on BatchPlatformException {
      if (context.mounted) showMessage(context, failed);
    }
  }
}
