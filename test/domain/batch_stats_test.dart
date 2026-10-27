import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/stats/domain/batch_stats.dart';

DayStats day(
  String date, {
  Map<String, int> held = const {},
  Map<LetThroughReason, int> through = const {},
}) => DayStats(day: Day.parse(date), held: held, letThrough: through);

void main() {
  group('Day', () {
    test('parses and prints ISO dates', () {
      expect(Day.parse('2026-03-08').toString(), '2026-03-08');
      expect(() => Day.parse('yesterday'), throwsFormatException);
    });

    test('counts back across month, year and leap day boundaries', () {
      expect(Day.parse('2026-11-01').minusDays(1), Day.parse('2026-10-31'));
      expect(Day.parse('2027-01-03').minusDays(6), Day.parse('2026-12-28'));
      expect(Day.parse('2028-03-01').minusDays(1), Day.parse('2028-02-29'));
    });

    test('ignores daylight saving: the day it starts is still one day', () {
      expect(Day.parse('2026-03-09').minusDays(1), Day.parse('2026-03-08'));
      expect(Day.parse('2026-03-29').minusDays(1), Day.parse('2026-03-28'));
    });

    test('sorts by date', () {
      final days = [Day.parse('2026-10-28'), Day.parse('2025-12-31'), Day.parse('2026-01-02')]
        ..sort();
      expect(days.map((d) => '$d'), ['2025-12-31', '2026-01-02', '2026-10-28']);
    });
  });

  test('reads Kotlin reason names', () {
    expect(LetThroughReason.fromName('VERIFICATION_CODE'), LetThroughReason.verificationCode);
    expect(LetThroughReason.fromName('CALL'), LetThroughReason.call);
    expect(LetThroughReason.fromName('NOTHING_TO_SHOW'), LetThroughReason.nothingToShow);
    expect(LetThroughReason.fromName('SOMETHING_NEW'), isNull);
  });

  group('StatsSummary', () {
    final snapshot = StatsSnapshot(
      today: Day.parse('2026-11-02'),
      days: [
        day('2026-10-26', held: {'old': 50}), // eight days ago: outside the week
        day('2026-10-27', held: {'shop': 3, 'game': 1}),
        day(
          '2026-10-31',
          held: {'shop': 2, 'feed': 4},
          through: {LetThroughReason.verificationCode: 2},
        ),
        day(
          '2026-11-02',
          held: {'game': 5},
          through: {LetThroughReason.verificationCode: 1, LetThroughReason.urgentWord: 1},
        ),
      ],
      labels: const {'shop': 'Cartwheel', 'game': 'Dragon Merge', 'feed': 'Picnic'},
    );
    final summary = StatsSummary.from(snapshot);

    test('counts today and the last seven days, across a month boundary', () {
      expect(summary.savedToday, 5);
      expect(summary.savedThisWeek, 15);
    });

    test('always has seven days, filling the gaps with zeros, today last', () {
      expect(summary.lastSevenDays.map((d) => '${d.day}'), [
        '2026-10-27',
        '2026-10-28',
        '2026-10-29',
        '2026-10-30',
        '2026-10-31',
        '2026-11-01',
        '2026-11-02',
      ]);
      expect(summary.lastSevenDays.map((d) => d.heldTotal), [4, 0, 0, 0, 6, 0, 5]);
    });

    test('ranks the noisiest apps with their names, ties by name', () {
      expect(summary.noisiestApps.map((a) => '${a.label} ${a.count}'), [
        'Dragon Merge 6',
        'Cartwheel 5',
        'Picnic 4',
      ]);
      final tied = StatsSummary.from(
        StatsSnapshot(
          today: Day.parse('2026-11-02'),
          days: [
            day('2026-11-02', held: {'b': 2, 'a': 2}),
          ],
        ),
      );
      expect(tied.noisiestApps.map((a) => a.label), ['a', 'b']);
    });

    test('adds up what was let through', () {
      expect(summary.letThroughThisWeek, {
        LetThroughReason.verificationCode: 3,
        LetThroughReason.urgentWord: 1,
      });
    });

    test('limits the app list', () {
      expect(StatsSummary.from(snapshot, topApps: 2).noisiestApps, hasLength(2));
    });

    test('with nothing recorded it is empty', () {
      final empty = StatsSummary.from(StatsSnapshot(today: Day.parse('2026-11-02')));
      expect(empty.isEmpty, isTrue);
      expect(empty.lastSevenDays, hasLength(7));
      expect(summary.isEmpty, isFalse);
    });
  });
}
