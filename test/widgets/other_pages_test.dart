import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/apps/presentation/apps_page.dart';
import 'package:notification_batch/features/onboarding/presentation/setup_page.dart';
import 'package:notification_batch/features/onboarding/presentation/welcome_page.dart';
import 'package:notification_batch/features/rules/presentation/rules_page.dart';
import 'package:notification_batch/features/schedule/presentation/schedule_page.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/settings/domain/delivery_time.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';

import '../support/fake_batch_platform.dart';
import '../support/pump.dart';
import '../support/sample_data.dart';

void main() {
  group('welcome', () {
    testWidgets('explains access and opens the settings screen', (tester) async {
      final fake = FakeBatchPlatform(currentStatus: const BatchStatus(listenerEnabled: false));
      await pumpScreen(tester, fake, const WelcomePage());
      expect(find.text('Why it needs notification access'), findsOneWidget);
      expect(find.textContaining('no internet permission'), findsOneWidget);
      await tester.ensureVisible(find.text('Open notification access settings'));
      await tester.tap(find.text('Open notification access settings'));
      await tester.pump();
      expect(fake.calls, contains('openListenerSettings'));
    });

    testWidgets('helps with Android restricted settings', (tester) async {
      final fake = FakeBatchPlatform();
      await pumpScreen(tester, fake, const WelcomePage());
      await tester.ensureVisible(find.text('Open App info'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open App info'));
      await tester.pump();
      expect(fake.calls, contains('openAppDetails'));
    });
  });

  group('setup', () {
    testWidgets('pre-ticks only suggested apps and saves the choice', (tester) async {
      final fake = FakeBatchPlatform(currentSettings: const BatchSettings(), apps: sampleApps);
      await pumpScreen(tester, fake, const SetupPage());
      expect(find.text('Cartwheel Shopping'), findsOneWidget);
      expect(find.text('Chatter Messenger'), findsNothing);
      expect(find.text('Ledger Bank'), findsNothing);
      expect(find.text('4 apps selected'), findsOneWidget);
      await tester.tap(find.text('Picnic'));
      await tester.pump();
      expect(find.text('3 apps selected'), findsOneWidget);
      await tester.tap(find.text('Start batching'));
      await tester.pump();
      expect(fake.saved.single.batchedPackages, {
        'com.example.cartwheel.shopping',
        'com.example.tiffin.food',
        'com.example.dragons',
      });
      expect(fake.saved.single.setupDone, isTrue);
    });

    testWidgets('can be skipped', (tester) async {
      final fake = FakeBatchPlatform(currentSettings: const BatchSettings(), apps: const []);
      await pumpScreen(tester, fake, const SetupPage());
      expect(find.textContaining('No obvious candidates'), findsOneWidget);
      await tester.tap(find.text('Skip for now'));
      await tester.pump();
      expect(fake.saved.single.batchedPackages, isEmpty);
      expect(fake.saved.single.setupDone, isTrue);
    });
  });

  group('apps', () {
    testWidgets('splits batched and other apps and toggles one', (tester) async {
      final fake = FakeBatchPlatform(
        currentSettings: const BatchSettings(
          batchedPackages: {'com.example.dragons'},
          setupDone: true,
        ),
        apps: sampleApps,
      );
      await pumpScreen(tester, fake, const AppsPage());
      expect(find.text('Batched'), findsOneWidget);
      expect(find.text('Not batched'), findsOneWidget);
      expect(find.text('Messages from people: best left alone'), findsWidgets);
      await tester.tap(find.text('Field Notes'));
      await tester.pump();
      expect(fake.saved.single.batchedPackages, {'com.example.dragons', 'com.example.notes'});
    });

    testWidgets('search filters by name', (tester) async {
      await pumpScreen(tester, FakeBatchPlatform(apps: sampleApps), const AppsPage());
      await tester.enterText(find.byType(TextField), 'tiff');
      await tester.pump();
      expect(find.text('Tiffin Express'), findsOneWidget);
      expect(find.text('Picnic'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('No apps match "zzz".'), findsOneWidget);
    });

    testWidgets('batches all suggestions at once', (tester) async {
      final fake = FakeBatchPlatform(apps: sampleApps);
      await pumpScreen(tester, fake, const AppsPage());
      await tester.tap(find.text('Batch suggested apps'));
      await tester.pump();
      expect(fake.saved.single.batchedPackages, hasLength(4));
    });

    testWidgets('shows an error with retry', (tester) async {
      await pumpScreen(tester, FakeBatchPlatform()..failWith = 'x', const AppsPage());
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('schedule', () {
    testWidgets('lists, adds and removes delivery times', (tester) async {
      final fake = FakeBatchPlatform();
      await pumpScreen(tester, fake, const SchedulePage());
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      await tester.tap(find.byTooltip('Remove 13:00'));
      await tester.pump();
      expect(fake.saved.last.deliveryTimes, const [DeliveryTime.at(9), DeliveryTime.at(19)]);
      await tester.tap(find.text('Add a time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(fake.saved.last.deliveryTimes, contains(const DeliveryTime.at(17)));
    });

    testWidgets('the last time cannot be removed', (tester) async {
      final fake = FakeBatchPlatform(
        currentSettings: const BatchSettings(deliveryTimes: [DeliveryTime.at(12)], setupDone: true),
      );
      await pumpScreen(tester, fake, const SchedulePage());
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_outline),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('offers exact alarms when they are off', (tester) async {
      final fake = FakeBatchPlatform(
        currentStatus: const BatchStatus(listenerEnabled: true, exactAlarmsAllowed: false),
      );
      await pumpScreen(tester, fake, const SchedulePage());
      await tester.tap(find.text('Allow'));
      await tester.pump();
      expect(fake.calls, contains('openExactAlarmSettings'));
    });
  });

  group('rules', () {
    testWidgets('adds and removes urgent words', (tester) async {
      final fake = FakeBatchPlatform(
        currentSettings: const BatchSettings(urgentWords: ['gate'], setupDone: true),
      );
      await pumpScreen(tester, fake, const RulesPage());
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'delivered');
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(fake.saved.last.urgentWords, ['gate', 'delivered']);
      await tester.tap(find.byTooltip('Remove gate'));
      await tester.pump();
      expect(fake.saved.last.urgentWords, ['delivered']);
    });

    testWidgets('starred contacts explain a refusal', (tester) async {
      final fake = FakeBatchPlatform()..grantContacts = false;
      await pumpScreen(tester, fake, const RulesPage());
      await tester.tap(find.text('Starred contacts'));
      await tester.pump();
      expect(find.text('Contacts access was not granted.'), findsOneWidget);
      expect(fake.saved, isEmpty);
    });
  });
}
