import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/conversations_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: false,
        backgroundColor: AppColors.background.withAlpha(240),
        surfaceTintColor: Colors.transparent,
      ),
      body: conversations.when(
        loading: () => Column(
          children: List.generate(
            6,
            (i) => const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ShimmerContainer(width: double.infinity, height: 82, borderRadius: 16),
            ),
          ),
        ),
        error: (err, st) => ErrorStateWidget(
          message: 'Impossible de charger vos messages.',
          onRetry: () => ref.refresh(conversationsProvider.future),
        ),
        data: (convs) => convs.isEmpty
            ? EmptyStateWidget(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Aucune conversation',
                message: 'Vos échanges avec les experts apparaîtront ici.',
                buttonText: 'Trouver un expert',
                onButtonTap: () => context.push(AppRoutes.experts),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
                onRefresh: () async => ref.refresh(conversationsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: convs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = convs[index];
                    return _ConversationTile(
                      conversation: c,
                    ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final id = conversation['id'] as int?;
    final expert = conversation['expert'] as Map<String, dynamic>?;
    final expertUser = expert?['user'] as Map<String, dynamic>?;
    final expertName = expertUser?['name'] as String? ?? 'Expert';
    final lastMessageMap = conversation['last_message'] as Map<String, dynamic>?;
    final lastMessage = lastMessageMap?['content'] as String? ?? 'Aucun message';
    final isUnread = (conversation['unread_count'] as int? ?? 0) > 0;
    
    // For now, assigning a consistent color per expert
    final color = const Color(0xFF8B5CF6);

    return GestureDetector(
      onTap: id != null
          ? () => context.push(AppRoutes.chat, extra: {
                'name': expertName,
                'initials': expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
                'color': color,
                'subtitle': expert?['specialty'] ?? 'Expert',
                'online': true,
                'isAi': false,
                'conversationId': id,
              })
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surfaceElevated : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? AppColors.primary.withAlpha(80) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(26),
                border: Border.all(color: color.withAlpha(60)),
              ),
              child: Center(
                child: Text(
                  expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          expertName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage,
                    style: AppTextStyles.caption.copyWith(
                      color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
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
}
