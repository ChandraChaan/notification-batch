import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_batch/core/platform/batch_platform.dart';
import 'package:notification_batch/features/settings/domain/batch_settings.dart';
import 'package:notification_batch/features/settings/domain/delivery_time.dart';
import 'package:notification_batch/features/settings/presentation/settings_controller.dart';
import 'package:notification_batch/features/status/domain/batch_status.dart';
import 'package:notification_batch/features/status/presentation/status_controller.dart';

import '../support/fake_batch_platform.dart';
import '../support/pump.dart';

void main() {
  late FakeBatchPlatform platform;
  late ProviderContainer container;

  setUp(() {
    platform = FakeBatchPlatform();
    container = ProviderContainer.test(overrides: overridesFor(platform), retry: noRetry);
  });

  tearDown(() => platform.close());

  SettingsController controller() => container.read(settingsControllerProvider.notifier);

  test('saves a change and shows it straight away', () async {
    await container.read(settingsControllerProvider.future);
    await controller().setBatched('com.example.shop', batched: true);
    expect(platform.saved.single.batchedPackages, {'com.example.shop'});
    expect(container.read(settingsControllerProvider).value?.batchedPackages, {'com.example.shop'});
  });

  test('rolls back when Android cannot save', () async {
    await container.read(settingsControllerProvider.future);
    platform.failSaves = true;
    await expectLater(controller().setPaused(true), throwsA(isA<BatchPlatformException>()));
    expect(container.read(settingsControllerProvider).value?.paused, isFalse);
  });

  test('does not save when nothing changed', () async {
    await container.read(settingsControllerProvider.future);
    await controller().removeTime(const DeliveryTime.at(8));
    expect(platform.saved, isEmpty);
  });

  test('completing setup batches the picked apps and asks to post notifications', () async {
    platform.currentSettings = const BatchSettings();
    await container.read(settingsControllerProvider.future);
    await controller().completeSetup({'a', 'b'});
    expect(platform.saved.single.setupDone, isTrue);
    expect(platform.saved.single.batchedPackages, {'a', 'b'});
    expect(platform.calls, contains('requestPostNotifications'));
  });

  test('starred contacts need contacts access first', () async {
    await container.read(settingsControllerProvider.future);
    platform.grantContacts = false;
    expect(await controller().setStarredContacts(true), isFalse);
    expect(platform.saved, isEmpty);
    platform.grantContacts = true;
    expect(await controller().setStarredContacts(true), isTrue);
    expect(platform.saved.single.letStarredContactsThrough, isTrue);
    expect(await controller().setStarredContacts(false), isTrue);
    expect(platform.calls.where((c) => c == 'requestContacts'), hasLength(2));
  });

  group('gate', () {
    Future<Gate> settle() async {
      container.listen(gateProvider, (_, _) {});
      await container
          .read(statusControllerProvider.future)
          .catchError((Object _) => platform.currentStatus);
      await container
          .read(settingsControllerProvider.future)
          .catchError((Object _) => platform.currentSettings);
      return container.read(gateProvider);
    }

    test('asks for notification access first', () async {
      platform.currentStatus = const BatchStatus(listenerEnabled: false);
      expect(await settle(), Gate.needsAccess);
    });

    test('then the first-run app picker', () async {
      platform.currentSettings = const BatchSettings();
      expect(await settle(), Gate.needsSetup);
    });

    test('then the app', () async {
      expect(await settle(), Gate.ready);
    });

    test('reports errors', () async {
      platform.failWith = 'unavailable';
      expect(await settle(), Gate.error);
    });
  });
}
