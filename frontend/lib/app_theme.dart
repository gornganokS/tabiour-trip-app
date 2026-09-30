import 'package:flutter/material.dart';

class AppTheme {
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static ThemeData build(bool dark) {
    final background = dark ? const Color(0xFF202B25) : const Color(0xFFF1F7D4);

    final text = dark ? const Color(0xFFF1F7D4) : const Color(0xFF654E3B);

    final green = dark ? const Color(0xFF42614E) : const Color(0xFFA0CBAE);

    final sand = dark ? const Color(0xFF354038) : const Color(0xFFE5DFC1);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: green,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: text,
          surface: background,
          onSurface: text,
          secondaryContainer: green,
          onSecondaryContainer: text,
          surfaceContainerHighest: sand,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: green,
        indicatorColor: sand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sand,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: text,
          minimumSize: const Size(100, 48),
        ),
      ),
    );
  }
}
