import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EconomiaHistoriaApp());
}

class EconomiaHistoriaApp extends StatelessWidget {
  const EconomiaHistoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Economia com Historia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const OnboardingScreen(),
      routes: AppRoutes.routes,
    );
  }
}
