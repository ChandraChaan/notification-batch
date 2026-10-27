import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../apps/presentation/app_icon.dart';
import '../domain/batch_stats.dart';
import 'stats_controller.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(statsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: switch (stats) {
        AsyncValue(:final value?) => _Stats(summary: value),
        AsyncError() => ErrorView(onRetry: ref.read(statsControllerProvider.notifier).refresh),
        _ => const LoadingView(),
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.summary});

  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final note = Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        l10n.statsPrivacy,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
    if (summary.isEmpty) {
      return ListView(
        children: [
          EmptyView(icon: Icons.insights, title: l10n.statsEmptyTitle, body: l10n.statsEmptyBody),
          note,
        ],
      );
    }
    final maxApp = summary.noisiestApps.isEmpty ? 1 : summary.noisiestApps.first.count;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _BigNumber(label: l10n.statsSavedToday, count: summary.savedToday),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigNumber(label: l10n.statsSavedWeek, count: summary.savedThisWeek),
              ),
            ],
          ),
        ),
        _Heading(l10n.statsLastSeven),
        _WeekBars(days: summary.lastSevenDays),
        if (summary.noisiestApps.isNotEmpty) ...[
          _Heading(l10n.statsNoisiest),
          for (final app in summary.noisiestApps)
            ListTile(
              key: ValueKey(app.packageName),
              leading: AppIcon(packageName: app.packageName, label: app.label),
              title: Text(app.label),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: app.count / maxApp,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              trailing: Text(l10n.statsAppCount(app.count)),
            ),
        ],
        _Heading(l10n.statsLetThrough),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: summary.letThroughThisWeek.isEmpty
              ? Text(l10n.statsLetThroughNone)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.statsLetThroughBody, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final MapEntry(key: reason, value: count)
                            in summary.letThroughThisWeek.entries)
                          Chip(label: Text(l10n.reasonCount(reasonLabel(l10n, reason), count))),
                      ],
                    ),
                  ],
                ),
        ),
        note,
      ],
    );
  }
}

String reasonLabel(AppLocalizations l10n, LetThroughReason reason) => switch (reason) {
  LetThroughReason.call => l10n.reasonCall,
  LetThroughReason.alarm => l10n.reasonAlarm,
  LetThroughReason.fullScreen => l10n.reasonFullScreen,
  LetThroughReason.ongoing => l10n.reasonOngoing,
  LetThroughReason.media => l10n.reasonMedia,
  LetThroughReason.timeSensitive => l10n.reasonTimeSensitive,
  LetThroughReason.verificationCode => l10n.reasonVerificationCode,
  LetThroughReason.urgentWord => l10n.reasonUrgentWord,
  LetThroughReason.starredContact => l10n.reasonStarredContact,
  LetThroughReason.nothingToShow => l10n.reasonNothingToShow,
};

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(header: true, child: Text(text, style: theme.textTheme.titleMedium)),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.decimalPattern(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(count),
              style: theme.textTheme.displaySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
            Text(
              AppLocalizations.of(context).statsInterruptions(count),
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days});

  static const _barHeight = 96.0;

  final List<DayStats> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final most = days.fold(0, (max, day) => day.heldTotal > max ? day.heldTotal : max);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (index, day) in days.indexed)
            Expanded(
              child: Semantics(
                container: true,
                label: l10n.statsDayBar(_weekday(locale, day, long: true), day.heldTotal),
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Text('${day.heldTotal}', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Container(
                        height: most == 0 ? 2 : 2 + (_barHeight - 2) * day.heldTotal / most,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: index == days.length - 1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekday(locale, day),
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _weekday(String locale, DayStats day, {bool long = false}) {
    final date = DateTime.utc(day.day.year, day.day.month, day.day.day);
    return (long ? DateFormat.EEEE(locale) : DateFormat.E(locale)).format(date);
  }
}
