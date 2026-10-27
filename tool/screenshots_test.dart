// Renders the README screenshots from the real widgets with made-up data.
//
//   flutter test tool/screenshots_test.dart --update-goldens
//
// Not part of `flutter test` (which only runs test/): text rendering differs between machines.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/apps/presentation/apps_page.dart';
import 'package:notification_batch/features/inbox/presentation/inbox_page.dart';
import 'package:notification_batch/features/onboarding/presentation/setup_page.dart';
import 'package:notification_batch/features/onboarding/presentation/welcome_page.dart';
import 'package:notification_batch/features/rules/presentation/rules_page.dart';
import 'package:notification_batch/features/schedule/presentation/schedule_page.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/settings/domain/delivery_time.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';

import '../test/support/fake_batch_platform.dart';
import '../test/support/pump.dart';
import '../test/support/sample_data.dart';

Future<void> _loadFonts() async {
  final fonts = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$fonts/$name').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(read('Roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('MaterialIcons-Regular.otf'))).load();
}

FakeBatchPlatform _platform() => FakeBatchPlatform(
  currentStatus: BatchStatus(
    listenerEnabled: true,
    listenerConnected: true,
    nextDeliveryAt: DateTime(2026, 10, 27, 13).toUtc(),
    heldCount: 6,
  ),
  currentSettings: const BatchSettings(
    batchedPackages: {
      'com.example.cartwheel.shopping',
      'com.example.tiffin.food',
      'com.example.dragons',
      'com.example.picnic',
    },
    deliveryTimes: [DeliveryTime.at(9), DeliveryTime.at(13), DeliveryTime.at(19)],
    urgentWords: ['delivered', 'gate change', 'Asha'],
    letStarredContactsThrough: true,
    setupDone: true,
  ),
  heldItems: [
    sampleItem(
      'a',
      packageName: 'com.example.tiffin.food',
      appLabel: 'Tiffin Express',
      title: 'Hungry? 40% off lunch',
      text: 'Your favourite thali place has a deal until 3 pm.',
      minutesAgo: 6,
    ),
    sampleItem(
      'b',
      packageName: 'com.example.cartwheel.shopping',
      appLabel: 'Cartwheel Shopping',
      title: 'Price drop on running shoes',
      text: 'The pair in your wishlist is now ₹2,499.',
      minutesAgo: 22,
    ),
    sampleItem(
      'c',
      packageName: 'com.example.cartwheel.shopping',
      appLabel: 'Cartwheel Shopping',
      title: 'Your cart misses you',
      text: 'Two items are almost sold out.',
      minutesAgo: 71,
    ),
    sampleItem(
      'd',
      packageName: 'com.example.dragons',
      appLabel: 'Dragon Merge',
      title: 'Your energy is full!',
      text: 'Come back and merge three more eggs.',
      minutesAgo: 95,
    ),
    sampleItem(
      'e',
      packageName: 'com.example.picnic',
      appLabel: 'Picnic',
      title: 'Ravi and 4 others liked your photo',
      text: 'Sunday at the lake',
      minutesAgo: 120,
    ),
    sampleItem(
      'f',
      packageName: 'com.example.picnic',
      appLabel: 'Picnic',
      title: 'Suggested for you',
      text: 'See what people near you are posting.',
      minutesAgo: 140,
    ),
  ],
  apps: sampleApps,
);

void main() {
  setUpAll(_loadFonts);

  final screens = <String, (Widget, FakeBatchPlatform Function())>{
    'welcome': (
      const WelcomePage(),
      () => _platform()..currentStatus = const BatchStatus(listenerEnabled: false),
    ),
    'setup': (const SetupPage(), () => _platform()..currentSettings = const BatchSettings()),
    'inbox': (const InboxPage(), _platform),
    'apps': (const AppsPage(), _platform),
    'schedule': (const SchedulePage(), _platform),
    'rules': (const RulesPage(), _platform),
  };

  for (final MapEntry(key: name, value: (screen, platform)) in screens.entries) {
    testWidgets(name, (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await pumpScreen(tester, platform(), screen);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../doc/screenshots/$name.png'),
      );
    });
  }
}
