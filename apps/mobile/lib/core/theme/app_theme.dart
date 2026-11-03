import 'package:flutter/material.dart';

/// KeyBlue visual identity: deep indigo + electric cyan accent, rounded cards.
class AppTheme {
  static const seed = Color(0xFF5B6CFF);
  static const accent2 = Color(0xFF22D3EE);

  static ThemeData build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b, surface: b == Brightness.dark ? const Color(0xFF0E1117) : null);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        color: b == Brightness.dark ? const Color(0xFF171B24) : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false, scrolledUnderElevation: 0, backgroundColor: Colors.transparent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: b == Brightness.dark ? const Color(0xFF12161D) : null,
        indicatorColor: scheme.primary.withValues(alpha: .22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}

