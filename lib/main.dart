import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/auth_state.dart';
import 'services/notification_state.dart';
import 'services/theme_state.dart';
import 'services/websocket_service.dart';
import 'theme/app_theme.dart';

/// Global observer — screens subscribe via RouteAware to detect when they
/// come back into focus after another route was pushed on top of them.
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

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
        navigatorObservers: [routeObserver],
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
      final userId = AuthState.instance.user?.id;
      if (userId != null) {
        WebSocketService.instance.subscribeToUserNotifications(userId);
      }
      NotificationState.instance
        ..startListening()
        ..refresh();
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
