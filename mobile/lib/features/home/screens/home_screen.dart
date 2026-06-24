import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart' show fixStorageUrl;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/expert_model.dart';
import '../providers/home_providers.dart';
import '../../chat/providers/chat_provider.dart' show aiChatProvider;
import '../../chat/providers/conversations_provider.dart';
import '../providers/notifications_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch themeProvider so HomeScreen rebuilds instantly on theme changes
    ref.watch(themeProvider);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _HomeBackground(size: size),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: _HomeHeader(),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Hero AI Card ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AiHeroCard(),
                  ).animate().fadeIn(delay: 80.ms, duration: 600.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // ── Quick Actions (single row of 4) ────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _QuickActionsRow(),
                  ).animate().fadeIn(delay: 180.ms),

                  const SizedBox(height: 28),

                  // ── Experts recommandés ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Experts recommandés',
                      onSeeAll: () => context.go(AppRoutes.experts),
                    ),
                  ).animate().fadeIn(delay: 280.ms),

                  const SizedBox(height: 14),

                  _ExpertRow().animate().fadeIn(delay: 330.ms),

                  const SizedBox(height: 28),

                  // ── Vos consultations ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Vos consultations',
                      onSeeAll: () => context.go(AppRoutes.messages),
                      seeAllText: 'Voir toutes',
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ConsultationList(),
                  ).animate().fadeIn(delay: 450.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background ──────────────────────────────────────────────────────────────

class _HomeBackground extends StatelessWidget {
  final Size size;
  const _HomeBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orb1Color = isDark ? const Color(0x228B5CF6) : const Color(0x1A10B981);
    final orb2Color = isDark ? const Color(0x146366F1) : const Color(0x1200A566);
    final orb3Color = isDark ? const Color(0x103B82F6) : const Color(0x12059669);

    return Stack(
      children: [
        // Top-left purple/lavender gradient glow (matching experts page)
        Positioned(
          top: -size.height * 0.1,
          left: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.75,
            height: size.height * 0.4,
            color: const Color(0x328B5CF6),
          ),
        ),
        // Orbs
        Positioned(
          top: -size.height * 0.06,
          right: -size.width * 0.15,
          child: BlurOrb(width: size.width * 0.65, height: size.height * 0.28, color: orb1Color),
        ),
        Positioned(
          top: size.height * 0.30,
          left: -size.width * 0.25,
          child: BlurOrb(width: size.width * 0.50, height: size.width * 0.50, color: orb2Color),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          right: size.width * 0.10,
          child: BlurOrb(width: size.width * 0.50, height: size.height * 0.18, color: orb3Color),
        ),
        // Subtle particle dots
        ...List.generate(20, (i) {
          final dx = (i * 53.7 + 17) % size.width;
          final dy = (i * 89.3 + 41) % size.height;
          final s = 1.5 + (i % 3) * 0.5;
          final a = 15 + (i % 4) * 8;
          return Positioned(
            left: dx, top: dy,
            child: Container(
              width: s, height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.white : AppColors.primary).withAlpha(a),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final rawName = userAsync.maybeWhen(
      data: (u) => u.name.trim().split(RegExp(r'\s+')).first,
      orElse: () => '...',
    );
    // Capitalize properly: "Aya" not "AYA"
    final firstName = rawName.length > 1
        ? rawName[0].toUpperCase() + rawName.substring(1).toLowerCase()
        : rawName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Logo + notification
        Row(
          children: [
            const NexoraImageIcon(size: 36),
            const Spacer(),
            _NotificationBell(
              onTap: () => context.push(AppRoutes.notifications),
              unreadCount: ref.watch(unreadCountProvider),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Greeting
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${_timeGreeting()}, $firstName',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(width: 8),
            const _AnimatedSparkle(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Comment puis-je vous aider aujourd\'hui ?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }

  static String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

class _AnimatedSparkle extends StatefulWidget {
  const _AnimatedSparkle();

  @override
  State<_AnimatedSparkle> createState() => _AnimatedSparkleState();
}

class _AnimatedSparkleState extends State<_AnimatedSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _rotation = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Transform.rotate(
          angle: _rotation.value,
          child: ShaderMask(
            shaderCallback: (bounds) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return LinearGradient(
                colors: isDark
                    ? const [Color(0xFF6366F1), Color(0xFFA78BFA), Color(0xFF38BDF8)]
                    : const [Color(0xFF00A566), Color(0xFF10B981), Color(0xFF34D399)],
              ).createShader(bounds);
            },
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;
  const _NotificationBell({required this.onTap, this.unreadCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(Icons.notifications_outlined,
                color: AppColors.textSecondary, size: 20),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -2, right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── AI Hero Carousel ────────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String highlight;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color secondColor;
  final IconData icon;
  final bool useLogoOrb;

  const _SlideData({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
    required this.secondColor,
    required this.icon,
    this.useLogoOrb = false,
  });
}

const _heroSlides = <_SlideData>[
  _SlideData(
    title: 'Votre santé,',
    highlight: 'augmentée par l\'IA',
    subtitle: 'Posez vos questions médicales\net obtenez des conseils fiables.',
    gradientColors: [Color(0xFF1A1744), Color(0xFF2D2A6E), Color(0xFF1A1744)],
    accentColor: Color(0xFF6366F1),
    secondColor: Color(0xFF8B5CF6),
    icon: Icons.auto_awesome_rounded,
    useLogoOrb: true,
  ),
  _SlideData(
    title: 'Experts médicaux',
    highlight: 'disponibles maintenant',
    subtitle: 'Spécialistes vérifiés, consultations\nen moins de 5 minutes.',
    gradientColors: [Color(0xFF0C2245), Color(0xFF1A3A70), Color(0xFF0C2245)],
    accentColor: Color(0xFF3B82F6),
    secondColor: Color(0xFF06B6D4),
    icon: Icons.medical_services_rounded,
  ),
  _SlideData(
    title: 'Urgences ?',
    highlight: 'Nous sommes là 24h/24',
    subtitle: 'Triage automatique et escalade\nprioritaire vers un médecin.',
    gradientColors: [Color(0xFF1F0A3D), Color(0xFF3D1F6E), Color(0xFF1F0A3D)],
    accentColor: Color(0xFF8B5CF6),
    secondColor: Color(0xFFA78BFA),
    icon: Icons.local_hospital_rounded,
  ),
  _SlideData(
    title: 'Confidentiel &',
    highlight: 'sécurisé',
    subtitle: 'Données médicales chiffrées\net protégées de bout en bout.',
    gradientColors: [Color(0xFF091F38), Color(0xFF163452), Color(0xFF091F38)],
    accentColor: Color(0xFF06B6D4),
    secondColor: Color(0xFF0EA5E9),
    icon: Icons.shield_rounded,
  ),
];

class _AiHeroCard extends StatefulWidget {
  const _AiHeroCard();

  @override
  State<_AiHeroCard> createState() => _AiHeroCardState();
}

class _AiHeroCardState extends State<_AiHeroCard> {
  late final PageController _ctrl;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _heroSlides.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: _heroSlides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _buildSlide(_heroSlides[i]),
          ),
          // Dot indicators overlay
          Positioned(
            bottom: 18,
            left: 22,
            child: Row(
              children: List.generate(_heroSlides.length, (i) {
                final active = i == _current;
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final activeColor = isDark ? _heroSlides[_current].accentColor : AppColors.primary;
                final inactiveColor = isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(45);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  width: active ? 22 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: active ? activeColor : inactiveColor,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_SlideData s) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accent = isDark ? s.accentColor : AppColors.primary;
        final second = isDark ? s.secondColor : const Color(0xFF10B981);
        final borderCol = isDark ? s.accentColor : AppColors.border;
        final shadowCol = isDark ? s.accentColor : AppColors.primary;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: s.gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderCol.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: shadowCol.withAlpha(25),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background glow
                Positioned(
                  top: -20, right: -30,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withAlpha(35),
                          second.withAlpha(12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 12, 42),
                  child: Row(
                    children: [
                      // Text column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.3,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: [accent, second],
                              ).createShader(b),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                s.highlight,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFCBD5E1),
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Orb / icon
                      SizedBox(
                        width: 110, height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: accent.withAlpha(30), blurRadius: 40, spreadRadius: 4),
                                  BoxShadow(color: second.withAlpha(15), blurRadius: 60, spreadRadius: 10),
                                ],
                              ),
                            ),
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accent.withAlpha(25), width: 1),
                              ),
                            ),
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: accent.withAlpha(40), width: 1.5),
                                gradient: RadialGradient(
                                  colors: [accent.withAlpha(20), Colors.transparent],
                                ),
                                boxShadow: [
                                  BoxShadow(color: accent.withAlpha(20), blurRadius: 16, spreadRadius: 2),
                                ],
                              ),
                            ),
                            if (s.useLogoOrb)
                              const NexoraImageIcon(size: 52)
                            else
                              ShaderMask(
                                shaderCallback: (b) => LinearGradient(
                                  colors: [accent, second],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(b),
                                blendMode: BlendMode.srcIn,
                                child: Icon(s.icon, size: 44, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

// ─── Quick Actions Row ───────────────────────────────────────────────────────

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(child: _QuickAction(
          icon: Icons.chat_bubble_rounded,
          label: 'Assistant IA',
          sub: '24h/24',
          color: const Color(0xFF6366F1),
          onTap: () {
            // Always start a fresh conversation from this button.
            ref.read(aiChatProvider.notifier).reset();
            context.push(AppRoutes.chat, extra: {
              'name': 'IA Nexora', 'initials': 'IA',
              'color': const Color(0xFF6366F1),
              'subtitle': 'Intelligence Artificielle',
              'online': true, 'isAi': true,
            });
          },
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(
          icon: Icons.people_rounded,
          label: 'Médecins',
          sub: 'Voir les experts',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.go(AppRoutes.experts),
        )),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(
          icon: Icons.grid_view_rounded,
          label: 'Spécialités',
          sub: 'Parcourir',
          color: const Color(0xFF3B82F6),
          onTap: () => context.push(AppRoutes.categoriesExplore),
        )),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? color
        : (color == const Color(0xFF6366F1)
            ? AppColors.primary
            : (color == const Color(0xFF8B5CF6)
                ? AppColors.secondary
                : (color == const Color(0xFF3B82F6)
                    ? AppColors.accent
                    : const Color(0xFF0D9488))));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: activeColor.withAlpha(15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: activeColor.withAlpha(25)),
              boxShadow: [BoxShadow(color: activeColor.withAlpha(10), blurRadius: 12, spreadRadius: -2)],
            ),
            child: Icon(icon, color: activeColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  final String seeAllText;
  const _SectionHeader({required this.title, required this.onSeeAll, this.seeAllText = 'Voir tout'});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seeAllColor = isDark ? const Color(0xFF818CF8) : AppColors.primary;

    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(seeAllText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: seeAllColor)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: seeAllColor),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Expert Row ──────────────────────────────────────────────────────────────

class _ExpertRow extends ConsumerWidget {
  const _ExpertRow();

  static const _mockExperts = [
    {'name': 'Dr. Leila Amrani', 'specialty': 'Médecin généraliste', 'initials': 'LA', 'rating': 4.9, 'color': 0xFF6366F1},
    {'name': 'Dr. Youssef Zahid', 'specialty': 'Cardiologue', 'initials': 'YZ', 'rating': 4.8, 'color': 0xFF8B5CF6},
    {'name': 'Dr. Sara El M.', 'specialty': 'Dermatologue', 'initials': 'SE', 'rating': 4.7, 'color': 0xFF3B82F6},
    {'name': 'Dr. Omar Bennani', 'specialty': 'Neurologue', 'initials': 'OB', 'rating': 4.8, 'color': 0xFF06B6D4},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expertsAsync = ref.watch(expertsProvider);
    return SizedBox(
      height: 235,
      child: expertsAsync.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => const ShimmerContainer(width: 150, height: 220, borderRadius: 16),
        ),
        error: (e, _) => _buildMockList(context),
        data: (experts) => experts.isEmpty
            ? _buildMockList(context)
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: experts.length > 5 ? 5 : experts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ExpertCard(expert: experts[i]),
              ),
      ),
    );
  }

  Widget _buildMockList(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _mockExperts.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => _MockExpertCard(data: _mockExperts[i]),
    );
  }
}

class _ExpertCard extends StatelessWidget {
  final ExpertModel expert;
  const _ExpertCard({required this.expert});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.expertProfile, extra: expert),
      child: Container(
        width: 148,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            // Circular avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: expert.avatarColor.withAlpha(20),
                    border: Border.all(color: expert.avatarColor.withAlpha(50), width: 2),
                  ),
                  child: ClipOval(
                    child: expert.avatarUrl != null && expert.avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: fixStorageUrl(expert.avatarUrl!),
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Center(child: Text(expert.initials, style: TextStyle(color: expert.avatarColor, fontWeight: FontWeight.w700, fontSize: 20))),
                            errorWidget: (_, _, _) => Center(child: Text(expert.initials, style: TextStyle(color: expert.avatarColor, fontWeight: FontWeight.w700, fontSize: 20))),
                          )
                        : Center(child: Text(expert.initials, style: TextStyle(color: expert.avatarColor, fontWeight: FontWeight.w700, fontSize: 20))),
                  ),
                ),
                if (expert.isOnline)
                  Positioned(
                    bottom: 0, right: 0,
                    child: OnlinePresenceDot(size: 11),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(expert.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(expert.specialty, style: TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // Rating + En ligne
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 3),
                Text(expert.rating.toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(width: 10),
                // isOnline = real-time Redis heartbeat presence
                if (expert.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF22C55E).withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('En ligne', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF4ADE80))),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Consulter button
            GestureDetector(
              onTap: () => context.push(AppRoutes.expertProfile, extra: expert),
              child: Container(
                width: double.infinity, height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('Consulter', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockExpertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MockExpertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = Color(data['color'] as int);
    return Container(
      width: 148,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(20),
              border: Border.all(color: color.withAlpha(50), width: 2),
            ),
            child: Center(child: Text(data['initials'] as String, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 20))),
          ),
          const SizedBox(height: 10),
          Text(data['name'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data['specialty'] as String, style: TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 3),
              Text((data['rating'] as double).toStringAsFixed(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF22C55E).withAlpha(50)),
                ),
                child: const Text('En ligne', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF4ADE80))),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go(AppRoutes.experts),
            child: Container(
              width: double.infinity, height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Consulter', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Consultation List ───────────────────────────────────────────────────────

class _ConsultationList extends ConsumerWidget {
  const _ConsultationList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    return conversations.when(
      loading: () => Column(
        children: List.generate(2, (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerContainer(width: double.infinity, height: 80, borderRadius: 14),
        )),
      ),
      error: (err, st) => Text('Erreur: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      data: (convs) => convs.isEmpty
          ? _buildEmptyConsultations()
          : Column(children: convs.take(3).map((c) => _ConsultationCard(conversation: c)).toList()),
    );
  }

  Widget _buildEmptyConsultations() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text('Aucune consultation', style: TextStyle(color: AppColors.textTertiary, fontSize: 13))),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final Map<String, dynamic> conversation;
  const _ConsultationCard({required this.conversation});

  static bool _isAi(Map<String, dynamic> c) {
    if (c['expert'] == null) return true;
    final s  = c['status']  as String? ?? '';
    final ch = c['channel'] as String? ?? '';
    return s == 'ai' || ch == 'ai';
  }

  @override
  Widget build(BuildContext context) {
    final id     = conversation['id'] as int?;
    final isAi   = _isAi(conversation);
    final expert     = conversation['expert'] as Map<String, dynamic>?;
    final expertUser = expert?['user'] as Map<String, dynamic>?;

    final expertName = isAi
        ? 'Assistant IA Nexora'
        : (expertUser?['name'] as String? ?? 'Expert');
    final specialty = isAi
        ? 'Assistant médical IA'
        : (expert?['category']?['name'] as String? ?? '');
    final avatarUrl  = expertUser?['avatar_url'] as String?;
    final isOnline   = isAi ? true : (expertUser?['is_online'] as bool? ?? false);
    final isValidated = (expert?['status'] as String?) == 'validated';
    final status     = conversation['status'] as String? ?? 'ai';
    final isClosed   = status == 'closed';

    final colorSeed = expertName.codeUnits.fold(0, (a, b) => a + b);
    const colors = [
      Color(0xFF8B5CF6), Color(0xFF0EA5E9),
      Color(0xFF10B981), Color(0xFFF59E0B),
      Color(0xFFEC4899), Color(0xFF6366F1),
    ];
    final color = isAi ? const Color(0xFF6366F1) : colors[colorSeed % colors.length];

    final lastMsg = conversation['last_message'] as Map<String, dynamic>?;
    final senderType = lastMsg?['sender_type'] as String? ?? 'user';
    final msgType    = lastMsg?['type'] as String? ?? 'text';
    final content    = lastMsg?['content'] as String? ?? '';
    String preview;
    if (lastMsg == null) {
      preview = isAi ? 'Votre assistant médical' : 'Démarrer la conversation…';
    } else {
      final prefix = senderType == 'user' ? 'Vous : ' : senderType == 'expert' ? 'Dr : ' : 'IA : ';
      preview = msgType == 'audio'
          ? '${prefix}🎤 Message vocal'
          : msgType == 'file'
              ? '${prefix}📎 Fichier'
              : prefix + content;
    }

    return GestureDetector(
      onTap: id == null ? null : () {
        if (isAi) {
          context.push(AppRoutes.chat, extra: {
            'name': 'Assistant IA Nexora',
            'initials': 'N',
            'color': const Color(0xFF6366F1),
            'subtitle': 'Assistant médical IA',
            'online': true,
            'isAi': true,
            'conversationId': id,
            'avatarUrl': null,
          });
        } else {
          context.push(AppRoutes.chat, extra: {
            'name': expertName,
            'initials': expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
            'color': color,
            'subtitle': specialty,
            'online': isOnline,
            'isAi': false,
            'conversationId': id,
            'avatarUrl': avatarUrl,
            'isValidated': isValidated,
            'isClosed': isClosed,
            'hasExpert': conversation['expert_id'] != null,
            'existingRating': conversation['rating'] as int?,
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            // Avatar
            if (isAi)
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/nexora1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(15),
                  border: Border.all(color: color.withAlpha(35)),
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: fixStorageUrl(avatarUrl),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
                              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                ),
              ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          expertName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isAi && isValidated) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                      ],
                    ]),
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    style: TextStyle(fontSize: 11, color: color.withAlpha(180)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
