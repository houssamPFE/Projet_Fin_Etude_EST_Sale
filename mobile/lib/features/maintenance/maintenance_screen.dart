import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/widgets.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient background orbs
          Positioned(
            top: -size.height * 0.05,
            left: 0,
            right: 0,
            child: BlurOrb(
              width: size.width,
              height: size.height * 0.45,
              color: const Color(0x3FF59E0B),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.04,
            left: size.width * 0.1,
            child: BlurOrb(
              width: size.width * 0.8,
              height: size.height * 0.25,
              color: const Color(0x25F59E0B),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withAlpha(80),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: 36),

                    Text(
                      'Plateforme en maintenance',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 500.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 16),

                    Text(
                      'Nexora est temporairement indisponible.\nNous travaillons à rétablir le service le plus vite possible.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 500.ms)
                        .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),

                    const SizedBox(height: 32),

                    // SAMU disclaimer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0x1AF59E0B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x50F59E0B),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_hospital_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'En cas d\'urgence médicale, appelez le 141 (SAMU Maroc) ou rendez-vous aux urgences.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: const Color(0xFFFCD34D),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 380.ms, duration: 500.ms),

                    const SizedBox(height: 40),

                    NexoraGradientButton(
                      label: 'Réessayer',
                      onTap: () => context.go(AppRoutes.login),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideY(begin: 0.12, end: 0, curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
