import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/inbox/domain/held_item.dart';

import '../support/sample_data.dart';

void main() {
  test('groups by app with the most recent app first and items newest first', () {
    final groups = groupByApp([
      sampleItem('1', minutesAgo: 50),
      sampleItem('2', packageName: 'com.example.food', appLabel: 'Tiffin', minutesAgo: 5),
      sampleItem('3', minutesAgo: 20),
    ]);
    expect(groups.map((g) => g.appLabel), ['Tiffin', 'Cartwheel']);
    expect(groups.last.items.map((i) => i.id), ['3', '1']);
    expect(groups.last.latest, sampleNow.subtract(const Duration(minutes: 20)).toUtc());
  });

  test('apps with the same latest time are ordered by name', () {
    final groups = groupByApp([
      sampleItem('1', packageName: 'b', appLabel: 'Beta'),
      sampleItem('2', packageName: 'a', appLabel: 'Alpha'),
    ]);
    expect(groups.map((g) => g.appLabel), ['Alpha', 'Beta']);
  });

  test('no items, no groups', () {
    expect(groupByApp(const []), isEmpty);
  });
}
