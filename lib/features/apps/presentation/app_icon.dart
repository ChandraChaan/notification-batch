import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apps_controller.dart';

/// An app's launcher icon, or its first letter while loading or if it has none.
class AppIcon extends ConsumerWidget {
  const AppIcon({required this.packageName, required this.label, this.size = 40, super.key});

  final String packageName;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(appIconProvider(packageName)).value;
    if (bytes != null) {
      final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return Image.memory(
        bytes,
        width: size,
        height: size,
        cacheWidth: pixels,
        excludeFromSemantics: true,
        gaplessPlayback: true,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Text(label.isEmpty ? '?' : label.characters.first.toUpperCase()),
      ),
    );
  }
}
