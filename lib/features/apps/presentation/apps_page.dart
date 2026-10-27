import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/batch_platform.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/app_suggester.dart';
import '../domain/installed_app.dart';
import 'app_icon.dart';
import 'apps_controller.dart';
import 'kind_label.dart';

class AppsPage extends ConsumerStatefulWidget {
  const AppsPage({super.key});

  @override
  ConsumerState<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends ConsumerState<AppsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(appsControllerProvider);
    final batched =
        ref.watch(settingsControllerProvider.select((s) => s.value?.batchedPackages)) ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appsTitle)),
      body: switch (apps) {
        AsyncValue(:final value?) => _list(context, value, batched),
        AsyncError() => ErrorView(onRetry: ref.read(appsControllerProvider.notifier).refresh),
        _ => const LoadingView(),
      },
    );
  }

  Widget _list(BuildContext context, List<InstalledApp> apps, Set<String> batched) {
    final l10n = AppLocalizations.of(context);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? apps
        : apps.where((a) => a.label.toLowerCase().contains(query)).toList();
    final batchedApps = visible.where((a) => batched.contains(a.packageName)).toList();
    final otherApps = visible.where((a) => !batched.contains(a.packageName)).toList();
    final suggestedLeft = [
      for (final app in AppSuggester.suggest(apps))
        if (!batched.contains(app.packageName)) app.packageName,
    ];
    final rows = <Object>[
      if (batchedApps.isNotEmpty) l10n.appsBatched,
      ...batchedApps,
      if (otherApps.isNotEmpty) l10n.appsNotBatched,
      ...otherApps,
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.appsSearch,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        if (query.isEmpty && suggestedLeft.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () => _save(
                  () => ref.read(settingsControllerProvider.notifier).batchAll(suggestedLeft),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.appsBatchSuggested),
              ),
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? SingleChildScrollView(
                  child: EmptyView(
                    icon: Icons.search_off,
                    title: l10n.appsEmptySearch(_query),
                    body: '',
                  ),
                )
              : ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) => switch (rows[index]) {
                    final InstalledApp app => AppTile(
                      key: ValueKey(app.packageName),
                      app: app,
                      batched: batched.contains(app.packageName),
                      onChanged: (on) => _save(
                        () => ref
                            .read(settingsControllerProvider.notifier)
                            .setBatched(app.packageName, batched: on),
                      ),
                    ),
                    final String header => _SectionHeader(
                      key: ValueKey('header-$header'),
                      text: header,
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
        ),
      ],
    );
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

class AppTile extends StatelessWidget {
  const AppTile({required this.app, required this.batched, required this.onChanged, super.key});

  final InstalledApp app;
  final bool batched;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final kind = AppSuggester.kindOf(app).label(AppLocalizations.of(context));
    return SwitchListTile(
      secondary: AppIcon(packageName: app.packageName, label: app.label),
      title: Text(app.label),
      subtitle: kind == null ? null : Text(kind),
      value: batched,
      onChanged: onChanged,
    );
  }
}
