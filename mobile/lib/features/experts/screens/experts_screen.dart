import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart' show fixStorageUrl;
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../home/models/category_model.dart';
import '../../home/models/expert_model.dart';
import '../../home/providers/home_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter state
// ─────────────────────────────────────────────────────────────────────────────

enum _SortBy { rating, name }

extension _SortByExt on _SortBy {
  String get label {
    switch (this) {
      case _SortBy.rating: return 'Mieux notés';
      case _SortBy.name:   return 'Nom A → Z';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortBy.rating: return Icons.star_rounded;
      case _SortBy.name:   return Icons.sort_by_alpha_rounded;
    }
  }
}

class _FilterState {
  final _SortBy sortBy;
  final bool availableOnly;
  final bool onlineOnly;

  const _FilterState({
    this.sortBy = _SortBy.rating,
    this.availableOnly = false,
    this.onlineOnly = false,
  });

  bool get isActive =>
      sortBy != _SortBy.rating ||
      availableOnly ||
      onlineOnly;

  _FilterState copyWith({
    _SortBy? sortBy,
    bool? availableOnly,
    bool? onlineOnly,
  }) {
    return _FilterState(
      sortBy: sortBy ?? this.sortBy,
      availableOnly: availableOnly ?? this.availableOnly,
      onlineOnly: onlineOnly ?? this.onlineOnly,
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (from HTML reference)
// ─────────────────────────────────────────────────────────────────────────────

Color get _kViolet     => AppColors.primary;
Color get _kGreen      => const Color(0xFF10B981);
Color get _kGreen2     => const Color(0xFF34D399);
Color get _kAmber      => const Color(0xFFFBBF24);
Color get _kSurface    => AppColors.card;
Color get _kSurface2   => AppColors.surfaceElevated;
Color get _kLine       => AppColors.border;
Color get _kLine2      => AppColors.border;
Color get _kInk        => AppColors.textPrimary;
Color get _kInkDim     => AppColors.textSecondary;
Color get _kInkFaint   => AppColors.textTertiary;

// ─────────────────────────────────────────────────────────────────────────────
// Specialty → icon mapping
// ─────────────────────────────────────────────────────────────────────────────

IconData _specialtyIcon(String slug) {
  switch (slug) {
    case 'medecine-generale': return Icons.medical_services_rounded;
    case 'pediatrie':         return Icons.child_care_rounded;
    case 'cardiologie':       return Icons.favorite_rounded;
    case 'dermatologie':      return Icons.spa_rounded;
    case 'gynecologie':       return Icons.woman_rounded;
    case 'psychiatrie':       return Icons.psychology_rounded;
    case 'dentisterie':       return Icons.sentiment_satisfied_alt_rounded;
    case 'ophtalmologie':     return Icons.visibility_rounded;
    default:                  return Icons.local_hospital_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExpertsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ExpertsScreen extends ConsumerStatefulWidget {
  const ExpertsScreen({super.key});

  @override
  ConsumerState<ExpertsScreen> createState() => _ExpertsScreenState();
}

class _ExpertsScreenState extends ConsumerState<ExpertsScreen> {
  int _selectedCategoryId = 0;
  String _searchQuery = '';
  _FilterState _filters = const _FilterState();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() =>
        setState(() => _searchFocused = _searchFocus.hasFocus));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(
        current: _filters,
        onApply: (f) {
          Navigator.pop(context);
          setState(() => _filters = f);
        },
        onReset: () {
          Navigator.pop(context);
          setState(() => _filters = const _FilterState());
        },
      ),
    );
  }

  List<ExpertModel> _applyFilters(List<ExpertModel> experts) {
    var list = experts.where((e) {
      if (_selectedCategoryId != 0 && e.categoryId != _selectedCategoryId) return false;
      if (_searchQuery.isNotEmpty &&
          !e.name.toLowerCase().contains(_searchQuery) &&
          !e.specialty.toLowerCase().contains(_searchQuery)) return false;
      if (_filters.availableOnly && !e.isAvailable) return false;
      if (_filters.onlineOnly && !e.isOnline) return false;
      return true;
    }).toList();

    switch (_filters.sortBy) {
      case _SortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortBy.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final expertsAsync = ref.watch(expertsProvider);

    final onlineCount = expertsAsync.maybeWhen(
      data: (list) => list.where((e) => e.isAvailable).length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ExpertsBackground(size: size),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _ExpertsHeader(
                    onlineCount: onlineCount,
                    filterActive: _filters.isActive,
                    onFilterTap: _openFilterSheet,
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                // ── Search ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchBar(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    focused: _searchFocused,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ).animate().fadeIn(delay: 60.ms, duration: 400.ms),

                const SizedBox(height: 4),

                // ── Filter label + chip rail ────────────────────────────────
                categoriesAsync.when(
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (categories) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Row(
                          children: [
                            Text(
                              'FILTRER PAR SPÉCIALITÉ',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0, color: _kInkFaint),
                            ),
                            const Spacer(),
                            Text(
                              '${categories.length} spécialités',
                              style: TextStyle(fontSize: 11, color: _kInkDim, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      _ChipRail(
                        categories: categories,
                        selectedId: _selectedCategoryId,
                        onSelect: (id) => setState(() => _selectedCategoryId = id),
                      ),
                    ],
                  ).animate().fadeIn(delay: 120.ms, duration: 400.ms),
                ),

                const SizedBox(height: 8),

                // ── Expert list ─────────────────────────────────────────────
                Expanded(
                  child: expertsAsync.when(
                    loading: () => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) => const ShimmerContainer(
                          width: double.infinity, height: 130, borderRadius: 18),
                    ),
                    error: (e, _) => ErrorStateWidget(
                      message: 'Impossible de charger la liste des experts.',
                      onRetry: () => ref.invalidate(expertsProvider),
                    ),
                    data: (experts) {
                      final filtered = _applyFilters(experts);

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyStateWidget(
                            icon: Icons.person_off_rounded,
                            title: 'Aucun expert trouvé',
                            message: 'Aucun spécialiste ne correspond à vos filtres.',
                            buttonText: 'Effacer les filtres',
                            onButtonTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedCategoryId = 0;
                                _filters = const _FilterState();
                              });
                            },
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: _kViolet,
                        backgroundColor: _kSurface2,
                        onRefresh: () => ref.read(expertsProvider.notifier).manualRefresh(),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ExpertCard(expert: filtered[i])
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 40 * i), duration: 350.ms)
                              .slideY(begin: 0.06, end: 0),
                        ),
                      );
                    },
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
            color: const Color(0x328B5CF6),
          ),
        ),
        Positioned(
          top: size.height * 0.1,
          right: -size.width * 0.15,
          child: BlurOrb(
            width: size.width * 0.60,
            height: size.width * 0.60,
            color: const Color(0x1A38BDF8),
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
  final int onlineCount;
  final bool filterActive;
  final VoidCallback onFilterTap;

  const _ExpertsHeader({
    required this.onlineCount,
    required this.filterActive,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nos Experts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kInk,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _LiveDot(),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: _kInkDim),
                    children: [
                      TextSpan(
                        text: '$onlineCount',
                        style: TextStyle(color: _kInk, fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' disponibles maintenant'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onFilterTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: filterActive
                  ? LinearGradient(colors: [_kViolet, Color(0xFF6D28D9)])
                  : null,
              color: filterActive ? null : Colors.white.withAlpha(13),
              border: filterActive ? null : Border.all(color: _kLine2),
              boxShadow: filterActive
                  ? [BoxShadow(color: _kViolet.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Icon(Icons.tune_rounded,
                color: filterActive ? Colors.white : _kInk, size: 18),
          ),
        ),
      ],
    );
  }
}

// Pulsing live dot
class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kGreen,
            boxShadow: [BoxShadow(color: _kGreen.withAlpha(180), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 48,
      decoration: BoxDecoration(
        color: focused ? _kSurface2 : _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? _kViolet.withAlpha(128) : _kLine,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: TextStyle(color: _kInk, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Rechercher un expert…',
          hintStyle: TextStyle(color: _kInkFaint, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search_rounded, color: _kInkFaint, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.close_rounded, color: _kInkFaint, size: 18),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip rail
// ─────────────────────────────────────────────────────────────────────────────

class _ChipRail extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedId;
  final ValueChanged<int> onSelect;

  const _ChipRail({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        children: [
          ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _Chip(
                icon: Icons.apps_rounded,
                label: 'Tous',
                active: selectedId == 0,
                onTap: () => onSelect(0),
              ),
              const SizedBox(width: 8),
              ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  icon: _specialtyIcon(cat.slug),
                  label: cat.name,
                  active: selectedId == cat.id,
                  onTap: () => onSelect(cat.id),
                ),
              )),
            ],
          ),
          // Left fade
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.background, AppColors.background.withAlpha(0)],
                  ),
                ),
              ),
            ),
          ),
          // Right fade
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.background.withAlpha(0), AppColors.background],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [_kViolet, Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active ? null : _kSurface,
          borderRadius: BorderRadius.circular(100),
          border: active ? null : Border.all(color: _kLine),
          boxShadow: active
              ? [BoxShadow(color: _kViolet.withAlpha(90), blurRadius: 20, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.white.withAlpha(46) : Colors.white.withAlpha(10),
              ),
              child: Icon(icon, size: 12,
                  color: active ? Colors.white : _kInkDim),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : _kInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expert card
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertCard extends StatelessWidget {
  final ExpertModel expert;
  const _ExpertCard({required this.expert});

  String get _responseTime {
    if (expert.isOnline && expert.isAvailable) return '~ 2 min';
    if (expert.isAvailable) return '~ 5 min';
    return '~ 10 min';
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = expert.avatarUrl != null && expert.avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.expertProfile, extra: expert),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: avatar + name/spec + availability ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasAvatar
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  expert.avatarColor.withAlpha(220),
                                  expert.avatarColor.withAlpha(160),
                                ],
                              ),
                        color: hasAvatar ? _kSurface2 : null,
                      ),
                      child: ClipOval(
                        child: hasAvatar
                            ? CachedNetworkImage(
                                imageUrl: fixStorageUrl(expert.avatarUrl!),
                                fit: BoxFit.cover,
                                placeholder: (_, _) => _initialsWidget(),
                                errorWidget: (_, _, _) => _initialsWidget(),
                              )
                            : _initialsWidget(),
                      ),
                    ),
                    // Online dot (real-time, not hardcoded)
                    if (expert.isOnline)
                      Positioned(
                        right: -2, bottom: -2,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kGreen,
                            border: Border.all(color: _kSurface, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // Name + specialty
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expert.name,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: _kInk, height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        expert.specialty,
                        style: TextStyle(fontSize: 12, color: _kInkDim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Availability pill
                if (expert.isAvailable) const _AvailabilityPill(),
              ],
            ),

            // ── Bio ───────────────────────────────────────────────────────
            if (expert.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                expert.bio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: _kInkDim, height: 1.4),
              ),
            ],

            // ── Divider ───────────────────────────────────────────────────
            const SizedBox(height: 10),
            Divider(height: 1, color: _kLine),
            const SizedBox(height: 10),

            // ── Meta row ──────────────────────────────────────────────────
            Row(
              children: [
                // Rating
                Icon(Icons.star_rounded, size: 13, color: _kAmber),
                const SizedBox(width: 5),
                Text(
                  expert.rating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kInk),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${expert.reviewCount})',
                  style: TextStyle(fontSize: 12, color: _kInkFaint),
                ),
                const Spacer(),
                // Response time
                Text(
                  _responseTime,
                  style: TextStyle(fontSize: 11, color: _kInkDim),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsWidget() {
    return Container(
      color: expert.avatarColor,
      child: Center(
        child: Text(
          expert.initials,
          style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

// Availability pill with animated pulsing dot
class _AvailabilityPill extends StatefulWidget {
  const _AvailabilityPill();

  @override
  State<_AvailabilityPill> createState() => _AvailabilityPillState();
}

class _AvailabilityPillState extends State<_AvailabilityPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kGreen.withAlpha(26),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kGreen2.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (_, _) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kGreen2,
                  boxShadow: [BoxShadow(color: _kGreen2.withAlpha(160), blurRadius: 6)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Disponible',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kGreen2),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _FilterState current;
  final ValueChanged<_FilterState> onApply;
  final VoidCallback onReset;

  const _FilterSheet({
    required this.current,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _SortBy _sortBy;
  late bool _availableOnly;
  late bool _onlineOnly;

  @override
  void initState() {
    super.initState();
    _sortBy        = widget.current.sortBy;
    _availableOnly = widget.current.availableOnly;
    _onlineOnly    = widget.current.onlineOnly;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _kLine2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _kLine2, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(children: [
                Text('Filtres',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kInk)),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onReset,
                  child: Text('Réinitialiser',
                      style: TextStyle(fontSize: 13, color: _kViolet, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: _kLine2),

            // ── Sort by ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRIER PAR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 1.0, color: _kInkFaint)),
                  const SizedBox(height: 10),
                  ..._SortBy.values.map((s) {
                    final active = s == _sortBy;
                    return GestureDetector(
                      onTap: () => setState(() => _sortBy = s),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? _kViolet.withAlpha(26) : _kSurface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? _kViolet.withAlpha(100) : _kLine2,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(s.icon, size: 16,
                              color: active ? _kViolet : _kInkDim),
                          const SizedBox(width: 10),
                          Text(s.label,
                              style: TextStyle(
                                fontSize: 14,
                                color: active ? _kViolet : _kInk,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                              )),
                          const Spacer(),
                          if (active)
                            Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: _kViolet),
                              child: const Icon(Icons.check_rounded,
                                  size: 11, color: Colors.white),
                            ),
                        ]),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Divider(height: 1, color: _kLine2),

            // ── Availability toggles ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DISPONIBILITÉ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 1.0, color: _kInkFaint)),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    icon: Icons.event_available_rounded,
                    iconColor: _kGreen,
                    label: 'Disponibles uniquement',
                    subtitle: 'Masquer les médecins occupés',
                    value: _availableOnly,
                    onChanged: (v) => setState(() => _availableOnly = v),
                  ),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    icon: Icons.circle,
                    iconColor: _kGreen2,
                    label: 'En ligne maintenant',
                    subtitle: 'Connectés et actifs',
                    value: _onlineOnly,
                    onChanged: (v) => setState(() => _onlineOnly = v),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _kLine2),

            // ── Apply button ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_kViolet, Color(0xFF6D28D9)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: _kViolet.withAlpha(80),
                          blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(_FilterState(
                      sortBy: _sortBy,
                      availableOnly: _availableOnly,
                      onlineOnly: _onlineOnly,
                    )),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Appliquer',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15)),
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

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? iconColor.withAlpha(30) : _kSurface2,
          border: Border.all(color: value ? iconColor.withAlpha(80) : _kLine2),
        ),
        child: Icon(icon, size: 14, color: value ? iconColor : _kInkDim),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kInk)),
          const SizedBox(height: 1),
          Text(subtitle,
              style: TextStyle(fontSize: 11.5, color: _kInkDim)),
        ]),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: iconColor,
        activeTrackColor: iconColor.withAlpha(80),
        inactiveTrackColor: _kLine2,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ]);
  }
}

