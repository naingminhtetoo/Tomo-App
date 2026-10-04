import 'package:flutter/material.dart';

class TomoTheme {
  static const _background = Color(0xFF121212);
  static const _surface = Color(0xFF1F2937);
  static const _accent = Color(0xFF2DD4BF);
  static const _secondaryText = Color(0xFF9CA3AF);

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: brightness,
        ).copyWith(
          primary: dark ? _accent : const Color(0xFF087F73),
          onPrimary: dark ? _background : Colors.white,
          surface: dark ? _surface : const Color(0xFFF1F5F9),
          onSurfaceVariant: dark ? _secondaryText : const Color(0xFF475569),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? _background : const Color(0xFFFAFAFA),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? _background : const Color(0xFFFAFAFA),
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        ),
      ),
    );
  }
}
