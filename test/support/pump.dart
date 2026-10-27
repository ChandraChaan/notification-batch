import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/app.dart';
import 'package:notification_batch/core/providers.dart';
import 'package:notification_batch/core/theme.dart';
import 'package:notification_batch/l10n/app_localizations.dart';

import 'fake_batch_platform.dart';
import 'sample_data.dart';

/// Riverpod retries failed providers; tests want to see the failure.
Duration? noRetry(int retryCount, Object error) => null;

List<Override> overridesFor(FakeBatchPlatform platform) => [
  batchPlatformProvider.overrideWithValue(platform),
  clockProvider.overrideWithValue(() => sampleNow),
];

/// The whole app, with routing and the gate, on a fake Android.
Future<void> pumpFullApp(WidgetTester tester, FakeBatchPlatform platform) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesFor(platform),
      retry: noRetry,
      child: const NotificationBatchApp(),
    ),
  );
  await settle(tester);
}

/// One screen inside a plain MaterialApp.
Future<void> pumpScreen(WidgetTester tester, FakeBatchPlatform platform, Widget screen) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesFor(platform),
      retry: noRetry,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // Tests read times as "13:00".
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await settle(tester);
}

/// Lets the fake platform's futures complete. Not pumpAndSettle: loading spinners never settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}
