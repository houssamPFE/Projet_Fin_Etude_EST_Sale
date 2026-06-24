import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/token_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTransitionTimer();
  }

  void _startTransitionTimer() {
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      final storage = ref.read(tokenStorageProvider);
      final refreshToken = await storage.readRefreshToken();
      
      if (!mounted) return;
      if (refreshToken != null) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.welcome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgGradient = isDark
        ? const RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0F172A), // Lighter slate center
              Color(0xFF070B18), // Deep dark primary background
            ],
          )
        : const RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFFFFFFFF), // Pure white center
              Color(0xFFF2F9F6), // Soft mint background
            ],
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Center Logo with glow, bounce, & shimmer animations
              Stack(
                alignment: Alignment.center,
                children: [
                  // Soft background glow
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? const Color(0xFF10B981) : AppColors.primary).withAlpha(45),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOut,
                  ),

                  // Nexora green logo with spring entry and sweep shimmer
                  Image.asset(
                    'assets/images/nexora1.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: 1200.ms,
                  )
                  .shimmer(
                    delay: 1200.ms,
                    duration: 1800.ms,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // NEXORA Brand Name with slide-up and color-shimmer sweep
              Text(
                'N E X O R A',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              )
              .animate()
              .fadeIn(delay: 350.ms, duration: 800.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack)
              .shimmer(
                delay: 1500.ms,
                duration: 1500.ms,
                color: isDark ? const Color(0xFF10B981) : const Color(0xFF34D399),
              ),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'Intelligence & Santé',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              )
              .animate()
              .fadeIn(delay: 700.ms, duration: 800.ms),

              const SizedBox(height: 64),

              // Sleek determinate progress bar
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 3000),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 3,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: value,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? const Color(0xFF10B981) : AppColors.primary,
                            ),
                            backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  );
                },
              )
              .animate()
              .fadeIn(delay: 900.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
