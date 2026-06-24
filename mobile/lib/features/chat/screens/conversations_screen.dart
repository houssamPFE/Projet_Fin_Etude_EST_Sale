import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart' show fixStorageUrl;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/services/reverb_service.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/conversations_provider.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _ConvFilter { tous, nonLus, experts, ia }

extension _ConvFilterExt on _ConvFilter {
  String get label {
    switch (this) {
      case _ConvFilter.tous:     return 'Tous';
      case _ConvFilter.nonLus:  return 'Non lus';
      case _ConvFilter.experts:  return 'Experts';
      case _ConvFilter.ia:       return 'IA';
    }
  }

  IconData get icon {
    switch (this) {
      case _ConvFilter.tous:     return Icons.forum_rounded;
      case _ConvFilter.nonLus:  return Icons.mark_chat_unread_rounded;
      case _ConvFilter.experts:  return Icons.medical_services_rounded;
      case _ConvFilter.ia:       return Icons.auto_awesome_rounded;
    }
  }
}

// ── Sort enum ─────────────────────────────────────────────────────────────────

enum _SortOrder { recentes, anciennes, az }

extension _SortOrderExt on _SortOrder {
  String get label {
    switch (this) {
      case _SortOrder.recentes:  return 'Récentes';
      case _SortOrder.anciennes: return 'Plus anciennes';
      case _SortOrder.az:        return 'A → Z';
    }
  }

