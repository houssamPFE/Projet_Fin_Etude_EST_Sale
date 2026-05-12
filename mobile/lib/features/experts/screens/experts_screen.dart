import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../home/models/category_model.dart';
import '../../home/models/expert_model.dart';
import '../../home/providers/home_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExpertsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ExpertsScreen extends ConsumerStatefulWidget {
  const ExpertsScreen({super.key});

  @override
  ConsumerState<ExpertsScreen> createState() => _ExpertsScreenState();
}

class _ExpertsScreenState extends ConsumerState<ExpertsScreen> {
  int _selectedCategoryId = 0; // 0 = all
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final expertsAsync = ref.watch(expertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ExpertsBackground(size: size),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ExpertsHeader(),
                ).animate().fadeIn(duration: 400.ms),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un expert...',
                            hintStyle: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: AppColors.textTertiary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(Icons.close_rounded,
                                        color: AppColors.textTertiary),
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 500.ms)
                            .slideY(begin: 0.08, end: 0),

                        const SizedBox(height: 20),

                        // Categories filter
                        categoriesAsync.when(
                          loading: () => const SizedBox(height: 50),
                          error: (e, _) => const SizedBox.shrink(),
                          data: (categories) => _CategoriesFilter(
                            categories: categories,
                            selectedId: _selectedCategoryId,
                            onSelect: (id) =>
                                setState(() => _selectedCategoryId = id),
                          )
                              .animate()
                              .fadeIn(delay: 140.ms, duration: 500.ms)
                              .slideY(begin: 0.08, end: 0),
                        ),

                        const SizedBox(height: 24),

                        // Experts list
                        expertsAsync.when(
                          loading: () => Column(
                            children: List.generate(
                              4,
                              (index) => const ExpertCardShimmer(),
                            ),
                          ),
                          error: (e, _) => ErrorStateWidget(
                            message: 'Impossible de charger la liste des experts.',
                            onRetry: () => ref.refresh(expertsProvider.future),
                          ),
                          data: (experts) {
                            // Filter by category and search
                            final filtered = experts.where((e) {
                              final matchesCategory = _selectedCategoryId == 0 ||
                                  e.categoryId == _selectedCategoryId;
                              final matchesSearch = _searchQuery.isEmpty ||
                                  e.name.toLowerCase().contains(_searchQuery) ||
                                  e.specialty
                                      .toLowerCase()
                                      .contains(_searchQuery);
                              return matchesCategory && matchesSearch;
                            }).toList();

                            if (filtered.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: EmptyStateWidget(
                                  icon: Icons.person_off_rounded,
                                  title: 'Aucun expert trouvé',
                                  message: 'Nous n\'avons trouvé aucun spécialiste correspondant à votre recherche.',
                                  buttonText: 'Effacer les filtres',
                                  onButtonTap: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedCategoryId = 0;
                                    });
                                  },
                                ),
                              );
                            }

                            return _ExpertsList(experts: filtered)
                                .animate()
                                .fadeIn(delay: 200.ms, duration: 500.ms)
                                .slideY(begin: 0.08, end: 0);
                          },
                        ),
                      ],
                    ),
                  ),
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

class _ExpertsBackground extends StatelessWidget {
  final Size size;
  const _ExpertsBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.1,
          left: -size.width * 0.2,
          child: BlurOrb(
            width: size.width * 0.75,
            height: size.height * 0.4,
            color: const Color(0x326366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.1,
          right: -size.width * 0.15,
          child: BlurOrb(
            width: size.width * 0.65,
            height: size.width * 0.65,
            color: const Color(0x2A8B5CF6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Nos Experts', style: AppTextStyles.headlineSmall),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Icon(Icons.tune_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories filter
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesFilter extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedId;
  final ValueChanged<int> onSelect;

  const _CategoriesFilter({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtrer par spécialité', style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onSelect(0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selectedId == 0 ? AppGradients.button : null,
                    color: selectedId == 0 ? null : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        selectedId == 0 ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Tous',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: selectedId == 0 ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(categories.length, (i) {
                final cat = categories[i];
                return Padding(
                  padding:
                      EdgeInsets.only(right: i == categories.length - 1 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => onSelect(cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient:
                            selectedId == cat.id ? AppGradients.button : null,
                        color: selectedId == cat.id
                            ? null
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: selectedId == cat.id
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.name,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: selectedId == cat.id
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Experts list
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertsList extends StatelessWidget {
  final List<ExpertModel> experts;

  const _ExpertsList({required this.experts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(experts.length, (i) {
        final exp = experts[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i == experts.length - 1 ? 0 : 12),
          child: _ExpertCard(expert: exp),
        );
      }),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: expert.avatarColor.withAlpha(200),
                      ),
                      child: Center(
                        child: Text(
                          expert.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    // Real-time online dot
                    if (expert.isOnline)
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: OnlinePresenceDot(size: 12),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expert.name, style: AppTextStyles.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        expert.specialty,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (expert.isAvailable)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.success.withAlpha(80)),
                    ),
                    child: Text(
                      'Disponible',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Bio
            Text(
              expert.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Rating + Rate
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${expert.rating} (${expert.reviewCount})',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${expert.hourlyRate} MAD/h',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
