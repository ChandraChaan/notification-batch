import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/features/apps/domain/app_suggester.dart';
import 'package:notification_batch/features/apps/domain/installed_app.dart';

import '../support/sample_data.dart';

InstalledApp app(
  String packageName,
  String label, {
  AppCategory category = AppCategory.undefined,
}) => InstalledApp(packageName: packageName, label: label, category: category);

void main() {
  test('suggests shopping, food, games and social apps', () {
    expect(
      AppSuggester.kindOf(app('in.amazon.mShop.android.shopping', 'Amazon Shopping')),
      AppKind.shopping,
    );
    expect(AppSuggester.kindOf(app('in.swiggy.android', 'Swiggy')), AppKind.food);
    expect(AppSuggester.kindOf(app('com.ubercab.eats', 'Uber Eats')), AppKind.food);
    expect(
      AppSuggester.kindOf(app('com.example.puzzle', 'Puzzle', category: AppCategory.game)),
      AppKind.games,
    );
    expect(AppSuggester.kindOf(app('com.instagram.android', 'Instagram')), AppKind.social);
  });

  test('never suggests messaging from people, even when Android calls it social', () {
    for (final candidate in [
      app('com.whatsapp', 'WhatsApp', category: AppCategory.social),
      app('org.telegram.messenger', 'Telegram'),
      app('com.google.android.apps.messaging', 'Messages'),
      app('com.facebook.orca', 'Messenger', category: AppCategory.social),
      app('com.google.android.gm', 'Gmail'),
      app('com.snapchat.android', 'Snapchat', category: AppCategory.social),
    ]) {
      expect(AppSuggester.kindOf(candidate), AppKind.messaging, reason: candidate.label);
    }
    expect(
      AppSuggester.kindOf(
        const InstalledApp(packageName: 'com.vendor.texts', label: 'Texts', isDefaultSms: true),
      ),
      AppKind.messaging,
    );
    expect(
      AppSuggester.kindOf(
        const InstalledApp(packageName: 'com.vendor.calls', label: 'Calls', isDefaultDialer: true),
      ),
      AppKind.messaging,
    );
  });

  test('never suggests money, time or travel apps', () {
    for (final candidate in [
      app('com.example.bank', 'My Bank'),
      app('com.google.android.apps.nbu.paisa.user', 'Google Pay'),
      app('com.google.android.deskclock', 'Clock'),
      app('com.google.android.calendar', 'Calendar'),
      app('com.ubercab', 'Uber'),
      app('com.example.authenticator', 'Authenticator'),
    ]) {
      expect(AppSuggester.kindOf(candidate), AppKind.important, reason: candidate.label);
    }
  });

  test('matches whole words, not fragments', () {
    // "ola" (a taxi app) must not match "motorola"; "pin" must not match "shopping".
    expect(AppSuggester.kindOf(app('com.motorola.gallery', 'Moto Gallery')), AppKind.other);
    expect(AppSuggester.kindOf(app('com.example.notes', 'Field Notes')), AppKind.other);
  });

  test('suggestions are sorted by name', () {
    expect(AppSuggester.suggest(sampleApps).map((a) => a.label), [
      'Cartwheel Shopping',
      'Dragon Merge',
      'Picnic',
      'Tiffin Express',
    ]);
  });
}
