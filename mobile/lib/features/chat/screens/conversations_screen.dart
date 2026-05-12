import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/reverb_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/conversations_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  /// Live online overrides: convId → isOnline (updated via WebSocket)
  final Map<int, bool> _onlineOverrides = {};
  /// Active WS subscriptions keyed by conversation ID
  final Map<int, StreamSubscription<Map<String, dynamic>>> _wsSubs = {};
  /// Search bar controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final sub in _wsSubs.values) sub.cancel();
    _wsSubs.clear();
    for (final id in List<int>.from(_onlineOverrides.keys)) {
      try { ref.read(reverbServiceProvider).unsubscribe(id); } catch (_) {}
    }
    super.dispose();
  }

  /// Subscribe to user.presence events for conversations not yet subscribed.
  Future<void> _subscribePresence(List<Map<String, dynamic>> convs) async {
    final reverb = ref.read(reverbServiceProvider);
    for (final conv in convs) {
      final id = conv['id'] as int?;
      if (id == null || _wsSubs.containsKey(id)) continue;
      final stream = await reverb.subscribePrivate(id);
      _wsSubs[id] = stream.listen((event) {
        if (event['event'] != 'user.presence') return;
        final payload  = event['payload'] as Map<String, dynamic>? ?? {};
        final isOnline = payload['is_online'] as bool? ?? false;
        if (!mounted) return;
        setState(() => _onlineOverrides[id] = isOnline);
      });
    }
  }

  Future<void> _confirmAndDelete(int convId, String expertName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444).withAlpha(20),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 16),
              Text('Supprimer la conversation',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Cette conversation avec $expertName sera supprimée définitivement sur tous vos appareils.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Text('Annuler',
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Supprimer',
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(conversationServiceProvider).deleteConversation(convId);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Conversation supprimée'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Erreur lors de la suppression'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _archiveConversation(int convId) async {
    try {
      await ref.read(conversationServiceProvider).archiveConversation(convId);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Conversation archivée'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Erreur lors de l\'archivage'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _openActionSheet(
      BuildContext ctx, int convId, String expertName, String specialty, bool isOnline, Color color) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConvActionSheet(
        expertName: expertName,
        specialty: specialty,
        isOnline: isOnline,
        color: color,
        onOpen: () {
          Navigator.pop(ctx);
          _navigateToConv(ctx, convId, expertName, specialty, isOnline, color);
        },
        onArchive: () {
          Navigator.pop(ctx);
          _archiveConversation(convId);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmAndDelete(convId, expertName);
        },
      ),
    );
  }

  void _navigateToConv(
      BuildContext ctx, int convId, String expertName, String specialty, bool isOnline, Color color) {
    ctx.push(AppRoutes.chat, extra: {
      'name': expertName,
      'initials': expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
      'color': color,
      'subtitle': specialty,
      'online': isOnline,
      'isAi': false,
      'conversationId': convId,
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final isOffline     = ref.watch(isOfflineProvider);

    conversations.whenData((convs) {
      Future.microtask(() => _subscribePresence(convs));
    });

    final totalUnread = conversations.maybeWhen(
      data: (convs) => convs.fold<int>(0, (sum, c) => sum + ((c['unread_count'] as int?) ?? 0)),
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          const Text('Messages'),
          if (totalUnread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                totalUnread > 99 ? '99+' : '$totalUnread',
                style: AppTextStyles.caption.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
          ],
        ]),
        centerTitle: false,
        backgroundColor: AppColors.background.withAlpha(240),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Offline banner
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.orange.shade800,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Mode hors ligne — données en cache',
                      style: AppTextStyles.caption.copyWith(color: Colors.white)),
                ],
              ),
            ).animate().slideY(begin: -1, end: 0, duration: 300.ms),

          // Search bar
          _SearchBar(controller: _searchController),

          Expanded(
            child: conversations.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => const ShimmerContainer(
                    width: double.infinity, height: 82, borderRadius: 16),
              ),
              error: (err, st) => ErrorStateWidget(
                message: 'Impossible de charger vos messages.',
                onRetry: () => ref.refresh(conversationsProvider.future),
              ),
              data: (convs) {
                final filtered = _searchQuery.isEmpty
                    ? convs
                    : convs.where((c) {
                        final expert     = c['expert'] as Map<String, dynamic>?;
                        final expertUser = expert?['user'] as Map<String, dynamic>?;
                        final name       = (expertUser?['name'] as String? ?? '').toLowerCase();
                        final title      = (c['title'] as String? ?? '').toLowerCase();
                        final specialty  = (expert?['category']?['name'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery) ||
                               title.contains(_searchQuery) ||
                               specialty.contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48,
                            color: AppColors.textSecondary.withAlpha(120)),
                        const SizedBox(height: 12),
                        Text('Aucun résultat pour "$_searchQuery"',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                if (convs.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Aucune conversation',
                    message: 'Vos échanges avec les experts apparaîtront ici.',
                    buttonText: 'Trouver un expert',
                    onButtonTap: () => context.push(AppRoutes.experts),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: () async => ref.refresh(conversationsProvider.future),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final c          = filtered[index];
                      final id         = c['id'] as int?;
                      final expert     = c['expert'] as Map<String, dynamic>?;
                      final expertUser = expert?['user'] as Map<String, dynamic>?;
                      final expertName = expertUser?['name'] as String? ?? 'Expert';
                      final specialty  = expert?['category']?['name'] as String?
                          ?? expert?['specialty'] as String? ?? 'Expert';
                      final onlineOverride = id != null ? _onlineOverrides[id] : null;
                      final isOnline   = onlineOverride ?? (expertUser?['is_online'] as bool? ?? false);
                      final unreadCount = c['unread_count'] as int? ?? 0;

                      final colorSeed = expertName.codeUnits.fold(0, (a, b) => a + b);
                      const colors = [
                        Color(0xFF8B5CF6), Color(0xFF0EA5E9), Color(0xFF10B981),
                        Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF6366F1),
                      ];
                      final color = colors[colorSeed % colors.length];

                      if (id == null) return const SizedBox.shrink();

                      return Dismissible(
                        key: ValueKey('conv_$id'),
                        // Swipe right → archive (amber)
                        background: _SwipeBackground.archive(),
                        // Swipe left → delete (red)
                        secondaryBackground: _SwipeBackground.delete(),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            await _confirmAndDelete(id, expertName);
                          } else {
                            await _archiveConversation(id);
                          }
                          return false; // we handle UI via provider invalidation
                        },
                        child: GestureDetector(
                          onLongPress: () => _openActionSheet(
                              ctx, id, expertName, specialty, isOnline, color),
                          onTap: () => _navigateToConv(
                              ctx, id, expertName, specialty, isOnline, color),
                          child: _ConvTile(
                            conversation: c,
                            expertName: expertName,
                            specialty: specialty,
                            isOnline: isOnline,
                            unreadCount: unreadCount,
                            color: color,
                          ).animate()
                            .fadeIn(delay: Duration(milliseconds: 40 * index))
                            .slideY(begin: 0.08, end: 0),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) => Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher un médecin, une spécialité…',
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (value.text.isNotEmpty)
              GestureDetector(
                onTap: controller.clear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Swipe Backgrounds ─────────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final MainAxisAlignment alignment;

  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  factory _SwipeBackground.archive() => const _SwipeBackground(
        color: Color(0xFFF59E0B),
        icon: Icons.archive_outlined,
        label: 'Archiver',
        alignment: MainAxisAlignment.start,
      );

  factory _SwipeBackground.delete() => const _SwipeBackground(
        color: Color(0xFFEF4444),
        icon: Icons.delete_outline_rounded,
        label: 'Supprimer',
        alignment: MainAxisAlignment.end,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          if (alignment == MainAxisAlignment.end) ...[
            Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
          ],
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(30),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          if (alignment == MainAxisAlignment.start) ...[
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String expertName;
  final String specialty;
  final bool isOnline;
  final int unreadCount;
  final Color color;

  const _ConvTile({
    required this.conversation,
    required this.expertName,
    required this.specialty,
    required this.isOnline,
    required this.unreadCount,
    required this.color,
  });

  static String _buildPreview(Map<String, dynamic>? msg) {
    if (msg == null) return 'Démarrer la conversation…';
    final senderType = msg['sender_type'] as String? ?? 'user';
    final msgType    = msg['type'] as String? ?? 'text';
    final content    = msg['content'] as String? ?? '';
    String prefix;
    switch (senderType) {
      case 'user':   prefix = 'Vous : '; break;
      case 'expert': prefix = 'Dr : ';   break;
      default:       prefix = 'IA : ';
    }
    if (msgType == 'audio') return '${prefix}🎤 Message vocal';
    if (msgType == 'file')  return '${prefix}📎 Fichier';
    return prefix + content;
  }

  static String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt  = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final today    = DateTime(now.year, now.month, now.day);
      final msgDay   = DateTime(dt.year, dt.month, dt.day);
      final diff     = today.difference(msgDay).inDays;
      if (diff == 0)  return DateFormat('HH:mm').format(dt);
      if (diff == 1)  return 'Hier';
      if (diff < 7)   return DateFormat('EEE', 'fr_FR').format(dt);
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread       = unreadCount > 0;
    final lastMessageMap = conversation['last_message'] as Map<String, dynamic>?;
    final preview        = _buildPreview(lastMessageMap);
    final timeStr        = _formatTime(lastMessageMap?['created_at'] as String?
        ?? conversation['updated_at'] as String?);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surfaceElevated : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? color.withAlpha(70) : AppColors.border,
          width: isUnread ? 1.2 : 1,
        ),
        boxShadow: isUnread
            ? [BoxShadow(color: color.withAlpha(18), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Avatar
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withAlpha(180)],
              ),
              boxShadow: [BoxShadow(color: color.withAlpha(70), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Center(
              child: Text(
                expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
                style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (isOnline)
            Positioned(
              bottom: 0, right: 0,
              child: OnlinePresenceDot(size: 13),
            ),
        ]),
        const SizedBox(width: 14),
        // Text content
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  expertName,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: AppTextStyles.caption.copyWith(
                  color: isUnread ? color : AppColors.textSecondary,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 11.5,
                ),
              ),
            ]),
            const SizedBox(height: 3),
            Text(
              specialty,
              style: AppTextStyles.caption.copyWith(
                  color: color.withAlpha(200), fontSize: 11.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            Row(children: [
              Expanded(
                child: Text(
                  preview,
                  style: AppTextStyles.caption.copyWith(
                    color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 20, maxWidth: 32),
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withAlpha(200)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: AppTextStyles.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10.5),
                    ),
                  ),
                ),
              ],
            ]),
          ]),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded, size: 18,
            color: AppColors.textSecondary.withAlpha(100)),
      ]),
    );
  }
}

