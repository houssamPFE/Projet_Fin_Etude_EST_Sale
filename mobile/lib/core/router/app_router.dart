import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/categories_explore_screen.dart';
import '../../features/experts/screens/experts_screen.dart';
import '../../features/experts/screens/expert_profile_screen.dart';
import '../../features/home/models/expert_model.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/chat/screens/chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route path constants
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppRoutes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const categoriesExplore = '/categories-explore';
  static const experts = '/experts';
  static const expertProfile = '/expert-profile';
  static const profile = '/profile';
  static const chat = '/chat';
}

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  debugLogDiagnostics: false,
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
      path: AppRoutes.chat,
      builder: (context, state) {
        final args = state.extra! as Map<String, dynamic>;
        return ChatScreen(
          name: args['name'] as String,
          initials: args['initials'] as String,
          color: args['color'] as Color,
          subtitle: args['subtitle'] as String,
          online: args['online'] as bool? ?? true,
          isAi: args['isAi'] as bool? ?? false,
        );
      },
    ),
  ],
  // Fallback for unknown routes
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
