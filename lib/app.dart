import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/inbox/presentation/inbox_controller.dart';
import 'features/status/presentation/status_controller.dart';
import 'l10n/app_localizations.dart';

class NotificationBatchApp extends ConsumerStatefulWidget {
  const NotificationBatchApp({super.key});

  @override
  ConsumerState<NotificationBatchApp> createState() => _NotificationBatchAppState();
}

class _NotificationBatchAppState extends ConsumerState<NotificationBatchApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from Android settings: the user may have granted or revoked access.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(statusControllerProvider);
        ref.invalidate(inboxControllerProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
