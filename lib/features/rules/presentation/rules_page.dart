import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/batch_platform.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/batch_settings.dart';
import '../../settings/presentation/settings_controller.dart';

class RulesPage extends ConsumerWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rulesTitle)),
      body: switch (settings) {
        AsyncValue(:final value?) => _Rules(settings: value),
        AsyncError() => ErrorView(onRetry: () => ref.invalidate(settingsControllerProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _Rules extends ConsumerWidget {
  const _Rules({required this.settings});

  final BatchSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(l10n.rulesBody, style: theme.textTheme.bodyLarge),
        ),
        _FixedRule(icon: Icons.call, title: l10n.ruleCalls, body: l10n.ruleCallsBody),
        _FixedRule(icon: Icons.password, title: l10n.ruleCodes, body: l10n.ruleCodesBody),
        _FixedRule(
          icon: Icons.play_circle_outline,
          title: l10n.ruleOngoing,
          body: l10n.ruleOngoingBody,
        ),
        _FixedRule(icon: Icons.apps, title: l10n.ruleOtherApps, body: l10n.ruleOtherAppsBody),
        SwitchListTile(
          secondary: const Icon(Icons.star_outline),
          title: Text(l10n.ruleStarred),
          subtitle: Text(l10n.ruleStarredBody),
          value: settings.letStarredContactsThrough,
          onChanged: (on) => _setStarred(context, ref, on),
        ),
        const Divider(height: 32),
        UrgentWords(words: settings.urgentWords),
      ],
    );
  }

  Future<void> _setStarred(BuildContext context, WidgetRef ref, bool on) async {
    final l10n = AppLocalizations.of(context);
    try {
      final done = await ref.read(settingsControllerProvider.notifier).setStarredContacts(on);
      if (!done && context.mounted) showMessage(context, l10n.ruleStarredDenied);
    } on BatchPlatformException {
      if (context.mounted) showMessage(context, l10n.saveFailed);
    }
  }
}

class _FixedRule extends StatelessWidget {
  const _FixedRule({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
      trailing: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class UrgentWords extends ConsumerStatefulWidget {
  const UrgentWords({required this.words, super.key});

  final List<String> words;

  @override
  ConsumerState<UrgentWords> createState() => _UrgentWordsState();
}

class _UrgentWordsState extends ConsumerState<UrgentWords> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.urgentTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.urgentBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          if (widget.words.isEmpty)
            Text(
              l10n.urgentEmpty,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in widget.words)
                  InputChip(
                    key: ValueKey(word),
                    label: Text(word),
                    deleteButtonTooltipMessage: l10n.urgentRemove(word),
                    onDeleted: () => _save(
                      () => ref.read(settingsControllerProvider.notifier).removeUrgentWord(word),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: l10n.urgentAdd,
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _add, child: Text(l10n.urgentAddButton)),
            ],
          ),
        ],
      ),
    );
  }

  void _add() {
    final word = _controller.text.trim();
    if (word.isEmpty) return;
    _controller.clear();
    _save(() => ref.read(settingsControllerProvider.notifier).addUrgentWord(word));
  }

  Future<void> _save(Future<void> Function() change) async {
    final failed = AppLocalizations.of(context).saveFailed;
    try {
      await change();
    } on BatchPlatformException {
      if (mounted) showMessage(context, failed);
    }
  }
}
