import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/blur_orb.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/category_model.dart';
import '../models/expert_model.dart';
import '../providers/home_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data — replaced by API calls when network layer is wired
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryItem {
  final IconData icon;
  final String label;
  const _CategoryItem({required this.icon, required this.label});
}

const _kCategories = [
  _CategoryItem(icon: Icons.medical_services_outlined, label: 'Médecine'),
  _CategoryItem(icon: Icons.gavel_rounded, label: 'Droit'),
  _CategoryItem(icon: Icons.account_balance_outlined, label: 'Fiscalité'),
  _CategoryItem(icon: Icons.assignment_outlined, label: 'Administration'),
  _CategoryItem(icon: Icons.trending_up_rounded, label: 'Finance'),
  _CategoryItem(icon: Icons.code_rounded, label: 'Technologie'),
  _CategoryItem(icon: Icons.school_outlined, label: 'Éducation'),
  _CategoryItem(icon: Icons.rocket_launch_outlined, label: 'Entrepreneuriat'),
];

class _ExpertData {
  final String name;
  final String specialty;
  final double rating;
  final int rate;
  final String initials;
  final Color color;
  final bool online;
  const _ExpertData({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.rate,
    required this.initials,
    required this.color,
    this.online = true,
  });
}

const _kExperts = [
  _ExpertData(
    name: 'Dr. Sara Benali',
    specialty: 'Médecine',
    rating: 4.9,
    rate: 150,
    initials: 'SB',
    color: Color(0xFF6366F1),
  ),
  _ExpertData(
    name: 'Me. Karim Idrissi',
    specialty: 'Droit',
    rating: 4.8,
    rate: 200,
    initials: 'KI',
    color: Color(0xFF8B5CF6),
  ),
  _ExpertData(
    name: 'M. Youssef Tahiri',
    specialty: 'Fiscalité',
    rating: 4.7,
    rate: 120,
    initials: 'YT',
    color: Color(0xFF3B82F6),
  ),
  _ExpertData(
    name: 'Mme. Nadia Fassi',
    specialty: 'Finance',
    rating: 4.9,
    rate: 180,
    initials: 'NF',
    color: Color(0xFF06B6D4),
    online: false,
  ),
];

class _ConversationData {
  final String title;
  final String preview;
  final String time;
  final bool isAi;
  final Color color;
  const _ConversationData({
    required this.title,
    required this.preview,
    required this.time,
    required this.isAi,
    required this.color,
  });
}

