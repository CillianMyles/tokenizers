import 'package:flutter/material.dart';

/// Builds the shared Material themes for the app shell.
abstract final class AppTheme {
  /// The light theme used by the app.
  static final ThemeData light = _buildTheme(Brightness.light);

  /// The dark theme used by the app.
  static final ThemeData dark = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = _colorScheme(brightness);
    final shellPalette = _shellPalette(brightness);
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme;
    final textTheme = baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 13, height: 1.35),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[shellPalette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.85 : 0.6,
            ),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(
          alpha: isDark ? 0.96 : 0.9,
        ),
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          minimumSize: const Size.square(40),
          maximumSize: const Size.square(40),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  static ColorScheme _colorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0C7A6C),
      brightness: brightness,
    );

    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: const Color(0xFF0C7A6C),
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFC9EEE2),
        onPrimaryContainer: const Color(0xFF073A31),
        secondary: const Color(0xFF4A635C),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFD7E8E1),
        onSecondaryContainer: const Color(0xFF20332E),
        surface: const Color(0xFFF9FCFA),
        surfaceContainerLow: const Color(0xFFF2F6F3),
        surfaceContainerHighest: const Color(0xFFE3ECE7),
        outline: const Color(0xFF6E817A),
        outlineVariant: const Color(0xFFC3D0C9),
      );
    }

    return base.copyWith(
      primary: const Color(0xFF79D8C0),
      onPrimary: const Color(0xFF00382F),
      primaryContainer: const Color(0xFF1E4E44),
      onPrimaryContainer: const Color(0xFFBFF2E4),
      secondary: const Color(0xFF9FCBC0),
      onSecondary: const Color(0xFF13362E),
      secondaryContainer: const Color(0xFF28483F),
      onSecondaryContainer: const Color(0xFFD3EBE4),
      surface: const Color(0xFF0E1513),
      surfaceContainerLow: const Color(0xFF16201D),
      surfaceContainerHighest: const Color(0xFF22312C),
      outline: const Color(0xFF889A94),
      outlineVariant: const Color(0xFF33443E),
    );
  }

  static AppShellPalette _shellPalette(Brightness brightness) {
    return switch (brightness) {
      Brightness.light => const AppShellPalette(
        gradientStart: Color(0xFFF4F8F5),
        gradientEnd: Color(0xFFE5EEE8),
      ),
      Brightness.dark => const AppShellPalette(
        gradientStart: Color(0xFF09100E),
        gradientEnd: Color(0xFF121B18),
      ),
    };
  }
}

class AppShellPalette extends ThemeExtension<AppShellPalette> {
  const AppShellPalette({
    required this.gradientStart,
    required this.gradientEnd,
  });

  final Color gradientStart;
  final Color gradientEnd;

  @override
  AppShellPalette copyWith({Color? gradientStart, Color? gradientEnd}) {
    return AppShellPalette(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  AppShellPalette lerp(ThemeExtension<AppShellPalette>? other, double t) {
    if (other is! AppShellPalette) {
      return this;
    }
    return AppShellPalette(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}
