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
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/screens/ai_triage_screen.dart';
import '../../features/home/screens/notifications_screen.dart';
import '../../shared/widgets/main_layout.dart';
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
  static const notifications  = '/notifications';
  static const aiTriage       = '/ai-triage';
  static const messages       = '/messages';
  static const categoriesExplore = '/categories-explore';
  static const experts        = '/experts';
  static const expertProfile  = '/expert-profile';
  static const profile        = '/profile';
  static const security       = '/security';
  static const chat           = '/chat';
}

// ─────────────────────────────────────────────────────────────────────────────
// Global navigator key — used by FCMService for out-of-context navigation
// ─────────────────────────────────────────────────────────────────────────────

final navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// Auth change notifier
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
    navigatorKey: navigatorKey,
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

      // ─────────────────────────────────────────────────────────────────────
      // Stateful Navigation Shell (Bottom Navigation Bar)
      // ─────────────────────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Experts
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.experts,
                builder: (_, _) => const ExpertsScreen(),
              ),
            ],
          ),
          // Branch 2: Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.messages,
                builder: (_, _) => const ConversationsScreen(),
              ),
            ],
          ),
          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // AI Triage — pushed above shell (no bottom nav)
      GoRoute(
        path: AppRoutes.aiTriage,
        builder: (_, _) => const AiTriageScreen(),
      ),
      // Notifications — pushed above shell, but keeps its own bottom nav
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurveTween(curve: Curves.easeOutQuart).animate(animation)),
                child: child,
              ),
            );
          },
        ),
      ),

      // ─────────────────────────────────────────────────────────────────────
      // Inner application routes (no bottom nav bar)
      // ─────────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.categoriesExplore,
        builder: (_, _) => const CategoriesExploreScreen(),
      ),
      GoRoute(
        path: AppRoutes.expertProfile,
        pageBuilder: (context, state) {
          final expert = state.extra! as ExpertModel;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ExpertProfileScreen(expert: expert),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (_, _) => const SecurityScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) {
          final args = state.extra! as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ChatScreen(
              name:           args['name']           as String,
              initials:       args['initials']       as String,
              color:          args['color']          as Color,
              subtitle:       args['subtitle']       as String,
              online:         args['online']         as bool? ?? true,
              isAi:           args['isAi']           as bool? ?? false,
              conversationId: args['conversationId'] as int?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutQuart;
              final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
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
