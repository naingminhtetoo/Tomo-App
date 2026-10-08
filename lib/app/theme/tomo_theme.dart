import 'package:flutter/material.dart';

/// Stitch reference palette, shared across every surface and interaction.
abstract final class TomoColors {
  static const background = Color(0xFF111219);
  static const card = Color(0xFF1D1E26);
  static const elevated = Color(0xFF282830);
  static const coral = Color(0xFFF4634B);
  static const text = Color(0xFFE6E5EE);
  static const secondary = Color(0xFFB49B99);
  static const border = Color(0xFF303039);
}

class TomoTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: TomoColors.coral,
          brightness: brightness,
        ).copyWith(
          primary: TomoColors.coral,
          onPrimary: Colors.white,
          surface: dark ? TomoColors.card : const Color(0xFFFFF8F5),
          surfaceContainerHighest: dark
              ? TomoColors.elevated
              : const Color(0xFFF4E5E0),
          onSurface: dark ? TomoColors.text : const Color(0xFF27232A),
          onSurfaceVariant: dark
              ? TomoColors.secondary
              : const Color(0xFF79635F),
          outlineVariant: dark ? TomoColors.border : const Color(0xFFE6D6D0),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'NotoSansJP',
    );
    return base.copyWith(
      scaffoldBackgroundColor: dark
          ? TomoColors.background
          : const Color(0xFFFFFCFA),
      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? TomoColors.background : const Color(0xFFFFFCFA),
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest,
          padding: const EdgeInsets.all(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? TomoColors.background : scheme.surface,
        indicatorColor: Colors.transparent,
        height: 82,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
