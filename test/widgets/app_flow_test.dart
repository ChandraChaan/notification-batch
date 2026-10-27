import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';

import '../support/fake_batch_platform.dart';
import '../support/pump.dart';
import '../support/sample_data.dart';

void main() {
  testWidgets('without notification access the app starts on the explanation', (tester) async {
    await pumpFullApp(
      tester,
      FakeBatchPlatform(currentStatus: const BatchStatus(listenerEnabled: false)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fewer pings, nothing missed'), findsOneWidget);
  });

  testWidgets('access granted on return from settings moves on to the app picker', (tester) async {
    final fake = FakeBatchPlatform(
      currentStatus: const BatchStatus(listenerEnabled: false),
      currentSettings: const BatchSettings(),
      apps: sampleApps,
    );
    await pumpFullApp(tester, fake);
    await tester.pumpAndSettle();
    fake.currentStatus = const BatchStatus(listenerEnabled: true, listenerConnected: true);
    fake.emitChange();
    await tester.pumpAndSettle();
    expect(find.text('Choose apps to batch'), findsOneWidget);
    await tester.tap(find.text('Start batching'));
    await tester.pumpAndSettle();
    expect(find.text('Notification Batch'), findsOneWidget);
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets('the tabs reach every screen', (tester) async {
    await pumpFullApp(tester, FakeBatchPlatform(apps: sampleApps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    expect(find.text('Search apps'), findsOneWidget);
    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Delivery times'), findsOneWidget);
    await tester.tap(find.text('Let through'));
    await tester.pumpAndSettle();
    expect(find.text('Always let through'), findsOneWidget);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('No numbers yet'), findsOneWidget);
  });

  testWidgets('a failure on start offers a retry', (tester) async {
    final fake = FakeBatchPlatform()..failWith = 'unavailable';
    await pumpFullApp(tester, fake);
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    fake.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsOneWidget);
  });
}
