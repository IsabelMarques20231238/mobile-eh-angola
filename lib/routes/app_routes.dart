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
  static const String onboarding  = '/onboarding';
  static const String login        = '/login';
  static const String signup       = '/signup';
  static const String verifyEmail  = '/verify-email';
  static const String resetPassword = '/reset-password';
  static const String newPassword  = '/new-password';
  static const String quizList     = '/quiz';
  static const String profile      = '/profile';
  static const String feed         = '/feed';
  static const String forum        = '/forum';
  static const String subscriptions = '/subscriptions';
  static const String creatorProfile = '/creator-profile';

  static Map<String, WidgetBuilder> get routes => {
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
}
