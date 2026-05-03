import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/category_model.dart';
import '../models/expert_model.dart';
import '../providers/home_providers.dart';

class CategoriesExploreScreen extends ConsumerStatefulWidget {
  const CategoriesExploreScreen({super.key});

  @override
  ConsumerState<CategoriesExploreScreen> createState() =>
      _CategoriesExploreScreenState();
}

class _CategoriesExploreScreenState extends ConsumerState<CategoriesExploreScreen> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final expertsAsync = ref.watch(expertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ExploreBackground(size: size),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.background,
                  leading: const NexoraBackButton(),
                  title: Text('Explorez', style: AppTextStyles.headlineSmall),
                  centerTitle: false,
                ),

                // Categories section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spécialités médicales',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          loading: () => SizedBox(
                            height: 140,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          error: (e, _) => SizedBox(
                            height: 80,
                            child: Center(
                              child: Text(
                                'Erreur de chargement',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                          ),
                          data: (categories) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.95,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, i) {
                              final cat = categories[i];
                              return _CategoryCard(
                                category: cat,
                                isSelected: _selectedCategoryId == cat.id,
                                onTap: () {
                                  setState(() {
                                    _selectedCategoryId =
                                        _selectedCategoryId == cat.id
                                            ? null
                                            : cat.id;
                                  });
                                },
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: (i * 50).ms,
                                    duration: 400.ms,
                                  )
                                  .slideY(begin: 0.1, end: 0);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Experts by category
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 32,
                      bottom: 20,
                    ),
                    child: Text(
                      _selectedCategoryId == null
                          ? 'Tous nos experts'
                          : 'Experts dans cette spécialité',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                ),

                // Experts list
                expertsAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          'Erreur de chargement',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                  data: (experts) {
                    final filtered = _selectedCategoryId == null
                        ? experts
                        : experts
                            .where((e) => e.categoryId == _selectedCategoryId)
                            .toList();

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: 150,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  size: 48,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun expert trouvé',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(
                                          color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final expert = filtered[i];
                          return _ExpertTile(expert: expert)
                              .animate()
                              .fadeIn(
                                delay: (i * 50).ms,
                                duration: 400.ms,
                              )
                              .slideX(begin: 0.1, end: 0);
                        },
                      ),
                    );
                  },
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
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

class _ExploreBackground extends StatelessWidget {
  final Size size;
  const _ExploreBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.15,
          left: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.8,
            height: size.height * 0.4,
            color: const Color(0x256366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          right: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.6,
            height: size.height * 0.35,
            color: const Color(0x1A8B5CF6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.1,
          left: size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.65,
            height: size.height * 0.3,
            color: const Color(0x153B82F6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected
              ? null
              : AppColors.card.withAlpha(150),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(40),
                    blurRadius: 16,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withAlpha(200)
                    : AppColors.surfaceElevated,
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      color:
                          isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              category.description,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? Colors.white.withAlpha(200)
                    : AppColors.textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertTile extends StatelessWidget {
  final ExpertModel expert;

  const _ExpertTile({required this.expert});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.expertProfile, extra: expert),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
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

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expert.specialty,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${expert.rating}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${expert.reviewCount})',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      if (expert.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Dispo',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.success,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Rate
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${expert.hourlyRate}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'MAD/h',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
