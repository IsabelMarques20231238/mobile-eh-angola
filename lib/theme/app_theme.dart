import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7B173F);
  static const Color primaryLight = Color(0xFF9E2B58);
  static const Color primaryDark = Color(0xFF4C0D25);
  static const Color accent = Color(0xFFF8D9E4);
  static const Color accentMid = Color(0xFFEAB6C8);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFBF6F8);
  static const Color textPrimary = Color(0xFF151114);
  static const Color textSecondary = Color(0xFF686066);
  static const Color textMuted = Color(0xFF9A9298);
  static const Color border = Color(0xFFE7D7DE);
  static const Color borderLight = Color(0xFFF0E7EB);
  static const Color success = Color(0xFF15945B);
  static const Color successLight = Color(0xFFE8F7EF);
  static const Color error = Color(0xFFB83357);
  static const Color errorLight = Color(0xFFFBE7EC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color iconBg = Color(0xFFF8DCE7);
  static const Color googleBorder = Color(0xFFE7E0E3);

  // Forum mockup aliases.
  static const Color bg = Color(0xFFFBF6F8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color wine = primary;
  static const Color wineBg = Color(0xFFFDF0F5);
  static const Color winePill = Color(0xFFF8D9E4);
  static const Color textMain = textPrimary;
  static const Color muted = textMuted;
  static const Color divider = Color(0xFFF0E7EB);
  static const Color green = Color(0xFF15945B);
  static const Color red = Color(0xFFB83357);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary, surface: AppColors.surface),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary, size: 18),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 38),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: AppColors.primary)),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}
