import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/batch_platform.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../apps/domain/app_suggester.dart';
import '../../apps/domain/installed_app.dart';
import '../../apps/presentation/app_icon.dart';
import '../../apps/presentation/apps_controller.dart';
import '../../apps/presentation/kind_label.dart';
import '../../settings/presentation/settings_controller.dart';

/// First run: suggested apps, ticked, for the user to confirm.
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  Set<String>? _selected;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(appsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: switch (apps) {
        AsyncValue(:final value?) => _content(context, AppSuggester.suggest(value)),
        AsyncError() => ErrorView(onRetry: ref.read(appsControllerProvider.notifier).refresh),
        _ => const LoadingView(),
      },
    );
  }

  Widget _content(BuildContext context, List<InstalledApp> suggested) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selected = _selected ??= {for (final app in suggested) app.packageName};
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: suggested.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggested.isEmpty ? l10n.setupNone : l10n.setupBody,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.setupHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final app = suggested[index - 1];
              return CheckboxListTile(
                key: ValueKey(app.packageName),
                secondary: AppIcon(packageName: app.packageName, label: app.label),
                title: Text(app.label),
                subtitle: Text(AppSuggester.kindOf(app).label(l10n) ?? ''),
                value: selected.contains(app.packageName),
                onChanged: (on) => setState(() {
                  on == true ? selected.add(app.packageName) : selected.remove(app.packageName);
                }),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.setupCount(selected.length), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving || selected.isEmpty ? null : () => _finish(selected),
                  child: Text(l10n.setupStart),
                ),
                TextButton(
                  onPressed: _saving ? null : () => _finish(const {}),
                  child: Text(l10n.setupSkip),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _finish(Set<String> packages) async {
    final failed = AppLocalizations.of(context).saveFailed;
    setState(() => _saving = true);
    try {
      await ref.read(settingsControllerProvider.notifier).completeSetup(packages);
    } on BatchPlatformException {
      if (mounted) showMessage(context, failed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
