import 'package:flutter/material.dart';

class AppTheme {
  // === Zinc Palette (Tailwind) ===
  static const zinc50 = Color(0xFFFAFAFA);
  static const zinc100 = Color(0xFFF4F4F5);
  static const zinc200 = Color(0xFFE4E4E7);
  static const zinc300 = Color(0xFFD4D4D8);
  static const zinc400 = Color(0xFFA1A1AA);
  static const zinc500 = Color(0xFF71717A);
  static const zinc600 = Color(0xFF52525B);
  static const zinc700 = Color(0xFF3F3F46);
  static const zinc800 = Color(0xFF27272A);
  static const zinc900 = Color(0xFF18181B);
  static const zinc950 = Color(0xFF09090B);

  // === Accent Colors ===
  static const orange500 = Color(0xFFF97316);
  static const blue500 = Color(0xFF3B82F6);
  static const emerald500 = Color(0xFF10B981);
  static const amber500 = Color(0xFFF59E0B);
  static const violet500 = Color(0xFF8B5CF6);
  static const red500 = Color(0xFFEF4444);
  static const green500 = Color(0xFF22C55E);

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: zinc950,
    colorScheme: const ColorScheme.dark(
      surface: zinc950,
      surfaceContainerLowest: zinc950,
      surfaceContainerLow: zinc900,
      surfaceContainer: zinc900,
      surfaceContainerHigh: zinc800,
      surfaceContainerHighest: zinc700,
      primary: orange500,
      onPrimary: Colors.white,
      secondary: emerald500,
      onSecondary: zinc50,
      tertiary: amber500,
      error: red500,
      onError: zinc50,
      onSurface: zinc50,
      onSurfaceVariant: zinc400,
      outline: zinc700,
      outlineVariant: zinc800,
    ),
    cardTheme: CardThemeData(
      color: zinc900,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: zinc800),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: zinc950,
      foregroundColor: zinc50,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: zinc950,
      indicatorColor: orange500.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: orange500, fontSize: 12);
        }
        return const TextStyle(color: zinc400, fontSize: 12);
      }),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: zinc900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: zinc800, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: zinc800,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: zinc700),
      ),
    ),
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: zinc50,
    colorScheme: const ColorScheme.light(
      surface: Colors.white,
      surfaceContainer: zinc100,
      surfaceContainerHigh: zinc200,
      primary: orange500,
      onPrimary: Colors.white,
      secondary: emerald500,
      error: red500,
      onSurface: zinc950,
      onSurfaceVariant: zinc600,
      outline: zinc300,
      outlineVariant: zinc200,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: zinc200),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: zinc950,
      elevation: 0,
    ),
  );
}
