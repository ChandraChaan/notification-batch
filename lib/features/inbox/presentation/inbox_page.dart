import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/platform/batch_platform.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/app_localizations.dart';
import '../../apps/presentation/app_icon.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/held_item.dart';
import 'inbox_controller.dart';
import 'status_card.dart';

enum InboxView { held, delivered }

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});

  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  InboxView _view = InboxView.held;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inbox = ref.watch(inboxControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: StatusCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SegmentedButton<InboxView>(
                segments: [
                  ButtonSegment(
                    value: InboxView.held,
                    label: Text(l10n.inboxHeld),
                    icon: const Icon(Icons.inbox),
                  ),
                  ButtonSegment(
                    value: InboxView.delivered,
                    label: Text(l10n.inboxDelivered),
                    icon: const Icon(Icons.done_all),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (selection) => setState(() => _view = selection.first),
              ),
            ),
          ),
          ...switch (inbox) {
            AsyncValue(:final value?) => _items(
              context,
              _view == InboxView.held ? value.held : value.delivered,
            ),
            AsyncError() => [
              SliverToBoxAdapter(
                child: ErrorView(onRetry: ref.read(inboxControllerProvider.notifier).refresh),
              ),
            ],
            _ => const [SliverFillRemaining(hasScrollBody: false, child: LoadingView())],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<Widget> _items(BuildContext context, List<HeldItem> items) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _view == InboxView.held
              ? EmptyView(
                  icon: Icons.inbox_outlined,
                  title: l10n.inboxEmptyHeldTitle,
                  body: l10n.inboxEmptyHeldBody,
                )
              : EmptyView(
                  icon: Icons.history,
                  title: l10n.inboxEmptyDeliveredTitle,
                  body: l10n.inboxEmptyDeliveredBody,
                ),
        ),
      ];
    }
    final rows = [
      for (final group in groupByApp(items)) ...[
        _GroupRow(group),
        for (final item in group.items) _ItemRow(item),
      ],
    ];
    return [
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) => switch (rows[index]) {
          _GroupRow(:final group) => AppGroupHeader(
            key: ValueKey('group-${group.packageName}'),
            group: group,
          ),
          _ItemRow(:final item) => HeldItemTile(key: ValueKey(item.id), item: item),
        },
      ),
    ];
  }
}

sealed class _Row {
  const _Row();
}

class _GroupRow extends _Row {
  const _GroupRow(this.group);

  final AppGroup group;
}

class _ItemRow extends _Row {
  const _ItemRow(this.item);

  final HeldItem item;
}

class AppGroupHeader extends StatelessWidget {
  const AppGroupHeader({required this.group, super.key});

  final AppGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          AppIcon(packageName: group.packageName, label: group.appLabel, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.appLabel,
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppLocalizations.of(context).groupCount(group.items.length),
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum _ItemAction { open, stopBatching, markUrgent }

class HeldItemTile extends ConsumerWidget {
  const HeldItemTile({required this.item, super.key});

  final HeldItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final time = formatTime(context, item.postedAt);
    final title = item.title.isEmpty ? item.appLabel : item.title;
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 56, end: 4),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.text.isEmpty ? time : '$time · ${item.text}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _open(context, ref),
      trailing: PopupMenuButton<_ItemAction>(
        tooltip: l10n.itemOptions,
        onSelected: (action) => switch (action) {
          _ItemAction.open => _open(context, ref),
          _ItemAction.stopBatching => _stopBatching(context, ref),
          _ItemAction.markUrgent => _markUrgent(context, ref),
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: _ItemAction.open, child: Text(l10n.itemOpen)),
          PopupMenuItem(
            value: _ItemAction.stopBatching,
            child: Text(l10n.itemStopBatching(item.appLabel)),
          ),
          PopupMenuItem(value: _ItemAction.markUrgent, child: Text(l10n.itemMarkUrgent)),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final message = AppLocalizations.of(context).inboxOpenFailed;
    final opened = await ref
        .read(inboxControllerProvider.notifier)
        .open(item)
        .catchError((Object _) => false);
    if (!opened && context.mounted) showMessage(context, message);
  }

  Future<void> _stopBatching(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .setBatched(item.packageName, batched: false);
      if (context.mounted) showMessage(context, l10n.itemStoppedBatching(item.appLabel));
    } on BatchPlatformException {
      if (context.mounted) showMessage(context, l10n.saveFailed);
    }
  }

  Future<void> _markUrgent(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final word = await showDialog<String>(
      context: context,
      builder: (context) => UrgentWordDialog(initial: item.title),
    );
    if (word == null || word.trim().isEmpty) return;
    try {
      await ref.read(settingsControllerProvider.notifier).addUrgentWord(word);
      if (context.mounted) showMessage(context, l10n.itemMarkUrgentAdded(word.trim()));
    } on BatchPlatformException {
      if (context.mounted) showMessage(context, l10n.saveFailed);
    }
  }
}

/// Asks for a word or phrase, starting from the notification's title.
class UrgentWordDialog extends StatefulWidget {
  const UrgentWordDialog({required this.initial, super.key});

  final String initial;

  @override
  State<UrgentWordDialog> createState() => _UrgentWordDialogState();
}

class _UrgentWordDialogState extends State<UrgentWordDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.itemMarkUrgentTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.itemMarkUrgentBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.urgentAdd),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.urgentAddButton),
        ),
      ],
    );
  }
}
