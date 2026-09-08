import 'package:flutter/material.dart';

abstract final class Brand {
  static const blue = Color(0xFF003366);
  static const navy = Color(0xFF082C4D);
  static const gold = Color(0xFFE7BC67);
  static const ink = Color(0xFF172D40);
  static const muted = Color(0xFF71808D);
  static const cream = Color(0xFFF6F7F9);
  static const white = Colors.white;
  static const green = Color(0xFF23744D);
  static const orange = Color(0xFFAC6018);
  static const purple = Color(0xFF7751A9);
  static const border = Color(0xFFE5E9ED);
  static const productBg = Color(0xFFF0F2F5);

  static Color productSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1C2C3D)
          : const Color(0xFFF0F2F5);

  static ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: blue, brightness: brightness)
        .copyWith(
          primary: dark ? const Color(0xFF9DCBFA) : blue,
          onPrimary: dark ? const Color(0xFF0A223B) : white,
          secondary: gold,
          surface: dark ? const Color(0xFF142436) : white,
          onSurface: dark ? const Color(0xFFE6EDF5) : ink,
          surfaceContainerHighest: dark ? const Color(0xFF1C2F44) : const Color(0xFFEEF2F6),
          outlineVariant: dark ? const Color(0xFF263C52) : const Color(0xFFE2E8F0),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Manrope',
      scaffoldBackgroundColor: dark ? const Color(0xFF101C29) : cream,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 80,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF142436) : white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark ? const Color(0xFF263C52) : border,
            width: 1.5,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: dark ? const Color(0xFFE6EDF5) : navy,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 29,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: scheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: dark ? const Color(0xFFAAB8C6) : muted,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: dark
                ? const Color(0xFF243B52)
                : scheme.outlineVariant.withValues(alpha: .35),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .45),
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: dark ? const Color(0xFF9DCBFA) : blue,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1E2E40) : cream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF2B445E) : Colors.transparent,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? const Color(0xFF16273A) : cream,
        selectedColor: dark ? const Color(0xFF254366) : blue.withValues(alpha: .12),
        labelStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? const Color(0xFFD4E3F3) : ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: dark ? white : blue,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(
          color: dark ? const Color(0xFF2B445E) : scheme.outlineVariant.withValues(alpha: .5),
        ),
        padding: const EdgeInsets.all(9),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 60,
        elevation: 0,
        backgroundColor: dark ? const Color(0xFF142436) : white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected
                ? (dark ? Brand.gold : blue)
                : (dark ? const Color(0xFF8A99A8) : const Color(0xFF64748B)),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.15,
            color: selected
                ? (dark ? Brand.gold : blue)
                : (dark ? const Color(0xFF8A99A8) : const Color(0xFF64748B)),
          );
        }),
      ),
    );
  }
}
