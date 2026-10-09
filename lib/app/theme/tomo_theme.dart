import 'package:flutter/material.dart';

/// Tomo's native Flutter interpretation of the Stitch tonal-dark palette.
abstract final class TomoColors {
  static const background = Color(0xFF111219);
  static const lowest = Color(0xFF0D0E15);
  static const low = Color(0xFF1A1B22);
  static const card = Color(0xFF1D1E26);
  static const elevated = Color(0xFF282830);
  static const highest = Color(0xFF34343C);
  static const bright = Color(0xFF383941);

  static const coral = Color(0xFFF4634B);
  static const coralSoft = Color(0xFFFFB4A6);
  static const amber = Color(0xFFE5A93C);
  static const blue = Color(0xFF5B8DEF);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFFFB4AB);

  static const text = Color(0xFFE6E5EE);
  static const secondary = Color(0xFFB49B99);
  static const outline = Color(0xFFA88A84);
  static const border = Color(0xFF2E2F3E);
}

abstract final class TomoSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const mobileMargin = 20.0;
}

abstract final class TomoRadii {
  static const control = 12.0;
  static const card = 16.0;
  static const pill = 999.0;
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
          primaryContainer: dark
              ? TomoColors.coral.withValues(alpha: 0.16)
              : const Color(0xFFFFDAD4),
          onPrimaryContainer: dark
              ? TomoColors.coralSoft
              : const Color(0xFF5C0500),
          secondary: dark ? TomoColors.amber : const Color(0xFF8B5E00),
          tertiary: dark ? TomoColors.blue : const Color(0xFF315FAF),
          error: dark ? TomoColors.error : const Color(0xFFBA1A1A),
          surface: dark ? TomoColors.card : const Color(0xFFFFF8F5),
          surfaceContainerLowest: dark ? TomoColors.lowest : Colors.white,
          surfaceContainerLow: dark ? TomoColors.low : const Color(0xFFFFF2EE),
          surfaceContainer: dark ? TomoColors.card : const Color(0xFFFFECE7),
          surfaceContainerHigh: dark
              ? TomoColors.elevated
              : const Color(0xFFF7E5E0),
          surfaceContainerHighest: dark
              ? TomoColors.highest
              : const Color(0xFFEEDBD5),
          onSurface: dark ? TomoColors.text : const Color(0xFF27232A),
          onSurfaceVariant: dark
              ? TomoColors.secondary
              : const Color(0xFF79635F),
          outline: dark ? TomoColors.outline : const Color(0xFF8D716B),
          outlineVariant: dark ? TomoColors.border : const Color(0xFFE6D6D0),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: 'NotoSansJP',
    );
    final text = base.textTheme;
    return base.copyWith(
      scaffoldBackgroundColor: dark
          ? TomoColors.background
          : const Color(0xFFFFFCFA),
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.05,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 30,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontSize: 26,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 17, height: 1.52),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.47),
        bodySmall: text.bodySmall?.copyWith(fontSize: 13, height: 1.38),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelSmall: text.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.45,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? TomoColors.background : const Color(0xFFFFFCFA),
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TomoRadii.card),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TomoRadii.control),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansJP',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TomoRadii.control),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TomoRadii.control),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(12),
          shape: const CircleBorder(),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 7,
        borderRadius: BorderRadius.circular(TomoRadii.pill),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? TomoColors.card : scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        height: 72,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TomoRadii.control),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TomoRadii.control),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TomoRadii.control),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TomoRadii.card),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TomoRadii.card),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
