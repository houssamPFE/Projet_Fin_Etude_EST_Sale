import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../models/expert_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

const _kAllExperts = [
  ExpertModel(
    name: 'Dr. Sara Benali',
    specialty: 'Médecine générale',
    category: 'Médecine',
    rating: 4.9,
    reviewCount: 124,
    rate: 150,
    initials: 'SB',
    color: Color(0xFF6366F1),
    online: true,
  ),
  ExpertModel(
    name: 'Me. Karim Idrissi',
    specialty: 'Droit des affaires',
    category: 'Droit',
    rating: 4.8,
    reviewCount: 89,
    rate: 200,
    initials: 'KI',
    color: Color(0xFF8B5CF6),
    online: true,
  ),
  ExpertModel(
    name: 'M. Youssef Tahiri',
    specialty: 'Fiscalité & TVA',
    category: 'Fiscalité',
    rating: 4.7,
    reviewCount: 67,
    rate: 120,
    initials: 'YT',
    color: Color(0xFF3B82F6),
    online: true,
  ),
  ExpertModel(
    name: 'Mme. Nadia Fassi',
    specialty: 'Finance & Bourse',
    category: 'Finance',
    rating: 4.9,
    reviewCount: 203,
    rate: 180,
    initials: 'NF',
    color: Color(0xFF06B6D4),
    online: false,
  ),
  ExpertModel(
    name: 'Dr. Ahmed Berrada',
    specialty: 'Cardiologie',
    category: 'Médecine',
    rating: 4.6,
    reviewCount: 58,
    rate: 130,
    initials: 'AB',
    color: Color(0xFF6366F1),
    online: true,
  ),
  ExpertModel(
    name: 'Me. Fatima Zahra',
    specialty: 'Droit du travail',
    category: 'Droit',
    rating: 4.8,
    reviewCount: 112,
    rate: 160,
    initials: 'FZ',
    color: Color(0xFF8B5CF6),
    online: false,
  ),
  ExpertModel(
    name: 'M. Rachid Alaoui',
    specialty: 'Développement & IA',
    category: 'Technologie',
    rating: 4.9,
    reviewCount: 95,
    rate: 250,
    initials: 'RA',
    color: Color(0xFF10B981),
    online: true,
  ),
  ExpertModel(
    name: 'Mme. Houda Tazi',
    specialty: 'Orientation scolaire',
    category: 'Éducation',
    rating: 4.7,
    reviewCount: 43,
    rate: 90,
    initials: 'HT',
    color: Color(0xFFF59E0B),
    online: true,
  ),
  ExpertModel(
    name: 'M. Omar Bensalem',
    specialty: 'Startup & Business Plan',
    category: 'Entrepreneuriat',
    rating: 4.8,
    reviewCount: 76,
    rate: 200,
    initials: 'OB',
    color: Color(0xFFEC4899),
    online: true,
  ),
  ExpertModel(
    name: 'Mme. Samira Douiri',
    specialty: 'Administration publique',
    category: 'Administration',
    rating: 4.5,
    reviewCount: 31,
    rate: 100,
    initials: 'SD',
    color: Color(0xFF8B5CF6),
    online: false,
  ),
  ExpertModel(
    name: 'M. Hassan Maarouf',
    specialty: 'Gestion & Comptabilité',
    category: 'Finance',
    rating: 4.6,
    reviewCount: 84,
    rate: 140,
    initials: 'HM',
    color: Color(0xFF06B6D4),
    online: true,
  ),
  ExpertModel(
    name: 'Dr. Layla Hajji',
    specialty: 'Dermatologie',
    category: 'Médecine',
    rating: 4.9,
    reviewCount: 167,
    rate: 170,
    initials: 'LH',
    color: Color(0xFF6366F1),
    online: true,
  ),
];

const _kFilterCategories = [
  'Tous',
  'Médecine',
  'Droit',
  'Fiscalité',
  'Administration',
  'Finance',
  'Technologie',
  'Éducation',
  'Entrepreneuriat',
];

// ─────────────────────────────────────────────────────────────────────────────
// ExpertsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ExpertsScreen extends StatefulWidget {
  const ExpertsScreen({super.key});

  @override
  State<ExpertsScreen> createState() => _ExpertsScreenState();
}

class _ExpertsScreenState extends State<ExpertsScreen> {
  int _selectedCategory = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpertModel> get _filtered {
    return _kAllExperts.where((e) {
      final matchesCategory = _selectedCategory == 0 ||
          e.category == _kFilterCategories[_selectedCategory];
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.specialty.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 0;
    });
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SortSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final experts = _filtered;
    final hasActiveFilter = _selectedCategory != 0 || _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ExpertsBackground(size: size),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
                  child: _ExpertsHeader(onFilter: _showSortSheet),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 18),

