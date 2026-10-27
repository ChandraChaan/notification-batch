import 'package:flutter/material.dart';

/// The deep teal of the launcher icon.
const _seed = Color(0xFF0B5D63);

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
    useMaterial3: true,
  );
}