const _kConversations = [
  _ConversationData(
    title: 'Question fiscale — TVA',
    preview: "L'IA a répondu à votre question sur la TVA.",
    time: 'Il y a 2h',
    isAi: true,
    color: Color(0xFF6366F1),
  ),
  _ConversationData(
    title: 'Contrat de travail',
    preview: 'Me. Idrissi : Je vais examiner votre contrat...',
    time: 'Hier',
    isAi: false,
    color: Color(0xFF8B5CF6),
  ),
  _ConversationData(
    title: 'Bilan médical annuel',
    preview: 'Dr. Benali : Vos résultats semblent normaux.',
    time: 'Lun.',
    isAi: false,
    color: Color(0xFF3B82F6),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = 0;

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
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
                    child: const _HomeHeader(),
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _AiHeroCard(),
                  )
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 600.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 36),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Catégories',
                      onSeeAll: () => context.push(AppRoutes.experts),
                    ),
                  ).animate().fadeIn(delay: 180.ms),

                  const SizedBox(height: 14),

                  _CategoryRow(
                    selectedId: _selectedCategory,
                    onSelect: (id) => setState(() => _selectedCategory = id),
                  ).animate().fadeIn(delay: 230.ms),

                  const SizedBox(height: 36),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Experts disponibles',
                      onSeeAll: () => context.push(AppRoutes.experts),
                    ),
                  ).animate().fadeIn(delay: 310.ms),

                  const SizedBox(height: 14),

                  const _ExpertRow().animate().fadeIn(delay: 360.ms),

                  const SizedBox(height: 36),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SectionHeader(
                      title: 'Conversations récentes',
                      onSeeAll: () {},
                    ),
                  ).animate().fadeIn(delay: 440.ms),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _ConversationList(),
                  ).animate().fadeIn(delay: 490.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBackground extends StatelessWidget {
  final Size size;
  const _HomeBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.08,
          right: -size.width * 0.20,
          child: BlurOrb(
            width: size.width * 0.75,
            height: size.height * 0.35,
            color: const Color(0x2E8B5CF6),
          ),
        ),
        Positioned(
          top: size.height * 0.20,
          left: -size.width * 0.30,
          child: BlurOrb(
            width: size.width * 0.65,
            height: size.width * 0.65,
            color: const Color(0x1A6366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.05,
          right: size.width * 0.10,
          child: BlurOrb(
            width: size.width * 0.60,
            height: size.height * 0.22,
            color: const Color(0x153B82F6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    final firstName = userAsync.maybeWhen(
      data: (u) => u.name.trim().split(RegExp(r'\s+')).first,
      orElse: () => '...',
    );
    final initial = userAsync.maybeWhen(
      data: (u) {
        final n = u.name.trim();
        return n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();
      },
      orElse: () => '·',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour,',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(firstName, style: AppTextStyles.headlineMedium),
          ],
        ),
        const Spacer(),
        _NotificationButton(onTap: () {}, badgeCount: 2),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.push(AppRoutes.profile),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final int badgeCount;
  const _NotificationButton({required this.onTap, this.badgeCount = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: AppTextStyles.badge.copyWith(fontSize: 8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF4338CA)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x806366F1),
            blurRadius: 36,
            spreadRadius: -10,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned(
              top: -24,
              right: -24,
              child: _DecorativeCircle(size: 130, opacity: 0x12),
            ),
            const Positioned(
              bottom: -32,
              right: 70,
              child: _DecorativeCircle(size: 90, opacity: 0x0A),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'IA Nexora',
                                style: AppTextStyles.overline.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Posez votre\nquestion',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'L\'IA analyse et vous connecte\nà l\'expert idéal.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: const Color(0xCCFFFFFF),
                            height: 1.55,
                          ),
                        ),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () => context.push(AppRoutes.chat, extra: {
                            'name': 'IA Nexora',
                            'initials': 'IA',
                            'color': const Color(0xFF6366F1),
                            'subtitle': 'Intelligence Artificielle',
                            'online': true,
                            'isAi': true,
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Démarrer',
                                  style: AppTextStyles.buttonMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1FFFFFFF),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 38,
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

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final int opacity;
  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color((opacity << 24) | 0x00FFFFFF),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const Spacer(),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'Voir tout',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRow extends ConsumerWidget {
  final int selectedId;
  final ValueChanged<int> onSelect;
  const _CategoryRow({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return SizedBox(
      height: 40,
      child: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Erreur lors du chargement',
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ),
        data: (categories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: categories.length,
          separatorBuilder: (_, index) => const SizedBox(width: 8),
          itemBuilder: (context, i) => _CategoryChip(
            category: categories[i],
            isSelected: selectedId == categories[i].id,
            onTap: () => onSelect(categories[i].id),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 7),
            Text(
              category.name,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert cards
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertRow extends ConsumerWidget {
  const _ExpertRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expertsAsync = ref.watch(expertsProvider);

    return SizedBox(
      height: 238,
      child: expertsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Impossible de charger les experts',
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ),
        data: (experts) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: experts.length > 4 ? 4 : experts.length,
          separatorBuilder: (_, index) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _ExpertCard(expert: experts[i]),
        ),
      ),
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
        width: 162,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: expert.avatarColor.withAlpha(40),
                    border: Border.all(
                      color: expert.avatarColor.withAlpha(80),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      expert.initials,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: expert.avatarColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (expert.isAvailable)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        border: Border.all(color: AppColors.card, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              expert.name,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 3),

            Text(
              expert.specialty,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFBBF24),
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  expert.rating.toStringAsFixed(1),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              '${expert.hourlyRate} MAD/h',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            GestureDetector(
              onTap: () => context.push(AppRoutes.experts),
              child: Container(
                width: double.infinity,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Contacter',
                    style: AppTextStyles.badge.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation list
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _kConversations
          .map((c) => _ConversationTile(conversation: c))
          .toList(),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _ConversationData conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: conversation.color.withAlpha(26),
              border: Border.all(color: conversation.color.withAlpha(60)),
            ),
            child: Icon(
              conversation.isAi
                  ? Icons.auto_awesome_rounded
                  : Icons.person_rounded,
              color: conversation.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.title,
                        style: AppTextStyles.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      conversation.time,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.preview,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: conversation.color.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: conversation.color.withAlpha(60),
                        ),
                      ),
                      child: Text(
                        conversation.isAi ? 'IA' : 'Expert',
                        style: AppTextStyles.badge.copyWith(
                          color: conversation.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
