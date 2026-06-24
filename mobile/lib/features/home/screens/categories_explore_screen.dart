import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart' show fixStorageUrl;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/category_model.dart';
import '../models/expert_model.dart';
import '../providers/home_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Category → accent color mapping
// ─────────────────────────────────────────────────────────────────────────────

Color _categoryColor(String slug) {
  switch (slug) {
    case 'medecine-generale': return const Color(0xFF60A5FA);
    case 'pediatrie':         return const Color(0xFFFB923C);
    case 'cardiologie':       return const Color(0xFFFB7185);
    case 'dermatologie':      return const Color(0xFF34D399);
    case 'gynecologie':       return const Color(0xFFF472B6);
    case 'psychiatrie':       return const Color(0xFFA78BFA);
    case 'dentisterie':       return const Color(0xFF38BDF8);
    case 'ophtalmologie':     return const Color(0xFFFBBF24);
    default:                  return const Color(0xFF6366F1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class CategoriesExploreScreen extends ConsumerStatefulWidget {
  const CategoriesExploreScreen({super.key});

  @override
  ConsumerState<CategoriesExploreScreen> createState() =>
      _CategoriesExploreScreenState();
}

class _CategoriesExploreScreenState
    extends ConsumerState<CategoriesExploreScreen> {
  int? _selectedCategoryId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final expertsAsync    = ref.watch(expertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ExploreBackground(size: size),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            const NexoraBackButton(),
                            const SizedBox(width: 14),
                            ShaderMask(
                              shaderCallback: (r) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFC4B5FD)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(r),
                              child: Text(
                                'Explorez',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sub-text
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                        child: expertsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (experts) => categoriesAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (cats) => RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF9DA8BE),
                                  height: 1.45,
                                ),
                                children: [
                                  const TextSpan(text: 'Trouvez le bon expert. '),
                                  TextSpan(
                                    text: '${cats.length} spécialités',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ', '),
                                  TextSpan(
                                    text: '${experts.where((e) => e.isAvailable).length} médecins',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' disponibles aujourd\'hui.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Search bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, _) => TextField(
                            controller: _searchController,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Spécialité, symptôme, médecin…',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 14, right: 8),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 19,
                                  color: value.text.isNotEmpty
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(),
                              suffixIcon: value.text.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Icon(Icons.close_rounded,
                                            size: 17, color: AppColors.textSecondary),
                                      ),
                                    )
                                  : null,
                              suffixIconConstraints: const BoxConstraints(),
                              filled: true,
                              fillColor: AppColors.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v.toLowerCase()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Categories section label ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 14, height: 1,
                          color: const Color(0xFFA78BFA),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'SPÉCIALITÉS',
                          style: AppTextStyles.overline.copyWith(
                            color: Colors.white.withAlpha(100),
                            letterSpacing: 1.2,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.experts),
                          child: Text(
                            'Tout voir →',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFFA78BFA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Categories grid ─────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: categoriesAsync.when(
                      loading: () => SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text('Erreur de chargement',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ),
                      data: (categories) {
                        // Build expert counts per category
                        final Map<int, int> countMap = {};
                        expertsAsync.whenData((experts) {
                          for (final e in experts) {
                            countMap[e.categoryId] =
                                (countMap[e.categoryId] ?? 0) + 1;
                          }
                        });

                        final filtered = _searchQuery.isEmpty
                            ? categories
                            : categories
                                .where((c) =>
                                    c.name
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    c.description
                                        .toLowerCase()
                                        .contains(_searchQuery))
                                .toList();

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final cat = filtered[i];
                            return _CategoryCard(
                              category: cat,
                              isSelected: _selectedCategoryId == cat.id,
                              expertCount: countMap[cat.id] ?? 0,
                              onTap: () => setState(() {
                                _selectedCategoryId =
                                    _selectedCategoryId == cat.id
                                        ? null
                                        : cat.id;
                              }),
                            )
                                .animate()
                                .fadeIn(
                                    delay: (i * 50).ms, duration: 350.ms)
                                .slideY(begin: 0.08, end: 0);
                          },
                        );
                      },
                    ),
                  ),
                ),

                // ── Experts section label ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Row(
                      children: [
                        Text(
                          _selectedCategoryId == null
                              ? 'Tous nos experts'
                              : 'Experts dans cette spécialité',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.experts),
                          child: Text(
                            'Voir tous →',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFFA78BFA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Experts list ────────────────────────────────────────────
                expertsAsync.when(
                  loading: () => SliverToBoxAdapter(
                    child: SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('Erreur de chargement',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ),
                  data: (experts) {
                    var filtered = _selectedCategoryId == null
                        ? experts
                        : experts
                            .where((e) => e.categoryId == _selectedCategoryId)
                            .toList();

                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered
                          .where((e) =>
                              e.name.toLowerCase().contains(_searchQuery) ||
                              e.specialty.toLowerCase().contains(_searchQuery))
                          .toList();
                    }

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: SizedBox(
                          height: 150,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off_outlined,
                                    size: 40, color: AppColors.textTertiary),
                                const SizedBox(height: 10),
                                Text(
                                  'Aucun expert trouvé',
                                  style: AppTextStyles.bodyMedium.copyWith(
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          return _ExpertTile(expert: filtered[i])
                              .animate()
                              .fadeIn(delay: (i * 50).ms, duration: 350.ms)
                              .slideX(begin: 0.06, end: 0);
                        },
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
            color: const Color(0x206366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.25,
          right: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.6,
            height: size.height * 0.35,
            color: const Color(0x1238BDF8),
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
  final int expertCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.expertCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category.slug);
    final cRgb = color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cRgb.withAlpha(90)
                : Colors.white.withAlpha(15),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              cRgb.withAlpha(isSelected ? 50 : 30),
              Colors.white.withAlpha(isSelected ? 10 : 5),
            ],
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cRgb.withAlpha(40),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Top-right glow orb
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cRgb.withAlpha(isSelected ? 55 : 40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cRgb.withAlpha(55),
                          cRgb.withAlpha(15),
                        ],
                      ),
                      border: Border.all(color: cRgb.withAlpha(75)),
                      boxShadow: [
                        BoxShadow(
                          color: cRgb.withAlpha(45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    category.name,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    category.description,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF9DA8BE),
                      height: 1.4,
                      fontSize: 11.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // "Découvrir →"
                  Row(
                    children: [
                      Text(
                        'DÉCOUVRIR',
                        style: TextStyle(
                          color: cRgb,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: cRgb,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Count badge top-right
            if (expertCount > 0)
              Positioned(
                top: 14,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(7, 3, 8, 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(65),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withAlpha(25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cRgb,
                          boxShadow: [
                            BoxShadow(
                              color: cRgb.withAlpha(150),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$expertCount',
                        style: TextStyle(
                          color: Colors.white.withAlpha(155),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
// Expert Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertTile extends StatelessWidget {
  final ExpertModel expert;
  const _ExpertTile({required this.expert});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(
      expert.specialty.toLowerCase().replaceAll(' ', '-'),
    );

    return GestureDetector(
      onTap: () => context.push(AppRoutes.expertProfile, extra: expert),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x07FFFFFF), Color(0x03FFFFFF)],
          ),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        expert.avatarColor.withAlpha(220),
                        expert.avatarColor.withAlpha(150),
                      ],
                    ),
                    border: Border.all(
                      color: color.withAlpha(50),
                      width: 1.5,
                    ),
                  ),
                  child: expert.avatarUrl != null && expert.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: fixStorageUrl(expert.avatarUrl!),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                expert.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            expert.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ],
            ),

            const SizedBox(width: 13),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expert.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Specialty with colored dot
                  Row(
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        expert.specialty,
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF9DA8BE),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Meta row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 11, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text(
                        expert.rating.toStringAsFixed(1),
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        ' (${expert.reviewCount})',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFF9DA8BE),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right: availability
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (expert.isAvailable)
                  _DispoChip()
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withAlpha(18)),
                    ),
                    child: Text(
                      'Indispo',
                      style: AppTextStyles.overline.copyWith(
                        color: const Color(0xFF9DA8BE),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing "Dispo" chip
// ─────────────────────────────────────────────────────────────────────────────

class _DispoChip extends StatefulWidget {
  @override
  State<_DispoChip> createState() => _DispoChipState();
}

class _DispoChipState extends State<_DispoChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(25),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFF34D399).withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + (_anim.value * 0.5),
              child: Opacity(
                opacity: 1.0 - (_anim.value * 0.45),
                child: Container(
                  width: 5, height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34D399),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Dispo',
            style: AppTextStyles.overline.copyWith(
              color: const Color(0xFF34D399),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
