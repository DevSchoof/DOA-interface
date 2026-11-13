import 'package:flutter/material.dart';

/// Cores da identidade visual do Dôa (retiradas da logomarca).
class Brand {
  static const green = Color(0xFF0F5C50);
  static const darkGreen = Color(0xFF0B3F38);
  static const coral = Color(0xFFFF6B4A);
  static const cream = Color(0xFFFFF8F0);

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFF7FD1BF) : green,
      onPrimary: dark ? darkGreen : Colors.white,
      tertiary: coral,
      onTertiary: Colors.white,
      tertiaryContainer: dark ? const Color(0xFF5A1F12) : const Color(0xFFFFDAD1),
      onTertiaryContainer: dark ? const Color(0xFFFFDAD1) : const Color(0xFF5A1A0C),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0E1513) : cream,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF0E1513) : cream,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
