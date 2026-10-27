import 'installed_app.dart';

/// Why an app is a good or a bad candidate for batching.
enum AppKind {
  shopping,
  food,
  games,
  social,

  /// People write to you here. Never suggested.
  messaging,

  /// Banks, payments, authenticators, clocks, calendars and the like. Never suggested.
  important,

  other;

  bool get isSuggested => this == shopping || this == food || this == games || this == social;
}

/// Picks the apps that are usually safe to batch: shopping, food delivery, games and social feeds.
///
/// Anything that looks like it carries messages from people, money or time is never suggested,
/// even if Android files it under "social". The user still confirms every suggestion.
abstract final class AppSuggester {
  static List<InstalledApp> suggest(Iterable<InstalledApp> apps) => [
    for (final app in apps)
      if (kindOf(app).isSuggested) app,
  ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

  static AppKind kindOf(InstalledApp app) {
    final packageName = app.packageName.toLowerCase();
    final words = '$packageName ${app.label}'.toLowerCase().split(RegExp('[^a-z0-9]+'));

    // Whole words only, so "ola" doesn't match "motorola". Longer hints may start a word
    // ("shop" matches "shopping"). Hints with a dot are package name prefixes.
    bool mentions(List<String> hints) => hints.any(
      (hint) => hint.contains('.')
          ? packageName.startsWith(hint)
          : words.any((word) => hint.length >= 4 ? word.startsWith(hint) : word == hint),
    );

    final isMessaging = app.isDefaultSms || app.isDefaultDialer || mentions(_messagingHints);
    if (isMessaging) return AppKind.messaging;
    if (mentions(_foodHints)) return AppKind.food;
    if (mentions(_shoppingHints)) return AppKind.shopping;
    if (mentions(_importantHints)) return AppKind.important;
    if (app.category == AppCategory.game) return AppKind.games;
    if (app.category == AppCategory.social || mentions(_socialHints)) return AppKind.social;
    return AppKind.other;
  }

  static const _messagingHints = [
    'whatsapp',
    'telegram',
    'org.thoughtcrime.securesms',
    'signal',
    'com.facebook.orca',
    'messenger',
    'messaging',
    'message',
    'sms',
    'mms',
    'chat',
    'viber',
    'jp.naver.line',
    'com.tencent.mm',
    'wechat',
    'skype',
    'slack',
    'teams',
    'discord',
    'snapchat',
    'threema',
    'element',
    'wire',
    'imo',
    'kik',
    'mail',
    'gmail',
    'outlook',
    'dialer',
    'phone',
    'contacts',
    'zoom',
    'meet',
    'duo',
  ];

  static const _importantHints = [
    'bank',
    'pay',
    'paytm',
    'phonepe',
    'upi',
    'wallet',
    'paisa',
    'card',
    'finance',
    'money',
    'auth',
    'otp',
    '2fa',
    'vault',
    'password',
    'security',
    'clock',
    'alarm',
    'calendar',
    'health',
    'doctor',
    'hospital',
    'medic',
    'emergency',
    'family',
    'kids',
    'school',
    'airline',
    'airways',
    'flight',
    'rail',
    'metro',
    'uber',
    'ola',
    'olacabs',
    'lyft',
    'taxi',
    'cab',
    'maps',
    'home',
    'nest',
    'ring',
    'camera',
    'weather',
  ];

  static const _shoppingHints = [
    'shop',
    'amazon',
    'flipkart',
    'myntra',
    'meesho',
    'ajio',
    'nykaa',
    'snapdeal',
    'jiomart',
    'tatacliq',
    'ebay',
    'aliexpress',
    'alibaba',
    'temu',
    'shein',
    'etsy',
    'walmart',
    'target',
    'bestbuy',
    'ikea',
    'wish',
    'shopee',
    'lazada',
    'mercadolibre',
    'zalando',
    'asos',
    'decathlon',
    'lenskart',
    'firstcry',
  ];

  static const _foodHints = [
    'swiggy',
    'zomato',
    'ubereats',
    'com.ubercab.eats',
    'doordash',
    'grubhub',
    'deliveroo',
    'foodpanda',
    'justeat',
    'just-eat',
    'dominos',
    'pizzahut',
    'mcdonalds',
    'kfc',
    'starbucks',
    'blinkit',
    'grofers',
    'zepto',
    'instamart',
    'bigbasket',
    'instacart',
    'talabat',
    'glovo',
    'wolt',
    'menulog',
    'postmates',
    'food',
    'eats',
    'grocery',
    'groceries',
  ];

  static const _socialHints = [
    'instagram',
    'com.facebook.katana',
    'facebook',
    'twitter',
    'com.instagram.barcelona',
    'threads',
    'tiktok',
    'musically',
    'com.ss.android.ugc',
    'pinterest',
    'reddit',
    'linkedin',
    'tumblr',
    'quora',
    'sharechat',
    'mastodon',
    'bluesky',
    'xyz.blueskyweb',
  ];
}
