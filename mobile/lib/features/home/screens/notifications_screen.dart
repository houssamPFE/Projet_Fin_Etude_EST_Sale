import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/main_layout.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsNotifierProvider);
    final notifier = ref.read(notificationsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withAlpha(240),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('Notifications'),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: false,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllRead,
              child: Text(
                'Tout lire',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: () {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state.error != null && state.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off_outlined,
                    color: Color(0xFF64748B), size: 48),
                const SizedBox(height: 16),
                Text(
                  'Impossible de charger\nles notifications',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: notifier.refresh,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        if (state.notifications.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: notifier.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: state.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final notif = state.notifications[i];
              return _NotifTile(
                notif: notif,
                onTap: () => _onTap(context, ref, notif),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 40 * i))
                  .slideY(begin: 0.05, end: 0);
            },
          ),
        );
      }(),
      bottomNavigationBar: PremiumBottomNavBar(
        currentPage: -1,
        onTap: (i) {
          final routes = [
            AppRoutes.home,
            AppRoutes.experts,
            AppRoutes.messages,
            AppRoutes.profile,
          ];
          context.go(routes[i]);
        },
        onAiTap: () => context.push(AppRoutes.aiTriage),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(15),
              border: Border.all(color: AppColors.primary.withAlpha(30)),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune notification',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _onTap(
      BuildContext context, WidgetRef ref, Map<String, dynamic> notif) async {
    final notifier = ref.read(notificationsNotifierProvider.notifier);
    if (notif['read_at'] == null) {
      await notifier.markRead(notif['id']);
    }
    final data = notif['data'] as Map<String, dynamic>?;
    final convId = data?['conversation_id'];
    if (convId != null && context.mounted) {
      context.push(AppRoutes.chat, extra: {
        'name': data?['expert_name'] ?? 'Expert',
        'initials': ((data?['expert_name'] as String?) ?? 'E').isNotEmpty
            ? (data!['expert_name'] as String)[0].toUpperCase()
            : 'E',
        'color': const Color(0xFF8B5CF6),
        'subtitle': data?['specialty'] ?? 'Expert',
        'online': true,
        'isAi': false,
        'conversationId': int.tryParse(convId.toString()),
      });
    }
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = notif['read_at'] == null;
    final type = notif['type'] as String? ?? '';
    final title = notif['title'] as String? ?? 'Notification';
    final body = notif['body'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surfaceElevated : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withAlpha(60)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _iconColor(type).withAlpha(20),
                border: Border.all(color: _iconColor(type).withAlpha(40)),
              ),
              child:
                  Icon(_iconFor(type), color: _iconColor(type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('message')) return Icons.chat_bubble_rounded;
    if (type.contains('expert') || type.contains('assign'))
      return Icons.medical_services_rounded;
    if (type.contains('payment')) return Icons.payment_rounded;
    if (type.contains('urgent') || type.contains('emergency'))
      return Icons.warning_rounded;
    return Icons.notifications_rounded;
  }

  Color _iconColor(String type) {
    if (type.contains('urgent') || type.contains('emergency'))
      return const Color(0xFFEF4444);
    if (type.contains('payment')) return const Color(0xFF22C55E);
    if (type.contains('expert') || type.contains('assign'))
      return const Color(0xFF8B5CF6);
    return AppColors.primary;
  }
}
