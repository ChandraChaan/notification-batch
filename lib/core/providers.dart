import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform/batch_platform.dart';
import 'platform/method_channel_batch_platform.dart';

/// The way to Android. Tests override it with a fake.
final batchPlatformProvider = Provider<BatchPlatform>((ref) => MethodChannelBatchPlatform());

/// Counts change events from Android. Controllers watch it to reload when something changes.
final changeTickProvider = StreamProvider<int>((ref) async* {
  var tick = 0;
  yield tick;
  await for (final _ in ref.watch(batchPlatformProvider).changes) {
    yield ++tick;
  }
});

/// The current time, so tests can fix it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