  IconData get icon {
    switch (this) {
      case _SortOrder.recentes:  return Icons.access_time_rounded;
      case _SortOrder.anciennes: return Icons.history_rounded;
      case _SortOrder.az:        return Icons.sort_by_alpha_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ConversationsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  final Map<int, bool> _onlineOverrides = {};
  final Map<int, StreamSubscription<Map<String, dynamic>>> _wsSubs = {};
  final TextEditingController _searchController = TextEditingController();
  // Conversations the user has opened this session — shown as read immediately
  final Set<int> _locallyRead = {};
  // Optimistic UI — remove/close instantly, API runs in background
  final Set<int> _optimisticDeleted = {};
  final Set<int> _optimisticClosed  = {};
  String      _searchQuery  = '';
  _ConvFilter _activeFilter = _ConvFilter.tous;
  _SortOrder  _sortOrder    = _SortOrder.recentes;
  bool        _onlineOnly   = false;
  Timer?      _refreshTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    // Refresh every 60 s so is_online reflects Redis TTL expiry (90 s).
    // Without this, stale "online" data lingers until the user pulls to refresh.
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) ref.invalidate(conversationsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    for (final sub in _wsSubs.values) sub.cancel();
    _wsSubs.clear();
    for (final id in List<int>.from(_onlineOverrides.keys)) {
      try { ref.read(reverbServiceProvider).unsubscribe(id); } catch (_) {}
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _isAiConv(Map<String, dynamic> c) {
    // No expert assigned → always AI, regardless of status value from backend
    if (c['expert'] == null) return true;
    final s  = c['status']  as String? ?? '';
    final ch = c['channel'] as String? ?? '';
    return s == 'ai' || ch == 'ai';
  }

  Future<void> _subscribePresence(List<Map<String, dynamic>> convs) async {
    final reverb = ref.read(reverbServiceProvider);
    for (final conv in convs) {
      final id = conv['id'] as int?;
      if (id == null || _wsSubs.containsKey(id)) continue;
      final stream = await reverb.subscribePrivate(id);
      _wsSubs[id] = stream.listen((event) {
        if (!mounted) return;
        final eventType = event['event'] as String?;
        if (eventType == 'user.presence') {
          final payload  = event['payload'] as Map<String, dynamic>? ?? {};
          final isOnline = payload['is_online'] as bool? ?? false;
          setState(() => _onlineOverrides[id] = isOnline);
        } else if (eventType == 'message.sent' || eventType == 'ai.response') {
          // New message from expert/AI — refresh the conversations list instantly
          // so the preview text and unread count update without pulling to refresh
          ref.invalidate(conversationsProvider);
        }
      });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _confirmAndDelete(int convId, String expertName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              'Cette conversation avec $expertName sera supprimée définitivement.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.5),
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
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Supprimer',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed != true) return;

    // Remove from UI immediately — API runs in background
    setState(() => _optimisticDeleted.add(convId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Conversation supprimée'),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }

    // Fire-and-forget — roll back on failure
    () async {
      try {
        await ref.read(conversationServiceProvider).deleteConversation(convId);
        // Purge offline cache so it doesn't reappear after back-navigation
        final cache = ref.read(offlineCacheProvider);
        final cached = await cache.loadConversations();
        if (cached != null) {
          final updated = cached.where((c) => c['id'] != convId).toList();
          await cache.saveConversations(updated);
        }
        if (mounted) ref.invalidate(conversationsProvider);
      } catch (_) {
        if (mounted) {
          setState(() => _optimisticDeleted.remove(convId));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Erreur lors de la suppression'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    }();
  }

  Future<void> _archiveConversation(int convId) async {
    // Show feedback immediately — API runs in background
    setState(() => _optimisticClosed.add(convId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Consultation clôturée'),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }

    () async {
      try {
        await ref.read(conversationServiceProvider).archiveConversation(convId);
        if (mounted) ref.invalidate(conversationsProvider);
      } catch (_) {
        if (mounted) {
          setState(() => _optimisticClosed.remove(convId));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Erreur lors de la clôture'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    }();
  }

  void _openActionSheet(BuildContext ctx, int convId, String expertName,
      String specialty, bool isOnline, Color color, String? avatarUrl,
      {bool isValidated = false}) {
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
        avatarUrl: avatarUrl,
        onOpen: () {
          Navigator.pop(ctx);
          _navigateToConv(ctx, convId, expertName, specialty, isOnline, color, avatarUrl,
              isValidated: isValidated);
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

  Future<void> _navigateToConv(BuildContext ctx, int convId, String expertName,
      String specialty, bool isOnline, Color color, String? avatarUrl,
      {bool isValidated = false, bool isClosed = false,
       bool hasExpert = false, int? existingRating}) async {
    setState(() => _locallyRead.add(convId));
    await ctx.push(AppRoutes.chat, extra: {
      'name': expertName,
      'initials': expertName.isNotEmpty ? expertName[0].toUpperCase() : 'E',
      'color': color,
      'subtitle': specialty,
      'online': isOnline,
      'isAi': false,
      'conversationId': convId,
      'avatarUrl': avatarUrl,
      'isValidated': isValidated,
      'isClosed': isClosed,
      'hasExpert': hasExpert,
      'existingRating': existingRating,
    });
    if (mounted) ref.invalidate(conversationsProvider);
  }

  void _openAdvancedFilter(BuildContext ctx) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AdvancedFilterSheet(
        currentSort: _sortOrder,
        onlineOnly: _onlineOnly,
        onApply: (sort, online) {
          Navigator.pop(ctx);
          setState(() {
            _sortOrder  = sort;
            _onlineOnly = online;
          });
        },
        onReset: () {
          Navigator.pop(ctx);
          setState(() {
            _sortOrder  = _SortOrder.recentes;
            _onlineOnly = false;
          });
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final isOffline     = ref.watch(isOfflineProvider);

    // Auto-switch to IA filter when triggered from the center FAB menu
    ref.listen(aiFilterRequestedProvider, (_, requested) {
      if (requested) {
        setState(() => _activeFilter = _ConvFilter.ia);
        ref.read(aiFilterRequestedProvider.notifier).state = false;
      }
    });

    conversations.whenData((convs) {
      Future.microtask(() => _subscribePresence(convs));
    });

    final totalUnread = conversations.maybeWhen(
      data: (convs) => convs.fold<int>(0, (sum, c) {
        final id = c['id'] as int?;
        if (id != null && _locallyRead.contains(id)) return sum;
        return sum + ((c['unread_count'] as int?) ?? 0);
      }),
      orElse: () => 0,
    );

    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ConversationsBackground(size: size),
          Column(
            children: [
              // ── Custom large header (matches Experts page style) ─────────────
              SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (totalUnread > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: [AppColors.primary, AppColors.secondary]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                totalUnread > 99 ? '99+' : '$totalUnread',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Vos conversations médicales',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: Colors.orange.shade800,
              child: Row(children: [
                const Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text('Mode hors ligne — données en cache',
                    style: AppTextStyles.caption.copyWith(color: Colors.white)),
              ]),
            ).animate().slideY(begin: -1, end: 0, duration: 300.ms),

          _SearchBar(controller: _searchController),

          _FilterRow(
            active: _activeFilter,
            counts: conversations.maybeWhen(
              data: (convs) {
                final visibleForCount = convs
                    .where((c) => !_optimisticDeleted.contains(c['id'] as int?))
                    .toList();
                return {
                  _ConvFilter.tous:    visibleForCount.length,
                  _ConvFilter.nonLus: visibleForCount.where((c) {
                    final id = c['id'] as int?;
                    if (id != null && _locallyRead.contains(id)) return false;
                    return (c['unread_count'] as int? ?? 0) > 0;
                  }).length,
                  _ConvFilter.experts: visibleForCount
                      .where((c) => !_isAiConv(c))
                      .length,
                  _ConvFilter.ia: visibleForCount
                      .where(_isAiConv)
                      .length,
                };
              },
              orElse: () => {},
            ),
            onChanged: (f) => setState(() => _activeFilter = f),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: conversations.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: 5,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) => const ShimmerContainer(
                    width: double.infinity, height: 82, borderRadius: 16),
              ),
              error: (err, st) => ErrorStateWidget(
                message: 'Impossible de charger vos messages.',
                onRetry: () => ref.refresh(conversationsProvider.future),
              ),
              data: (convs) {
                // Apply local optimistic overrides before any filtering
                final visible = convs
                    .where((c) => !_optimisticDeleted.contains(c['id'] as int?))
                    .map((c) {
                  final id = c['id'] as int?;
                  if (id != null && _optimisticClosed.contains(id) &&
                      (c['status'] as String?) != 'closed') {
                    return {...c, 'status': 'closed'};
                  }
                  return c;
                }).toList();

                var tabFiltered = visible.where((c) {
                  switch (_activeFilter) {
                    case _ConvFilter.tous:
                      return true;
                    case _ConvFilter.nonLus:
                      final cid = c['id'] as int?;
                      if (cid != null && _locallyRead.contains(cid)) return false;
                      return (c['unread_count'] as int? ?? 0) > 0;
                    case _ConvFilter.experts:
                      return !_isAiConv(c);
                    case _ConvFilter.ia:
                      return _isAiConv(c);
                  }
                }).toList();

                if (_onlineOnly) {
                  tabFiltered = tabFiltered.where((c) {
                    final expertUser =
                        (c['expert'] as Map<String, dynamic>?)?['user']
                            as Map<String, dynamic>?;
                    final id = c['id'] as int?;
                    return (id != null && _onlineOverrides[id] == true) ||
                        (expertUser?['is_online'] as bool? ?? false);
                  }).toList();
                }

                var filtered = _searchQuery.isEmpty
                    ? tabFiltered
                    : tabFiltered.where((c) {
                        final expert     = c['expert'] as Map<String, dynamic>?;
                        final expertUser = expert?['user'] as Map<String, dynamic>?;
                        final name = (expertUser?['name'] as String? ?? '').toLowerCase();
                        final title = (c['title'] as String? ?? '').toLowerCase();
                        final specialty =
                            (expert?['category']?['name'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery) ||
                            title.contains(_searchQuery) ||
                            specialty.contains(_searchQuery);
                      }).toList();

                filtered.sort((a, b) {
                  final aIsAi = _isAiConv(a);
                  final bIsAi = _isAiConv(b);
                  if (aIsAi && !bIsAi) return -1;
                  if (!aIsAi && bIsAi) return 1;
                  switch (_sortOrder) {
                    case _SortOrder.recentes:
                      return (b['updated_at'] as String? ?? '')
                          .compareTo(a['updated_at'] as String? ?? '');
                    case _SortOrder.anciennes:
                      return (a['updated_at'] as String? ?? '')
                          .compareTo(b['updated_at'] as String? ?? '');
                    case _SortOrder.az:
                      final an = ((a['expert']?['user']?['name'] as String?) ?? '').toLowerCase();
                      final bn = ((b['expert']?['user']?['name'] as String?) ?? '').toLowerCase();
                      return an.compareTo(bn);
                  }
                });

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.textSecondary.withAlpha(120)),
                        const SizedBox(height: 12),
                        Text('Aucun résultat pour "$_searchQuery"',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                if (visible.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Aucune conversation',
                    message: 'Vos échanges avec les experts apparaîtront ici.',
                    buttonText: 'Trouver un expert',
                    onButtonTap: () => context.push(AppRoutes.experts),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_activeFilter.icon,
                            size: 48,
                            color: AppColors.textSecondary.withAlpha(120)),
                        const SizedBox(height: 12),
                        Text(
                            'Aucune conversation '
                            '${_activeFilter.label.toLowerCase()}',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: () async => ref.refresh(conversationsProvider.future),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: filtered.length + 1,
                    itemBuilder: (ctx, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 2),
                          child: Row(children: [
                            Text(
                              '${filtered.length} conversation'
                              '${filtered.length > 1 ? 's' : ''}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _openAdvancedFilter(ctx),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(_sortOrder.icon, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(_sortOrder.label,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    )),
                                const SizedBox(width: 2),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 15, color: AppColors.primary),
                              ]),
                            ),
                          ]),
                        );
                      }

                      final c = filtered[index - 1];
                      final id = c['id'] as int?;
                      final expert = c['expert'] as Map<String, dynamic>?;
                      final expertUser = expert?['user'] as Map<String, dynamic>?;
                      final expertName = expertUser?['name'] as String? ?? 'Assistant IA';
                      final specialty = expert?['category']?['name'] as String? ??
                          expert?['specialty'] as String? ?? '';
                      final avatarUrl = expertUser?['avatar_url'] as String?;
                      final onlineOverride = id != null ? _onlineOverrides[id] : null;
                      final isOnline = onlineOverride ??
                          (expertUser?['is_online'] as bool? ?? false);
                      final unreadCount = _locallyRead.contains(id)
                          ? 0
                          : (c['unread_count'] as int? ?? 0);
                      final channel = c['channel'] as String? ?? 'ai';
                      final status  = c['status']  as String? ?? 'ai';
                      final isValidated = (expert?['status'] as String?) == 'validated';
                      final isAi = _isAiConv(c);

                      final colorSeed = expertName.codeUnits.fold(0, (a, b) => a + b);
                      const colors = [
                        Color(0xFF8B5CF6), Color(0xFF0EA5E9),
                        Color(0xFF10B981), Color(0xFFF59E0B),
                        Color(0xFFEC4899), Color(0xFF6366F1),
                      ];
                      final color = colors[colorSeed % colors.length];

                      if (id == null) return const SizedBox.shrink();

                      if (isAi) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey('ai_conv_$id'),
                            background: _SwipeBackground.archive(),
                            secondaryBackground: _SwipeBackground.delete(),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                await _confirmAndDelete(id, 'Assistant IA Nexora');
                              } else {
                                await _archiveConversation(id);
                              }
                              return false;
                            },
                            child: GestureDetector(
                              onTap: () async {
                                setState(() => _locallyRead.add(id));
                                await ctx.push(AppRoutes.chat, extra: {
                                  'name': 'Assistant IA Nexora',
                                  'initials': 'N',
                                  'color': const Color(0xFF6366F1),
                                  'subtitle': 'Assistant médical IA',
                                  'online': true,
                                  'isAi': true,
                                  'conversationId': id,
                                  'avatarUrl': null,
                                });
                                if (mounted) ref.invalidate(conversationsProvider);
                              },
                              onLongPress: () => _openActionSheet(
                                ctx, id, 'Assistant IA Nexora', 'Intelligence Artificielle',
                                true, const Color(0xFF6366F1), null,
                              ),
                              child: _AiConvTile(conversation: c, unreadCount: unreadCount)
                                  .animate()
                                  .fadeIn(delay: Duration(milliseconds: 40 * (index - 1)))
                                  .slideY(begin: 0.08, end: 0),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey('conv_$id'),
                          background: _SwipeBackground.archive(),
                          secondaryBackground: _SwipeBackground.delete(),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              await _confirmAndDelete(id, expertName);
                            } else {
                              await _archiveConversation(id);
                            }
                            return false;
                          },
                          child: GestureDetector(
                            onLongPress: () => _openActionSheet(
                                ctx, id, expertName, specialty, isOnline, color, avatarUrl,
                                isValidated: isValidated),
                            onTap: () => _navigateToConv(
                                ctx, id, expertName, specialty, isOnline, color, avatarUrl,
                                isValidated: isValidated,
                                isClosed: (c['status'] as String?) == 'closed',
                                hasExpert: c['expert_id'] != null,
                                existingRating: c['rating'] as int?),
                            child: _ConvTile(
                              conversation: c,
                              expertName: expertName,
                              specialty: specialty,
                              avatarUrl: avatarUrl,
                              isOnline: isOnline,
                              unreadCount: unreadCount,
                              color: color,
                              channel: channel,
                              status: status,
                              isValidated: isValidated,
                            )
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 40 * (index - 1)))
                                .slideY(begin: 0.08, end: 0),
                          ),
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
        builder: (context, value, child) => TextField(
          controller: controller,
          style: AppTextStyles.bodyMedium
              .copyWith(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Rechercher un médecin, une spécialité…',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary, fontSize: 13.5),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, size: 19,
                  color: value.text.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: value.text.isNotEmpty
                ? GestureDetector(
                    onTap: controller.clear,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final _ConvFilter active;
  final Map<_ConvFilter, int> counts;
  final ValueChanged<_ConvFilter> onChanged;

  const _FilterRow({
    required this.active,
    required this.counts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _ConvFilter.values.map((f) {
          final isActive = f == active;
          final count = counts[f] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary])
                      : null,
                  color: isActive ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isActive ? Colors.transparent : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(f.icon, size: 13,
                      color: isActive ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(f.label,
                      style: AppTextStyles.caption.copyWith(
                        color: isActive ? Colors.white : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12.5,
                      )),
                  if (count > 0 && f != _ConvFilter.tous) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withAlpha(40)
                            : AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$count',
                          style: AppTextStyles.caption.copyWith(
                            color: isActive ? Colors.white : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          )),
                    ),
                  ],
                ]),
              ),
            ),
          );
        }).toList(),
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
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
          ],
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withAlpha(30)),
            child: Icon(icon, color: color, size: 18),
          ),
          if (alignment == MainAxisAlignment.start) ...[
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// ── AI Conversation Tile ──────────────────────────────────────────────────────

class _AiConvTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final int unreadCount;

  const _AiConvTile({required this.conversation, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final lastMsg  = conversation['last_message'] as Map<String, dynamic>?;
    final content  = lastMsg?['content'] as String?;
    final preview  = (content != null && content.isNotEmpty)
        ? content
        : 'Votre assistant médical intelligent';
    final timeStr  = _ConvTile._formatTime(
        lastMsg?['created_at'] as String? ??
            conversation['updated_at'] as String?);
    final isUnread = unreadCount > 0;

    final isDark = AppThemePreset.current.brightness == Brightness.dark;
    final gradientColors = isDark 
        ? [const Color(0xFF1E1B4B), const Color(0xFF312E81).withAlpha(220)]
        : [AppColors.surfaceElevated, AppColors.card];
    final baseColor = isDark ? const Color(0xFF6366F1) : AppColors.primary;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final badgeBg = isDark ? const Color(0xFF6366F1).withAlpha(50) : AppColors.primary.withAlpha(40);
    final badgeText = isDark ? const Color(0xFFA5B4FC) : AppColors.primary;
    final previewColor = isDark ? Colors.white.withAlpha(isUnread ? 220 : 130) : AppColors.textSecondary;
    final timeColor = isUnread 
        ? (isDark ? const Color(0xFFA5B4FC) : AppColors.primary)
        : (isDark ? Colors.white.withAlpha(100) : AppColors.textTertiary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(
          color: baseColor.withAlpha(isUnread ? 120 : 55),
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withAlpha(isUnread ? 55 : 25),
            blurRadius: isUnread ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: isDark 
                      ? [const Color(0xFF818CF8), const Color(0xFF4F46E5)]
                      : [AppColors.primaryLight, AppColors.primary]),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withAlpha(90),
                  blurRadius: 14, spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/nexora1.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: OnlinePresenceDot(size: 13),
          ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text('Assistant IA Nexora',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: baseColor.withAlpha(80)),
                ),
                child: Text('Assistant IA',
                    style: AppTextStyles.caption.copyWith(
                      color: badgeText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              const Spacer(),
              Text(timeStr,
                  style: AppTextStyles.caption.copyWith(
                    color: timeColor,
                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 11,
                  )),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Expanded(
                child: Text(preview,
                    style: AppTextStyles.caption.copyWith(
                      color: previewColor,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700,
                        fontSize: 10.5),
                  )),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Conversation Tile ─────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String expertName;
  final String specialty;
  final String? avatarUrl;
  final bool isOnline;
  final int unreadCount;
  final Color color;
  final String channel;
  final String status;
  final bool isValidated;

  const _ConvTile({
    required this.conversation,
    required this.expertName,
    required this.specialty,
    required this.avatarUrl,
    required this.isOnline,
    required this.unreadCount,
    required this.color,
    required this.channel,
    required this.status,
    required this.isValidated,
  });

  static String _buildPreview(Map<String, dynamic>? msg) {
    if (msg == null) return 'Démarrer la conversation…';
    final senderType = msg['sender_type'] as String? ?? 'user';
    final msgType    = msg['type']        as String? ?? 'text';
    final content    = msg['content']     as String? ?? '';
    String prefix;
    switch (senderType) {
      case 'user':   prefix = 'Vous : '; break;
      case 'expert': prefix = 'Dr : ';   break;
      default:       prefix = 'IA : ';
    }
    if (msgType == 'audio') return '$prefix🎤 Message vocal';
    if (msgType == 'file')  return '$prefix📎 Fichier';
    return prefix + content;
  }

  static String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt     = DateTime.parse(isoDate).toLocal();
      final now    = DateTime.now();
      final today  = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      final diff   = today.difference(msgDay).inDays;
      if (diff == 0) return DateFormat('HH:mm').format(dt);
      if (diff == 1) return 'Hier';
      if (diff < 7)  return DateFormat('EEE', 'fr_FR').format(dt);
      return DateFormat('dd/MM/yy').format(dt);
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread       = unreadCount > 0;
    final lastMessageMap = conversation['last_message'] as Map<String, dynamic>?;
    final preview  = _buildPreview(lastMessageMap);
    final timeStr  = _formatTime(lastMessageMap?['created_at'] as String?
        ?? conversation['updated_at'] as String?);
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

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
            ? [BoxShadow(color: color.withAlpha(18), blurRadius: 12,
                offset: const Offset(0, 4))]
            : [],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasAvatar ? null : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withAlpha(180)]),
              color: hasAvatar ? AppColors.surfaceElevated : null,
              boxShadow: [BoxShadow(
                color: color.withAlpha(isUnread ? 80 : 40),
                blurRadius: isUnread ? 14 : 8,
                offset: const Offset(0, 3),
              )],
            ),
            child: ClipOval(child: hasAvatar
                ? CachedNetworkImage(
                    imageUrl: fixStorageUrl(avatarUrl!),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _initialsCircle(color, expertName),
                    errorWidget: (context, url, error) => _initialsCircle(color, expertName),
                  )
                : _initialsCircle(color, expertName)),
          ),
          if (isOnline)
            Positioned(bottom: 0, right: 0, child: OnlinePresenceDot(size: 13)),
          Positioned(
            top: -2, left: -4,
            child: _ChannelBadge(channel: channel, status: status),
          ),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Flexible(child: Text(expertName,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14.5,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isValidated) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.verified,
                size: 15,
                color: Color(0xFF3B82F6),
              ),
            ],
            const Spacer(),
            const SizedBox(width: 6),
            Text(timeStr, style: AppTextStyles.caption.copyWith(
              color: isUnread ? color : AppColors.textSecondary,
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
              fontSize: 11.5,
            )),
          ]),
          const SizedBox(height: 3),
          if (specialty.isNotEmpty)
            Text(specialty, style: AppTextStyles.caption.copyWith(
                color: color.withAlpha(200), fontSize: 11.5,
                fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(child: Text(preview,
                style: AppTextStyles.caption.copyWith(
                  color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                  fontSize: 12.5,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 20, maxWidth: 32),
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withAlpha(200)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 10.5),
                )),
              ),
            ],
          ]),
        ])),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded, size: 18,
            color: AppColors.textSecondary.withAlpha(100)),
      ]),
    );
  }
}

