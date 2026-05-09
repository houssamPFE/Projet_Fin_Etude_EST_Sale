import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/expert_model.dart';
import '../providers/home_providers.dart';
import '../../chat/providers/conversations_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
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
                    child: const _HomeHeader(),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Hero AI Card ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _AiHeroCard(),
                  ).animate().fadeIn(delay: 80.ms, duration: 600.ms)
                      .slideY(begin: 0.05, end: 0),

                  const SizedBox(height: 24),

                  // ── Quick Actions (single row of 4) ────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _QuickActionsRow(),
                  ).animate().fadeIn(delay: 180.ms),

                  const SizedBox(height: 28),

                  // ── Experts recommandés ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Experts recommandés',
                      onSeeAll: () => context.push(AppRoutes.experts),
                    ),
                  ).animate().fadeIn(delay: 280.ms),

                  const SizedBox(height: 14),

                  const _ExpertRow().animate().fadeIn(delay: 330.ms),

                  const SizedBox(height: 28),

                  // ── Vos consultations ──────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Vos consultations',
                      onSeeAll: () {},
                      seeAllText: 'Voir toutes',
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _ConsultationList(),
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
    return Stack(
      children: [
        // Orbs
        Positioned(
          top: -size.height * 0.06,
          right: -size.width * 0.15,
          child: BlurOrb(width: size.width * 0.65, height: size.height * 0.28, color: const Color(0x228B5CF6)),
        ),
        Positioned(
          top: size.height * 0.30,
          left: -size.width * 0.25,
          child: BlurOrb(width: size.width * 0.50, height: size.width * 0.50, color: const Color(0x146366F1)),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          right: size.width * 0.10,
          child: BlurOrb(width: size.width * 0.50, height: size.height * 0.18, color: const Color(0x103B82F6)),
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
                color: Colors.white.withAlpha(a),
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
            _NotificationBell(onTap: () {}),
          ],
        ),
        const SizedBox(height: 14),
        // Greeting
        Text(
          'Bonjour, $firstName 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Comment puis-je vous aider aujourd\'hui ?',
          style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), height: 1.4),
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(8),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: const Icon(Icons.notifications_outlined, color: Color(0xFFCBD5E1), size: 20),
      ),
    );
  }
}

// ─── AI Hero Card ────────────────────────────────────────────────────────────

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1744), Color(0xFF2D2A6E), Color(0xFF1A1744)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4338CA).withAlpha(50)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withAlpha(25), blurRadius: 30, spreadRadius: -6, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background glow behind orb
            Positioned(
              top: -20, right: -30,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [const Color(0xFF6366F1).withAlpha(35), const Color(0xFF8B5CF6).withAlpha(12), Colors.transparent],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 12, 18),
              child: Row(
                children: [
                  // Left text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre santé,',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                        ),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFF93C5FD), Color(0xFFA78BFA), Color(0xFF818CF8)],
                          ).createShader(b),
                          blendMode: BlendMode.srcIn,
                          child: const Text(
                            'augmentée par l\'IA',
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Obtenez des conseils personnalisés\net fiables, 24h/24.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.55),
                        ),
                        const Spacer(),
                        // Dots
                        Row(
                          children: List.generate(4, (i) => Container(
                            width: i == 0 ? 20 : 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: i == 0 ? const Color(0xFF818CF8) : Colors.white.withAlpha(25),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Right: Cinematic AI Orb
                  SizedBox(
                    width: 110, height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Container(
                          width: 110, height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF6366F1).withAlpha(30), blurRadius: 40, spreadRadius: 4),
                              BoxShadow(color: const Color(0xFF8B5CF6).withAlpha(15), blurRadius: 60, spreadRadius: 10),
                            ],
                          ),
                        ),
                        // Mid ring
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF818CF8).withAlpha(25), width: 1),
                          ),
                        ),
                        // Inner ring
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF6366F1).withAlpha(40), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF6366F1).withAlpha(20), blurRadius: 16, spreadRadius: 2),
                            ],
                          ),
                        ),
                        const NexoraImageIcon(size: 52),
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
}

// ─── Quick Actions Row ───────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAction(
          icon: Icons.chat_bubble_rounded,
          label: 'Assistant IA',
          sub: '24h/24',
          color: const Color(0xFF6366F1),
          onTap: () => context.push(AppRoutes.chat, extra: {
            'name': 'IA Nexora', 'initials': 'IA',
            'color': const Color(0xFF6366F1),
            'subtitle': 'Intelligence Artificielle',
            'online': true, 'isAi': true,
          }),
        )),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(
          icon: Icons.people_rounded,
          label: 'Experts',
          sub: 'à portée de main',
          color: const Color(0xFF8B5CF6),
          onTap: () => context.push(AppRoutes.experts),
        )),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(
          icon: Icons.grid_view_rounded,
          label: 'Catégories',
          sub: 'Parcourir',
          color: const Color(0xFF3B82F6),
          onTap: () => context.push(AppRoutes.categoriesExplore),
        )),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(
          icon: Icons.calendar_month_rounded,
          label: 'Prendre RDV',
          sub: 'en ligne',
          color: const Color(0xFF06B6D4),
          onTap: () {},
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withAlpha(25)),
              boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 12, spreadRadius: -2)],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(seeAllText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF818CF8))),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF818CF8)),
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
          color: const Color(0xFF111631),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Column(
          children: [
            // Circular avatar
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: expert.avatarColor.withAlpha(20),
                    border: Border.all(color: expert.avatarColor.withAlpha(50), width: 2),
                  ),
                  child: Center(child: Text(expert.initials, style: TextStyle(color: expert.avatarColor, fontWeight: FontWeight.w700, fontSize: 20))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(expert.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(expert.specialty, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            // Rating + En ligne
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 3),
                Text(expert.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(width: 10),
                if (expert.isAvailable)
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
            // Consulter button
            Container(
              width: double.infinity, height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: Text('Consulter', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
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
        color: const Color(0xFF111631),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(8)),
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
          Text(data['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data['specialty'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 3),
              Text((data['rating'] as double).toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
          Container(
            width: double.infinity, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('Consulter', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
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
          : Column(children: convs.map((c) => _ConsultationCard(conversation: c)).toList()),
    );
  }

  Widget _buildEmptyConsultations() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text('Aucune consultation', style: TextStyle(color: Colors.white38, fontSize: 13))),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final Map<String, dynamic> conversation;
  const _ConsultationCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final id = conversation['id'] as int?;
    final expert = conversation['expert'] as Map<String, dynamic>?;
    final expertUser = expert?['user'] as Map<String, dynamic>?;
    final expertName = expertUser?['name'] as String? ?? 'Expert';
    final lastMessage = (conversation['last_message'] as Map<String, dynamic>?)?['content'] as String? ?? '';

    return GestureDetector(
      onTap: id != null
          ? () => context.push(AppRoutes.chat, extra: {
                'name': expertName, 'initials': 'EX',
                'color': const Color(0xFF8B5CF6),
                'subtitle': 'Expert', 'online': true,
                'isAi': false, 'conversationId': id,
              })
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111631),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withAlpha(15),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(35)),
              ),
              child: const Icon(Icons.medical_services_outlined, color: Color(0xFF818CF8), size: 20),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consultation avec $expertName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage.isEmpty ? 'Contrôle général' : lastMessage,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      const Text('12 Mai 2025', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      const Text('10:30', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6366F1).withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('À venir', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF818CF8))),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: Color(0xFF818CF8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
