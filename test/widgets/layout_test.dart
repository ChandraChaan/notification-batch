import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/apps/presentation/apps_page.dart';
import 'package:notification_batch/features/inbox/presentation/inbox_page.dart';
import 'package:notification_batch/features/onboarding/presentation/setup_page.dart';
import 'package:notification_batch/features/onboarding/presentation/welcome_page.dart';
import 'package:notification_batch/features/rules/presentation/rules_page.dart';
import 'package:notification_batch/features/schedule/presentation/schedule_page.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/stats/presentation/stats_page.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';

import '../support/fake_batch_platform.dart';
import '../support/pump.dart';
import '../support/sample_data.dart';

void main() {
  final screens = <String, Widget>{
    'welcome': const WelcomePage(),
    'setup': const SetupPage(),
    'inbox': const InboxPage(),
    'apps': const AppsPage(),
    'schedule': const SchedulePage(),
    'rules': const RulesPage(),
    'stats': const StatsPage(),
  };

  for (final MapEntry(key: name, value: screen) in screens.entries) {
    testWidgets('$name fits a 320 px wide phone with text at 200%', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final fake = FakeBatchPlatform(
        currentStatus: BatchStatus(
          listenerEnabled: true,
          listenerConnected: true,
          notificationsAllowed: false,
          exactAlarmsAllowed: false,
          nextDeliveryAt: DateTime(2026, 10, 27, 13).toUtc(),
          heldCount: 2,
        ),
        currentSettings: const BatchSettings(
          urgentWords: ['delivered', 'gate change'],
          setupDone: true,
        ),
        heldItems: [
          sampleItem('1'),
          sampleItem('2', title: 'A rather long title that will need to wrap'),
        ],
        apps: sampleApps,
      );
      await pumpScreen(tester, fake, screen);
      expect(tester.takeException(), isNull);
    });
  }
}
