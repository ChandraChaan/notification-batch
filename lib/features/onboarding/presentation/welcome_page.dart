import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../status/presentation/status_controller.dart';

/// Explains what notification access means before sending the user to Android's settings.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = ref.read(statusControllerProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Icon(Icons.layers_outlined, size: 56, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(l10n.welcomeTitle, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 12),
              Text(l10n.welcomeBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(l10n.welcomeAlwaysThrough, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 28),
              Text(l10n.accessTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l10n.accessBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              _Promise(icon: Icons.checklist, text: l10n.accessPromiseOnly),
              _Promise(icon: Icons.phonelink_lock, text: l10n.accessPromiseLocal),
              _Promise(icon: Icons.undo, text: l10n.accessPromiseUndo),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final missing = l10n.accessSettingsMissing;
                  final opened = await status.openListenerSettings();
                  if (!opened && context.mounted) showMessage(context, missing);
                },
                icon: const Icon(Icons.settings),
                label: Text(l10n.accessButton),
              ),
              const SizedBox(height: 24),
              Card.filled(
                color: scheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.accessRestrictedTitle, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(l10n.accessRestrictedBody, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: status.openAppDetails,
                        child: Text(l10n.accessRestrictedButton),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
