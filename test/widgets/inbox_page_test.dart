import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/inbox/domain/held_item.dart';
import 'package:notification_batch/features/inbox/presentation/inbox_page.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';

import '../support/fake_batch_platform.dart';
import '../support/pump.dart';
import '../support/sample_data.dart';

class _SlowPlatform extends FakeBatchPlatform {
  final _held = Completer<List<HeldItem>>();

  @override
  Future<List<HeldItem>> held() => _held.future;
}

void main() {
  final status = BatchStatus(
    listenerEnabled: true,
    listenerConnected: true,
    nextDeliveryAt: DateTime(2026, 10, 27, 13).toUtc(),
    heldCount: 3,
  );
  const settings = BatchSettings(batchedPackages: {'com.example.shop'}, setupDone: true);

  FakeBatchPlatform platform({List<HeldItem>? held}) => FakeBatchPlatform(
    currentStatus: status,
    currentSettings: settings,
    heldItems:
        held ??
        [
          sampleItem('1', title: 'Your cart misses you', minutesAgo: 30),
          sampleItem('2', title: 'Price drop on running shoes', minutesAgo: 5),
          sampleItem(
            '3',
            packageName: 'com.example.food',
            appLabel: 'Tiffin',
            title: 'Lunch deals near you',
            minutesAgo: 15,
          ),
        ],
  );

  testWidgets('shows the next delivery, the held count and groups by app', (tester) async {
    await pumpScreen(tester, platform(), const InboxPage());
    expect(find.text('Next delivery at 13:00'), findsOneWidget);
    expect(find.text('3 notifications held'), findsOneWidget);
    expect(find.text('Cartwheel'), findsOneWidget);
    expect(find.text('Tiffin'), findsOneWidget);
    expect(find.text('2 notifications'), findsOneWidget);
    expect(find.text('Price drop on running shoes'), findsOneWidget);
  });

  testWidgets('shows a loading state', (tester) async {
    await pumpScreen(tester, _SlowPlatform(), const InboxPage());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await pumpScreen(tester, platform(held: const []), const InboxPage());
    expect(find.text('Nothing held'), findsOneWidget);
  });

  testWidgets('shows an error with a retry that works', (tester) async {
    final fake = platform()..failWith = 'broken';
    await pumpScreen(tester, fake, const InboxPage());
    expect(find.text('Something went wrong talking to Android.'), findsOneWidget);
    fake.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Your cart misses you'), findsOneWidget);
  });

  testWidgets('tapping an item opens it', (tester) async {
    final fake = platform();
    await pumpScreen(tester, fake, const InboxPage());
    await tester.tap(find.text('Lunch deals near you'));
    await tester.pump();
    expect(fake.opened, ['3']);
  });

  testWidgets('says so when an item cannot be opened', (tester) async {
    final fake = platform()..canOpenItems = false;
    await pumpScreen(tester, fake, const InboxPage());
    await tester.tap(find.text('Lunch deals near you'));
    await tester.pump();
    expect(find.text("That app can't be opened any more."), findsOneWidget);
  });

  testWidgets('deliver now delivers', (tester) async {
    final fake = platform();
    await pumpScreen(tester, fake, const InboxPage());
    await tester.tap(find.text('Deliver now'));
    await tester.pump();
    expect(fake.calls, contains('deliverNow'));
    expect(find.text('Delivered.'), findsOneWidget);
  });

  testWidgets('the switch pauses batching', (tester) async {
    final fake = platform();
    await pumpScreen(tester, fake, const InboxPage());
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(fake.saved.single.paused, isTrue);
    expect(find.text('Batching is paused'), findsOneWidget);
  });

  testWidgets('marking an item urgent adds its title as an urgent word', (tester) async {
    final fake = platform();
    await pumpScreen(tester, fake, const InboxPage());
    await tester.tap(find.byTooltip('Options for this notification').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as urgent…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Price drop');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(fake.saved.single.urgentWords, ['Price drop']);
  });

  testWidgets('warns when batches cannot be posted', (tester) async {
    final fake = platform()
      ..currentStatus = const BatchStatus(
        listenerEnabled: true,
        listenerConnected: true,
        notificationsAllowed: false,
      );
    await pumpScreen(tester, fake, const InboxPage());
    expect(find.text("Batches can't be shown"), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pump();
    expect(fake.calls, contains('requestPostNotifications'));
  });

  testWidgets('the delivered tab lists earlier batches', (tester) async {
    final fake = platform()
      ..deliveredItems = [sampleItem('9', title: 'Weekly picks', minutesAgo: 200)];
    await pumpScreen(tester, fake, const InboxPage());
    await tester.tap(find.text('Delivered'));
    await tester.pump();
    expect(find.text('Weekly picks'), findsOneWidget);
  });
}
