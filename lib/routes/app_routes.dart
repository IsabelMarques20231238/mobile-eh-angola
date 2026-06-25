import 'package:flutter/material.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/new_password_screen.dart';
import '../screens/quiz/quiz_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/forum/subscricoes_screen.dart';
import '../screens/profile/public_creator_profile_screen.dart';

class AppRoutes {
  static const String onboarding    = '/onboarding';
  static const String login         = '/login';
  static const String signup        = '/signup';
  static const String verifyEmail   = '/verify-email';
  static const String resetPassword = '/reset-password';
  static const String newPassword   = '/new-password';
  static const String quizList      = '/quiz';
  static const String profile       = '/profile';
  static const String feed          = '/feed';
  static const String forum         = '/forum';
  static const String subscriptions = '/subscriptions';
  static const String creatorProfile = '/creator-profile';

  // Rotas de tab usam crossfade; todas as outras usam o slide do tema.
  static const _tabRoutes = {feed, forum, quizList, subscriptions, profile};

  static final Map<String, WidgetBuilder> _builders = {
    onboarding:    (_) => const OnboardingScreen(),
    login:         (_) => const LoginScreen(),
    signup:        (_) => const SignUpScreen(),
    verifyEmail:   (_) => const VerifyEmailScreen(),
    resetPassword: (_) => const ResetPasswordScreen(),
    newPassword:   (_) => const NewPasswordScreen(),
    quizList:      (_) => const QuizListScreen(),
    profile:       (_) => const ProfileScreen(),
    feed:          (_) => const FeedScreen(isGuest: false),
    forum:         (_) => const ForumScreen(isGuest: false),
    subscriptions: (_) => const SubscricoesScreen(),
    creatorProfile: (_) => const PublicCreatorProfileScreen(),
  };

  // Mantido para compatibilidade com widgets que ainda usem este getter.
  static Map<String, WidgetBuilder> get routes => _builders;

  /// Route que desliza de baixo para cima — ideal para ecrãs de composição
  /// (criar/editar tópico, formulários, etc.).
  static PageRouteBuilder<T> bottomSlideRoute<T>({required WidgetBuilder builder}) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, _) => builder(context),
      transitionsBuilder: (context, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final builder = _builders[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const Scaffold(body: SizedBox.shrink()),
      );
    }

    // Tabs: crossfade rápido — sem slide, sem direcção
    if (_tabRoutes.contains(settings.name)) {
      return PageRouteBuilder<dynamic>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, _, _) => builder(context),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        ),
      );
    }

    // Restantes: usa MaterialPageRoute para herdar o PageTransitionsTheme
    return MaterialPageRoute(settings: settings, builder: builder);
  }
}
