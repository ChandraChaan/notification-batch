import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/stats/domain/batch_stats.dart';
import 'package:notification_batch/features/stats/presentation/stats_page.dart';

import '../support/fake_batch_platform.dart';
import '../support/pump.dart';

final _snapshot = StatsSnapshot(
  today: Day.parse('2026-10-27'),
  days: [
    DayStats(day: Day.parse('2026-10-25'), held: const {'shop': 7, 'feed': 2}),
    DayStats(
      day: Day.parse('2026-10-27'),
      held: const {'shop': 4, 'game': 9},
      letThrough: const {LetThroughReason.verificationCode: 2},
    ),
  ],
  labels: const {'shop': 'Cartwheel Shopping', 'game': 'Dragon Merge', 'feed': 'Picnic'},
);

void main() {
  testWidgets('shows today, the week, the noisiest apps and what was let through', (tester) async {
    await pumpScreen(tester, FakeBatchPlatform(statsSnapshot: _snapshot), const StatsPage());
    expect(find.text('13'), findsWidgets);
    expect(find.text('22'), findsOneWidget);
    expect(find.text('Cartwheel Shopping'), findsOneWidget);
    expect(find.text('11 held'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('One-time codes: 2'), 200);
    expect(find.text('One-time codes: 2'), findsOneWidget);
  });

  testWidgets('each day bar has a spoken label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester, FakeBatchPlatform(statsSnapshot: _snapshot), const StatsPage());
    expect(find.bySemanticsLabel('Tuesday: 13 held'), findsOneWidget);
    expect(find.bySemanticsLabel('Monday: 0 held'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shows an empty state before anything happened', (tester) async {
    await pumpScreen(tester, FakeBatchPlatform(), const StatsPage());
    expect(find.text('No numbers yet'), findsOneWidget);
  });

  testWidgets('shows an error with a retry', (tester) async {
    final fake = FakeBatchPlatform(statsSnapshot: _snapshot)..failWith = 'broken';
    await pumpScreen(tester, fake, const StatsPage());
    fake.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Dragon Merge'), findsOneWidget);
  });

  testWidgets('shows a loading state', (tester) async {
    await pumpScreen(tester, _NeverPlatform(), const StatsPage());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

class _NeverPlatform extends FakeBatchPlatform {
  @override
  Future<StatsSnapshot> stats() => Future.any([]);
}