                // ── Search bar ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchBar(
                    controller: _searchController,
                    query: _searchQuery,
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ).animate().fadeIn(delay: 60.ms, duration: 400.ms),

                const SizedBox(height: 14),

                // ── Category filter ───────────────────────────────────────
                _CategoryFilter(
                  selected: _selectedCategory,
                  onSelect: (i) => setState(() => _selectedCategory = i),
                ).animate().fadeIn(delay: 110.ms, duration: 400.ms),

                const SizedBox(height: 14),

                // ── Results count ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ResultsInfo(
                    count: experts.length,
                    hasFilter: hasActiveFilter,
                    onClear: _clearFilters,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 12),

                // ── Grid ──────────────────────────────────────────────────
                Expanded(
                  child: experts.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                          key: ValueKey('$_selectedCategory-$_searchQuery'),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.63,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: experts.length,
                          itemBuilder: (_, i) => _ExpertCard(expert: experts[i])
                              .animate(delay: Duration(milliseconds: 40 * i))
                              .fadeIn(duration: 350.ms)
                              .slideY(
                                begin: 0.06,
                                end: 0,
                                curve: Curves.easeOut,
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
          top: -size.height * 0.06,
          left: -size.width * 0.15,
          child: BlurOrb(
            width: size.width * 0.70,
            height: size.height * 0.30,
            color: const Color(0x286366F1),
          ),
        ),
        Positioned(
          top: size.height * 0.35,
          right: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.60,
            height: size.width * 0.60,
            color: const Color(0x1A8B5CF6),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          left: size.width * 0.10,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.height * 0.18,
            color: const Color(0x123B82F6),
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
  final VoidCallback onFilter;
  const _ExpertsHeader({required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const NexoraBackButton(),
        const SizedBox(width: 10),
        Text('Experts', style: AppTextStyles.headlineSmall),
        const Spacer(),
        GestureDetector(
          onTap: onFilter,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? const [
                BoxShadow(
                  color: Color(0x406366F1),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: _focused ? AppColors.primary : AppColors.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: AppTextStyles.input,
              decoration: InputDecoration(
                hintText: 'Rechercher un expert...',
                hintStyle: AppTextStyles.inputHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.query.isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textTertiary.withAlpha(40),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _CategoryFilter({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _kFilterCategories.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _FilterChip(
          label: _kFilterCategories[i],
          isSelected: selected == i,
          onTap: () => onSelect(i),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.button : null,
          color: isSelected ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results info bar
// ─────────────────────────────────────────────────────────────────────────────

class _ResultsInfo extends StatelessWidget {
  final int count;
  final bool hasFilter;
  final VoidCallback onClear;
  const _ResultsInfo({
    required this.count,
    required this.hasFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 0
        ? 'Aucun expert trouvé'
        : '$count expert${count > 1 ? 's' : ''} trouvé${count > 1 ? 's' : ''}';

    return Row(
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        if (hasFilter) ...[
          const Spacer(),
          GestureDetector(
            onTap: onClear,
            child: Text(
              'Réinitialiser',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert card (grid item)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertCard extends StatelessWidget {
  final ExpertModel expert;
  const _ExpertCard({required this.expert});

  void _openProfile(BuildContext context) {
    context.push(AppRoutes.expertProfile, extra: expert);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openProfile(context),
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.card, AppColors.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: expert.color.withAlpha(18),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Avatar + online dot ──────────────────────────────────────
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: expert.color.withAlpha(20),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      expert.color.withAlpha(220),
                      expert.color.withAlpha(140),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    expert.initials,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (expert.online)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    width: 13,
                    height: 13,
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

          // ── Name ──────────────────────────────────────────────────────
          Text(
            expert.name,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // ── Specialty badge ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: expert.color.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: expert.color.withAlpha(55)),
            ),
            child: Text(
              expert.specialty,
              style: AppTextStyles.caption.copyWith(
                color: expert.color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 10),

          // ── Rating ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 3),
              Text(
                expert.rating.toStringAsFixed(1),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '(${expert.reviewCount})',
                style: AppTextStyles.caption,
              ),
            ],
          ),

          const SizedBox(height: 5),

          // ── Rate ──────────────────────────────────────────────────────
          Text(
            '${expert.rate} MAD/h',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // ── CTA button ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(50),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Voir le profil',
                style: AppTextStyles.badge.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              size: 36,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun expert trouvé',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez un autre terme\nou une autre catégorie.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SortSheet extends StatefulWidget {
  const _SortSheet();

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  int _selected = 0;

  static const _options = [
    'Mieux notés',
    'Moins chers',
    'Plus expérimentés',
    'Disponibles maintenant',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Trier par', style: AppTextStyles.titleLarge),
          const SizedBox(height: 16),
          ..._options.asMap().entries.map(
                (entry) => _SortOption(
                  label: entry.value,
                  isSelected: _selected == entry.key,
                  onTap: () => setState(() => _selected = entry.key),
                ),
              ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Appliquer',
                style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SortOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected ? AppGradients.button : null,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