// ── Advanced Filter Sheet ─────────────────────────────────────────────────────

class _AdvancedFilterSheet extends StatefulWidget {
  final _SortOrder currentSort;
  final bool onlineOnly;
  final void Function(_SortOrder sort, bool online) onApply;
  final VoidCallback onReset;

  const _AdvancedFilterSheet({
    required this.currentSort,
    required this.onlineOnly,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<_AdvancedFilterSheet> {
  late _SortOrder _sort;
  late bool _online;

  @override
  void initState() {
    super.initState();
    _sort   = widget.currentSort;
    _online = widget.onlineOnly;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Text('Filtres', style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: widget.onReset,
                child: Text('Réinitialiser', style: AppTextStyles.caption
                    .copyWith(color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Trier par', style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600,
                  fontSize: 12)),
              const SizedBox(height: 10),
              ..._SortOrder.values.map((s) {
                final active = s == _sort;
                return GestureDetector(
                  onTap: () => setState(() => _sort = s),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary.withAlpha(20) : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? AppColors.primary.withAlpha(80) : AppColors.border,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Icon(s.icon, size: 16,
                          color: active
                              ? AppColors.primary : AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(s.label, style: AppTextStyles.bodyMedium.copyWith(
                        color: active ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13.5,
                      )),
                      const Spacer(),
                      if (active)
                        Container(width: 18, height: 18,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary),
                          child: const Icon(Icons.check_rounded,
                              size: 11, color: Colors.white)),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _online
                      ? const Color(0xFF4ADE80).withAlpha(20) : AppColors.card,
                  border: Border.all(color: _online
                      ? const Color(0xFF4ADE80).withAlpha(80) : AppColors.border),
                ),
                child: Icon(Icons.circle, size: 10,
                    color: _online
                        ? const Color(0xFF4ADE80) : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('En ligne uniquement',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('Médecins disponibles seulement',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary, fontSize: 11.5)),
              ])),
              Switch(
                value: _online,
                onChanged: (v) => setState(() => _online = v),
                activeThumbColor: const Color(0xFF4ADE80),
                inactiveTrackColor: AppColors.border,
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity, height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed: () => widget.onApply(_sort, _online),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Appliquer', style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Action Sheet ──────────────────────────────────────────────────────────────

class _ConvActionSheet extends StatelessWidget {
  final String expertName;
  final String specialty;
  final bool isOnline;
  final Color color;
  final String? avatarUrl;
  final VoidCallback onOpen;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _ConvActionSheet({
    required this.expertName,
    required this.specialty,
    required this.isOnline,
    required this.color,
    required this.avatarUrl,
    required this.onOpen,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
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
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasAvatar ? null : LinearGradient(
                    colors: [color, color.withAlpha(180)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                  color: hasAvatar ? AppColors.surfaceElevated : null,
                ),
                child: ClipOval(child: hasAvatar
                    ? CachedNetworkImage(
                        imageUrl: fixStorageUrl(avatarUrl!),
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _initialsCircle(color, expertName),
                        errorWidget: (_, __, ___) => _initialsCircle(color, expertName),
                      )
                    : _initialsCircle(color, expertName)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expertName, style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(specialty, style: AppTextStyles.caption
                      .copyWith(color: color.withAlpha(200))),
                  if (isOnline) ...[
                    const SizedBox(width: 8),
                    Container(width: 6, height: 6,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4ADE80))),
                    const SizedBox(width: 4),
                    Text('En ligne', style: AppTextStyles.caption
                        .copyWith(color: const Color(0xFF4ADE80))),
                  ],
                ]),
              ])),
            ]),
          ),
          Divider(height: 1, color: AppColors.border),
          _SheetAction(icon: Icons.open_in_new_rounded,
              iconColor: AppColors.primary,
              label: 'Ouvrir la conversation',
              subtitle: 'Voir les messages', onTap: onOpen),
          _SheetAction(icon: Icons.archive_outlined,
              iconColor: const Color(0xFFF59E0B),
              label: 'Archiver',
              subtitle: 'Masquer sans supprimer', onTap: onArchive),
          _SheetAction(icon: Icons.delete_outline_rounded,
              iconColor: const Color(0xFFEF4444),
              label: 'Supprimer',
              subtitle: 'Suppression définitive',
              isDestructive: true, onTap: onDelete),
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
                child: Text('Annuler', style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
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
          Container(width: 38, height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: iconColor.withAlpha(20)),
            child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDestructive
                  ? const Color(0xFFEF4444) : AppColors.textPrimary,
              fontSize: 14,
            )),
            const SizedBox(height: 1),
            Text(subtitle, style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 16,
              color: AppColors.textSecondary.withAlpha(100)),
        ]),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

Widget _initialsCircle(Color color, String name) {
  return Container(
    color: color,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'E',
        style: AppTextStyles.titleMedium
            .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _ChannelBadge extends StatelessWidget {
  final String channel;
  final String status;
  const _ChannelBadge({required this.channel, required this.status});

  @override
  Widget build(BuildContext context) {
    final isAi = channel == 'ai' || status == 'ai';
    final isExpert = channel == 'expert' || status == 'expert' ||
        channel == 'hybrid'   || status == 'hybrid';
    if (!isAi && !isExpert) return const SizedBox.shrink();
    final bgColor = isAi ? const Color(0xFF6366F1) : const Color(0xFF10B981);
    final icon    = isAi
        ? Icons.auto_awesome_rounded : Icons.medical_services_rounded;
    return Container(
      width: 18, height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: AppColors.background, width: 1.5),
      ),
      child: Icon(icon, size: 9, color: Colors.white),
    );
  }
}

class _ConversationsBackground extends StatelessWidget {
  final Size size;
  const _ConversationsBackground({required this.size});

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
