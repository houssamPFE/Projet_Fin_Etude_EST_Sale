import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart' show DioException;
import '../../../core/network/dio_client.dart' show fixStorageUrl, dioProvider;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/current_user_provider.dart';
import '../../home/models/expert_model.dart';
import '../../home/providers/home_providers.dart';
import '../../chat/providers/conversations_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewData {
  final String reviewer;
  final String initials;
  final Color reviewerColor;
  final int rating;
  final String comment;
  final String date;
  const _ReviewData({
    required this.reviewer,
    required this.initials,
    required this.reviewerColor,
    required this.rating,
    required this.comment,
    required this.date,
  });
}



// ─────────────────────────────────────────────────────────────────────────────
// ExpertProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ExpertProfileScreen extends ConsumerWidget {
  final ExpertModel expert;

  const ExpertProfileScreen({
    super.key,
    required this.expert,
  });

  String get name => expert.name;
  String get specialty => expert.specialty;
  double get rating => expert.rating;
  int get reviewCount => expert.reviewCount;
  String get initials => expert.initials;
  Color get color => expert.avatarColor;

  String get _bio => expert.bio.isNotEmpty
      ? expert.bio
      : 'Aucune biographie disponible.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final reviewsAsync = ref.watch(expertReviewsProvider(expert.id));
    // Live data — polls every 20 s so the online dot stays accurate.
    final liveExpertAsync = ref.watch(expertLiveProvider(expert.id));
    final isOnline = liveExpertAsync.maybeWhen(
      data: (e) => e.isOnline,
      orElse: () => expert.isOnline, // fallback to navigation snapshot
    );
    final isAvailable = liveExpertAsync.maybeWhen(
      data: (e) => e.isAvailable,
      orElse: () => expert.isAvailable,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ProfileBackground(size: size, accentColor: color),

          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 90 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero ──────────────────────────────────────────────────
                _HeroSection(
                  name: name,
                  specialty: specialty,
                  rating: rating,
                  reviewCount: reviewCount,
                  initials: initials,
                  avatarUrl: expert.avatarUrl,
                  color: color,
                  online: isOnline,
                ),

                const SizedBox(height: 4),

                // ── Stats ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatsRow(rating: rating, reviewCount: reviewCount),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── À propos ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('À propos'),
                      const SizedBox(height: 12),
                      _AboutCard(bio: _bio),
                    ],
                  ),
                ).animate().fadeIn(delay: 280.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Tarifs ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Tarifs de consultation'),
                      const SizedBox(height: 12),
                      _ConsultationCard(
                        icon: Icons.chat_outlined,
                        label: 'Consultation rapide',
                        duration: '30 min',
                        color: color,
                      ),
                      const SizedBox(height: 10),
                      _ConsultationCard(
                        icon: Icons.medical_services_outlined,
                        label: 'Consultation standard',
                        duration: '45 min',
                        color: color,
                      ),
                      const SizedBox(height: 10),
                      _ConsultationCard(
                        icon: Icons.health_and_safety_outlined,
                        label: 'Consultation complète',
                        duration: '60 min',
                        color: color,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 360.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Avis ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitleWithBadge(
                        title: 'Avis clients',
                        badge: '$reviewCount avis',
                      ),
                      const SizedBox(height: 12),
                      reviewsAsync.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        error: (e, s) => const SizedBox.shrink(),
                        data: (reviews) => reviews.isEmpty
                            ? Text(
                                'Aucun avis pour le moment.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              )
                            : Column(
                                children: reviews.take(3).map((r) {
                                  final user = r['user'] as Map<String, dynamic>?;
                                  final name = user?['name'] as String? ?? 'Utilisateur';
                                  final parts = name.trim().split(' ');
                                  final initials = parts.length >= 2
                                      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                                      : name.substring(0, 1).toUpperCase();
                                  final rating = (r['rating'] as num?)?.toInt() ?? 5;
                                  final comment = r['comment'] as String? ?? '';
                                  final createdAt = r['created_at'] as String? ?? '';
                                  final date = createdAt.isNotEmpty
                                      ? createdAt.substring(0, 10)
                                      : '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ReviewCard(
                                      review: _ReviewData(
                                        reviewer: name,
                                        initials: initials,
                                        reviewerColor: AppColors.primary,
                                        rating: rating,
                                        comment: comment,
                                        date: date,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 440.ms, duration: 500.ms),
              ],
            ),
          ),

          // ── Sticky CTA ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomCTA(
              expertId: expert.id,
              categoryId: expert.categoryId,
              bottomPadding: bottomPadding,
              name: name,
              initials: initials,
              color: color,
              specialty: specialty,
              online: isAvailable,
              avatarUrl: expert.avatarUrl,
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

class _ProfileBackground extends StatelessWidget {
  final Size size;
  final Color accentColor;
  const _ProfileBackground({required this.size, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.04,
          right: -size.width * 0.25,
          child: BlurOrb(
            width: size.width * 0.70,
            height: size.height * 0.28,
            color: accentColor.withAlpha(28),
          ),
        ),
        Positioned(
          top: size.height * 0.40,
          left: -size.width * 0.30,
          child: BlurOrb(
            width: size.width * 0.60,
            height: size.width * 0.60,
            color: const Color(0x156366F1),
          ),
        ),
        Positioned(
          bottom: -size.height * 0.04,
          right: size.width * 0.10,
          child: BlurOrb(
            width: size.width * 0.55,
            height: size.height * 0.18,
            color: const Color(0x108B5CF6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String initials;
  final String? avatarUrl;
  final Color color;
  final bool online;

  const _HeroSection({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.initials,
    this.avatarUrl,
    required this.color,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withAlpha(42), color.withAlpha(8), Colors.transparent],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
              child: Row(
                children: [
                  const NexoraBackButton(),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.bookmark_border_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // Avatar with glow rings
            _buildAvatar().animate().fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.88, 0.88),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 20),

            // Name
            Text(
              name,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 120.ms, duration: 500.ms),

            const SizedBox(height: 8),

            // Specialty badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Text(
                specialty,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 160.ms, duration: 500.ms),

            const SizedBox(height: 16),

            // Rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 18),
                const SizedBox(width: 5),
                Text(
                  rating.toStringAsFixed(1),
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($reviewCount avis)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 190.ms, duration: 500.ms),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Outer ambient glow
        Container(
          width: 152,
          height: 152,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(16),
          ),
        ),
        // Mid ring
        Container(
          width: 124,
          height: 124,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(26),
          ),
        ),
        // Gradient border + avatar
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          padding: const EdgeInsets.all(2.5),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: fixStorageUrl(avatarUrl!),
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _initialsInner(),
                    errorWidget: (_, _, _) => _initialsInner(),
                  )
                : _initialsInner(),
          ),
        ),
        // Online badge
        if (online)
          Positioned(
            bottom: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'En ligne',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialsInner() {
    return Container(
      color: color,
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.headlineLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  const _StatsRow({required this.rating, required this.reviewCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFBBF24),
          value: rating.toStringAsFixed(1),
          label: 'Note',
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: AppColors.primary,
          value: '$reviewCount',
          label: 'Avis',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 7),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section titles
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleLarge);
  }
}

class _SectionTitleWithBadge extends StatelessWidget {
  final String title;
  final String badge;
  const _SectionTitleWithBadge({required this.title, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleLarge),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(badge, style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About card
// ─────────────────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  final String bio;
  const _AboutCard({required this.bio});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        bio,
        style: AppTextStyles.bodyMedium.copyWith(height: 1.75),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Consultation card (subscription model — 1 credit per consultation)
// ─────────────────────────────────────────────────────────────────────────────

class _ConsultationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String duration;
  final Color color;

  const _ConsultationCard({
    required this.icon,
    required this.label,
    required this.duration,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(55)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_outlined, size: 11, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(duration, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Text(
                        '1 crédit',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Review card
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final _ReviewData review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: review.reviewerColor.withAlpha(40),
                  border: Border.all(
                    color: review.reviewerColor.withAlpha(60),
                  ),
                ),
                child: Center(
                  child: Text(
                    review.initials,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: review.reviewerColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(review.date, style: AppTextStyles.caption),
                  ],
                ),
              ),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFBBF24),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky bottom CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCTA extends ConsumerStatefulWidget {
  final int expertId;
  final int categoryId;
  final double bottomPadding;
  final String name;
  final String initials;
  final Color color;
  final String specialty;
  final bool online;
  final String? avatarUrl;

  const _BottomCTA({
    required this.expertId,
    required this.categoryId,
    required this.bottomPadding,
    required this.name,
    required this.initials,
    required this.color,
    required this.specialty,
    required this.online,
    this.avatarUrl,
  });

  @override
  ConsumerState<_BottomCTA> createState() => _BottomCTAState();
}

class _BottomCTAState extends ConsumerState<_BottomCTA> {
  bool _loading = false;

  Future<void> _startConversation() async {
    if (_loading) return;

    // ── Plan check ──────────────────────────────────────────────────────────
    // Free users and users with no credits must upgrade before consulting.
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    if (user.plan == 'free' || !user.planIsActive) {
      if (mounted) {
        context.push(AppRoutes.upgrade, extra: {'reason': 'no_plan'});
      }
      return;
    }
    if (user.consultationCredits <= 0) {
      if (mounted) {
        context.push(AppRoutes.upgrade, extra: {'reason': 'no_credits'});
      }
      return;
    }

    setState(() => _loading = true);

    try {
      final dio = ref.read(dioProvider);

      // Step 1: Create the conversation WITHOUT an initial message.
      // Sending a message here would trigger the n8n AI pipeline before
      // the conversation is escalated, causing the AI to reply instead of
      // the doctor.
      final createRes = await dio.post(
        '/conversations',
        data: {'category_id': widget.categoryId},
      );
      final createPayload =
          ((createRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
      final conversation =
          (createPayload['conversation'] as Map<String, dynamic>? ?? createPayload);
      final conversationId = conversation['id'] as int;

      // Step 2: Immediately escalate to this specific doctor.
      // Deducts 1 credit and sets conversation.status = 'expert'.
      await dio.post(
        '/conversations/$conversationId/escalate',
        data: {'expert_id': widget.expertId},
      );

      if (!mounted) return;
      ref.invalidate(conversationsProvider);

      // Step 3: Open the doctor chat — the user sends their first message.
      context.push(AppRoutes.chat, extra: {
        'name': widget.name,
        'initials': widget.initials,
        'color': widget.color,
        'subtitle': widget.specialty,
        'online': widget.online,
        'isAi': false,
        'conversationId': conversationId,
        'avatarUrl': widget.avatarUrl,
        'isValidated': true,
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 402) {
        final reason = e.response?.data?['reason'] as String? ?? 'no_plan';
        context.push(AppRoutes.upgrade, extra: {'reason': reason});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du démarrage de la consultation.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read plan reactively so the button label updates if the user upgrades.
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isFree = user == null || user.plan == 'free' || !user.planIsActive;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + widget.bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(242),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Cost badge — for free users show "Pro requis"
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Coût',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                isFree ? 'Pro requis' : '1 crédit',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isFree
                      ? const Color(0xFF8B5CF6)
                      : AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _loading
                ? NexoraGradientButton(
                    label: 'Chargement...',
                    onTap: () {},
                    height: 50,
                  )
                : isFree
                    ? GestureDetector(
                        onTap: _startConversation,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.workspace_premium_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Passer au Pro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : NexoraGradientButton(
                        label: 'Démarrer une consultation',
                        onTap: _startConversation,
                        height: 50,
                      ),
          ),
        ],
      ),
    );
  }
}
