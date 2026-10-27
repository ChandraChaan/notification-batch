import 'package:notification_batch/features/apps/domain/installed_app.dart';
import 'package:notification_batch/features/inbox/domain/held_item.dart';

/// A fixed "now" for tests and screenshots: Tuesday 27 October 2026, 11:20 local time.
final sampleNow = DateTime(2026, 10, 27, 11, 20);

HeldItem sampleItem(
  String id, {
  String packageName = 'com.example.shop',
  String appLabel = 'Cartwheel',
  String title = 'Your cart misses you',
  String text = 'Two items are almost sold out.',
  int minutesAgo = 10,
}) => HeldItem(
  id: id,
  packageName: packageName,
  appLabel: appLabel,
  title: title,
  text: text,
  postedAt: sampleNow.subtract(Duration(minutes: minutesAgo)).toUtc(),
);

/// Made-up apps, so screenshots and tests don't show real brands.
const sampleApps = [
  InstalledApp(packageName: 'com.example.cartwheel.shopping', label: 'Cartwheel Shopping'),
  InstalledApp(packageName: 'com.example.tiffin.food', label: 'Tiffin Express'),
  InstalledApp(
    packageName: 'com.example.dragons',
    label: 'Dragon Merge',
    category: AppCategory.game,
  ),
  InstalledApp(packageName: 'com.example.picnic', label: 'Picnic', category: AppCategory.social),
  InstalledApp(
    packageName: 'com.example.chatter',
    label: 'Chatter Messenger',
    category: AppCategory.social,
  ),
  InstalledApp(packageName: 'com.example.ledger', label: 'Ledger Bank'),
  InstalledApp(
    packageName: 'com.example.notes',
    label: 'Field Notes',
    category: AppCategory.productivity,
  ),
  InstalledApp(packageName: 'com.example.sms', label: 'Texts', isDefaultSms: true),
];