// ── Action Sheet ──────────────────────────────────────────────────────────────

class _ConvActionSheet extends StatelessWidget {
  final String expertName;
  final String specialty;
  final bool isOnline;
  final Color color;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ConvActionSheet({
    required this.expertName,
    required this.specialty,
    required this.isOnline,
    required this.color,
    required this.onOpen,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Expert header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
                    style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(expertName,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(specialty,
                        style: AppTextStyles.caption.copyWith(color: color.withAlpha(200))),
                    if (isOnline) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFF4ADE80)),
                      ),
                      const SizedBox(width: 4),
                      Text('En ligne',
                          style: AppTextStyles.caption.copyWith(color: const Color(0xFF4ADE80))),
                    ],
                  ]),
                ]),
              ),
            ]),
          ),
          Divider(height: 1, color: AppColors.border),
          // Actions
          _SheetAction(
            icon: Icons.open_in_new_rounded,
            iconColor: AppColors.primary,
            label: 'Ouvrir la conversation',
            subtitle: 'Voir les messages',
            onTap: onOpen,
          ),
          _SheetAction(
            icon: Icons.archive_outlined,
            iconColor: const Color(0xFFF59E0B),
            label: 'Archiver',
            subtitle: 'Masquer sans supprimer',
            onTap: onArchive,
          ),
          _SheetAction(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFEF4444),
            label: 'Supprimer',
            subtitle: 'Suppression définitive',
            isDestructive: true,
            onTap: onDelete,
          ),
          // Cancel
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Text('Annuler',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withAlpha(20),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? const Color(0xFFEF4444) : AppColors.textPrimary,
                    fontSize: 14,
                  )),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary.withAlpha(100)),
        ]),
      ),
    );
  }
}
