import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/two_factor_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/categories_explore_screen.dart';
import '../../features/experts/screens/experts_screen.dart';
import '../../features/experts/screens/expert_profile_screen.dart';
import '../../features/home/models/expert_model.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/security_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../services/token_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route path constants
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppRoutes {
  static const welcome        = '/';
  static const login          = '/login';
  static const register       = '/register';
  static const otp            = '/otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword  = '/reset-password';
  static const twoFactor      = '/two-factor';
  static const home           = '/home';
  static const categoriesExplore = '/categories-explore';
  static const experts        = '/experts';
  static const expertProfile  = '/expert-profile';
  static const profile        = '/profile';
  static const security       = '/security';
  static const chat           = '/chat';
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth change notifier — call notifyAuthChanged() after login / logout
// to trigger the router redirect guard.
// ─────────────────────────────────────────────────────────────────────────────

final _authChangeNotifier = ValueNotifier<int>(0);

void notifyAuthChanged() => _authChangeNotifier.value++;

// ─────────────────────────────────────────────────────────────────────────────
// Public routes (accessible without token)
// ─────────────────────────────────────────────────────────────────────────────

const _publicRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.otp,
  AppRoutes.forgotPassword,
  AppRoutes.resetPassword,
  AppRoutes.twoFactor,
};

// ─────────────────────────────────────────────────────────────────────────────
// Router provider
// ─────────────────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(tokenStorageProvider);

  return GoRouter(
    initialLocation: AppRoutes.welcome,
    refreshListenable: _authChangeNotifier,
    debugLogDiagnostics: false,

    redirect: (context, state) async {
      final token = await storage.read();
      final isAuth = token != null;
      final isPublic = _publicRoutes.contains(state.matchedLocation);

      if (!isAuth && !isPublic) return AppRoutes.welcome;
      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          return OtpScreen(email: args['email'] as String);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final email = state.extra! as String;
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.twoFactor,
        builder: (context, state) {
          final token = state.extra! as String;
          return TwoFactorScreen(twoFactorToken: token);
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.categoriesExplore,
        builder: (_, _) => const CategoriesExploreScreen(),
      ),
      GoRoute(
        path: AppRoutes.experts,
        builder: (_, _) => const ExpertsScreen(),
      ),
      GoRoute(
        path: AppRoutes.expertProfile,
        builder: (context, state) {
          final expert = state.extra! as ExpertModel;
          return ExpertProfileScreen(expert: expert);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, _) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (_, _) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          return ChatScreen(
            name:           args['name']           as String,
            initials:       args['initials']       as String,
            color:          args['color']          as Color,
            subtitle:       args['subtitle']       as String,
            online:         args['online']         as bool? ?? true,
            isAi:           args['isAi']           as bool? ?? false,
            conversationId: args['conversationId'] as int?,
          );
        },
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: Center(
        child: Text(
          'Page introuvable',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
  );
});
