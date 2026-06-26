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

// ── Adaptive colours (light/dark) — use context.c in build methods ───────────

class AppAdaptiveColors {
  final Color bg;
  final Color card;
  final Color cardElevated;
  final Color textMain;
  final Color textSecondary;
  final Color muted;
  final Color border;
  final Color wine;
  final Color wineBg;
  final Color winePill;

  const AppAdaptiveColors({
    required this.bg,
    required this.card,
    required this.cardElevated,
    required this.textMain,
    required this.textSecondary,
    required this.muted,
    required this.border,
    required this.wine,
    required this.wineBg,
    required this.winePill,
  });
}

const _lightAdaptive = AppAdaptiveColors(
  bg: Color(0xFFFBF6F8),
  card: Color(0xFFFFFFFF),
  cardElevated: Color(0xFFF8F4F6),
  textMain: Color(0xFF151114),
  textSecondary: Color(0xFF686066),
  muted: Color(0xFF9A9298),
  border: Color(0xFFF0E7EB),
  wine: Color(0xFF7B173F),
  wineBg: Color(0xFFFDF0F5),
  winePill: Color(0xFFF8D9E4),
);

const _darkAdaptive = AppAdaptiveColors(
  bg: Color(0xFF0F0A0D),
  card: Color(0xFF1A1118),
  cardElevated: Color(0xFF221720),
  textMain: Color(0xFFF0ECEE),
  textSecondary: Color(0xFFAA9AA4),
  muted: Color(0xFF6B5E67),
  border: Color(0xFF2A1E25),
  wine: Color(0xFFB03468),
  wineBg: Color(0xFF1E0E15),
  winePill: Color(0xFF321523),
);

extension AppColorsX on BuildContext {
  AppAdaptiveColors get c =>
      Theme.of(this).brightness == Brightness.dark ? _darkAdaptive : _lightAdaptive;
}

// ── Transição suave personalizada ────────────────────────────────────────────

class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    final slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.18, 0.0),
    ).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic),
    );

    return SlideTransition(
      position: slideOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      ),
    );
  }
}

// ── Theme definitions ────────────────────────────────────────────────────────

class AppTheme {
  static const _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: _SmoothPageTransitionsBuilder(),
      TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
      TargetPlatform.windows: _SmoothPageTransitionsBuilder(),
      TargetPlatform.linux: _SmoothPageTransitionsBuilder(),
      TargetPlatform.macOS: _SmoothPageTransitionsBuilder(),
    },
  );

  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: _transitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary, size: 18),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkWine = Color(0xFFB03468);
    const darkBg = Color(0xFF0F0A0D);
    const darkCard = Color(0xFF1A1118);
    const darkBorder = Color(0xFF2A1E25);
    const darkText = Color(0xFFF0ECEE);
    const darkMuted = Color(0xFF6B5E67);

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: darkWine,
        surface: darkCard,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      pageTransitionsTheme: _transitions,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkWine, size: 18),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: darkWine,
        unselectedItemColor: darkMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkWine,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkWine,
          minimumSize: const Size(double.infinity, 38),
          side: const BorderSide(color: darkWine),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: darkWine),
        ),
        hintStyle: const TextStyle(color: darkMuted, fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder),
      cardTheme: const CardThemeData(color: darkCard),
      dialogTheme: const DialogThemeData(backgroundColor: darkCard),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: darkText),
      ),
    );
  }
}
