import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_state.dart';
import 'services/notification_state.dart';
import 'services/theme_state.dart';
import 'services/websocket_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EconomiaHistoriaApp());
}

class EconomiaHistoriaApp extends StatelessWidget {
  const EconomiaHistoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeState.instance,
      builder: (context, _) => MaterialApp(
        title: 'Economia com Historia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeState.instance.mode,
        home: const _AppLoader(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      AuthState.instance.restore(),
      ThemeState.instance.restore(),
    ]);
    // Ligar o WebSocket depois do auth, para que o token já esteja em memória.
    WebSocketService.instance.connect();
    if (!mounted) return;
    if (AuthState.instance.isAuthenticated) {
      NotificationState.instance.refresh();
      Navigator.pushReplacementNamed(context, AppRoutes.feed);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.wine),
      ),
    );
  }
}
