import 'dart:async';
import 'dart:io' as dart_io;
import 'dart:ui' show FontFeature;
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:open_file/open_file.dart';
import '../../../core/network/dio_client.dart' show fixStorageUrl, dioProvider;
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/current_user_provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String name;
  final String initials;
  final Color color;
  final String subtitle;
  final bool online;
  final bool isAi;
  final int? conversationId;
  final String? avatarUrl;
  final bool isValidated;
  final bool isClosed;
  final bool hasExpert;
  final int? existingRating;

  const ChatScreen({
    super.key,
    required this.name,
    required this.initials,
    required this.color,
    required this.subtitle,
    required this.online,
    required this.isAi,
    this.conversationId,
    this.avatarUrl,
    this.isValidated = false,
    this.isClosed = false,
    this.hasExpert = false,
    this.existingRating,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  Timer? _typingTimer;
  bool _ratingSheetShown = false;

  // Summary + PDF report
  String? _conversationSummary;
  bool _downloadingReport = false;

  bool get _usesPersistentAi => widget.isAi && widget.conversationId == null;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);

      // Send typing start; auto-stop after 2s idle
      if (widget.conversationId != null) {
        ref.read(chatProvider.notifier).sendTyping(isTyping: true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          ref.read(chatProvider.notifier).sendTyping(isTyping: false);
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_usesPersistentAi) {
        ref.read(aiChatProvider.notifier).initialize();
      } else {
        ref.read(chatProvider.notifier).initialize(
          isAi: widget.isAi,
          conversationId: widget.conversationId,
          otherOnline: widget.online,
        );
      }
      _scrollToBottom();

      // Show rating sheet once for closed expert consultations not yet rated
      if (widget.isClosed &&
          widget.hasExpert &&
          widget.existingRating == null &&
          !_ratingSheetShown &&
          widget.conversationId != null) {
        _ratingSheetShown = true;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _showRatingSheet();
        });
      }

      // Fetch consultation summary for closed conversations
      if (widget.isClosed && widget.conversationId != null) {
        _fetchSummary();
      }
    });
  }

  /// Fetches the conversation summary from the API (async, non-blocking).
  Future<void> _fetchSummary() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/conversations/${widget.conversationId}');
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (mounted && data != null) {
        setState(() {
          _conversationSummary = data['summary'] as String?;
        });
      }
    } catch (_) {
      // Summary unavailable — non-critical, card still shows with empty state
    }
  }

  /// Sends a suggestion chip text as if the user typed it.
  void _sendSuggestion(String text) {
    if (_usesPersistentAi) {
      ref.read(aiChatProvider.notifier).sendMessage(text);
    } else if (widget.conversationId != null) {
      ref.read(chatProvider.notifier).sendMessage(text);
    }
  }

  /// Called when the user taps "Consulter un médecin" in the ⋮ options menu
  /// while inside an AI conversation. Checks plan, then either escalates the
  /// current conversation or sends the user to the experts list.
  void _handleConsultDoctor() {
    final user = ref.read(currentUserProvider).valueOrNull;

    if (user == null || user.plan == 'free' || !user.planIsActive) {
      context.push(AppRoutes.upgrade, extra: {'reason': 'no_plan'});
      return;
    }
    if (user.consultationCredits <= 0) {
      context.push(AppRoutes.upgrade, extra: {'reason': 'no_credits'});
      return;
    }

    // Has a real persisted AI conversation → escalate it to the best available doctor.
    if (!_usesPersistentAi && widget.conversationId != null) {
      ref.read(chatProvider.notifier).escalateToDoctor();
      return;
    }

    // Persistent AI demo mode or no conversation yet → let the user pick a doctor.
    context.push(AppRoutes.experts);
  }

  /// Downloads the PDF report to the temp directory and opens it.
  Future<void> _downloadReport() async {
    if (_downloadingReport || widget.conversationId == null) return;
    setState(() => _downloadingReport = true);
    try {
      final dio = ref.read(dioProvider);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/rapport-consultation-${widget.conversationId}.pdf';

      await dio.download(
        '/conversations/${widget.conversationId}/report',
        filePath,
        options: Options(responseType: ResponseType.bytes),
      );

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune application pour ouvrir le PDF.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de télécharger le rapport.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingReport = false);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    _typingTimer?.cancel();
    if (_usesPersistentAi) {
      ref.read(aiChatProvider.notifier).sendMessage(_controller.text);
    } else {
      ref.read(chatProvider.notifier).sendTyping(isTyping: false);
      ref.read(chatProvider.notifier).sendMessage(_controller.text);
    }
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendAudio(String path, int durationSeconds) async {
    if (_usesPersistentAi) {
      await ref.read(aiChatProvider.notifier).sendAudioMessage(path, durationSeconds: durationSeconds);
    } else {
      await ref.read(chatProvider.notifier).sendAudioMessage(path, durationSeconds: durationSeconds);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendFile(String path, String fileName, String mimeType) async {
    if (_usesPersistentAi) {
      await ref.read(aiChatProvider.notifier).sendFileMessage(path, fileName, mimeType);
    } else {
      await ref.read(chatProvider.notifier).sendFileMessage(path, fileName, mimeType);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showRatingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RatingBottomSheet(
        conversationId: widget.conversationId!,
        expertName: widget.name,
        onSubmit: (rating, comment) {
          ref.read(chatProvider.notifier).rateConversation(
            widget.conversationId!,
            rating,
            comment: comment,
          );
        },
      ),
    );
  }

  void _showDeleteSheet(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteMessageSheet(
        onDeleteForMe: () {
          Navigator.pop(context);
          if (_usesPersistentAi) {
            ref.read(aiChatProvider.notifier).deleteForMe(message.id);
          } else {
            ref.read(chatProvider.notifier).deleteForMe(message.id);
          }
        },
        onDeleteForEveryone: widget.conversationId != null
            ? () {
                Navigator.pop(context);
                ref.read(chatProvider.notifier).deleteMessage(message.id);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final chatState = _usesPersistentAi
        ? ref.watch(aiChatProvider)
        : ref.watch(chatProvider);

    if (_usesPersistentAi) {
      ref.listen<ChatState>(aiChatProvider, (prev, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        // 402 upgrade redirect (AI mode escalation)
        if (next.escalate402Reason != null && prev?.escalate402Reason == null) {
          ref.read(aiChatProvider.notifier).clearEscalate402();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.push(AppRoutes.upgrade,
                  extra: {'reason': next.escalate402Reason});
            }
          });
        }
      });
    } else {
      ref.listen<ChatState>(chatProvider, (prev, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        // 402 upgrade redirect
        if (next.escalate402Reason != null && prev?.escalate402Reason == null) {
          ref.read(chatProvider.notifier).clearEscalate402();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.push(AppRoutes.upgrade,
                  extra: {'reason': next.escalate402Reason});
            }
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _ChatBackground(size: size),
          Column(
            children: [
              // Header — use live online status from provider if available,
              // fall back to the initial value passed when navigating
              _ChatHeader(
                name: widget.name,
                initials: widget.initials,
                color: widget.color,
                subtitle: widget.subtitle,
                online: chatState.isOtherOnline ?? widget.online,
                isAi: widget.isAi,
                conversationId: widget.conversationId,
                avatarUrl: widget.avatarUrl,
                isValidated: widget.isValidated,
                onConsultDoctor: widget.isAi ? _handleConsultDoctor : null,
              ),

              // Messages
              Expanded(
                child: chatState.isLoading && chatState.messages.isEmpty
                    ? const _MessagesSkeleton()
                    : chatState.error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  chatState.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => ref.refresh(chatProvider),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        : chatState.messages.isEmpty
                            ? (_usesPersistentAi
                                ? _AiEmptyState(onSuggestion: _sendSuggestion)
                                : const Center(child: Text('Aucun message')))
                            : ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                itemCount: chatState.messages.length +
                                    (chatState.isTyping ? 2 : 1),
                                itemBuilder: (context, i) {
                                  if (i == 0) return const _DateSeparator();

                                  final msgIndex = i - 1;

                                  if (chatState.isTyping &&
                                      msgIndex == chatState.messages.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: _TypingBubble(
                                        isAi: widget.isAi,
                                        initials: widget.initials,
                                        color: widget.color,
                                      ),
                                    );
                                  }

                                  final msg = chatState.messages[msgIndex];
                                  return _MessageBubble(
                                    message: msg,
                                    expertInitials: widget.initials,
                                    expertColor: widget.color,
                                    isAiMode: _usesPersistentAi,
                                    onLongPress: msg.type == MessageType.user && !msg.isDeleted
                                        ? () => _showDeleteSheet(context, msg)
                                        : null,
                                  );
                                },
                              ),
              ),

              // Summary card — shown for closed conversations
              if (widget.isClosed && widget.conversationId != null)
                _ConvSummaryCard(
                  summary: _conversationSummary,
                  downloading: _downloadingReport,
                  onDownload: _downloadReport,
                ),

              // Input bar — hidden when conversation is closed
              if (widget.isClosed)
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottom),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.85),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: Colors.white38),
                      const SizedBox(width: 8),
                      Text(
                        'Cette consultation est terminée',
                        style: AppTextStyles.caption.copyWith(color: Colors.white38),
                      ),
                    ],
                  ),
                )
              else
                _ChatInputBar(
                  controller: _controller,
                  hasText: _hasText,
                  bottomPadding: bottom,
                  onSend: _sendMessage,
                  onAudioSend: _sendAudio,
                  onFileSend: _sendFile,
                  canAttach: !widget.isAi,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Messages skeleton — shown while first load is in progress
// ─────────────────────────────────────────────────────────────────────────────

class _MessagesSkeleton extends StatelessWidget {
  const _MessagesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 6,
      itemBuilder: (_, i) {
        final isOwn = i.isEven;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment:
                isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              ShimmerContainer(
                width: isOwn ? 180 + (i * 8.0) : 220 + (i * 6.0),
                height: 44,
                borderRadius: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBackground extends StatelessWidget {
  final Size size;
  const _ChatBackground({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.04,
          right: -size.width * 0.20,
          child: BlurOrb(
            width: size.width * 0.65,
            height: size.height * 0.28,
            color: const Color(0x1E6366F1),
          ),
        ),
        Positioned(
          bottom: size.height * 0.12,
          left: -size.width * 0.20,
          child: BlurOrb(
            width: size.width * 0.50,
            height: size.width * 0.50,
            color: const Color(0x128B5CF6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String name;
  final String initials;
  final Color color;
  final String subtitle;
  final bool online;
  final bool isAi;
  final int? conversationId;
  final String? avatarUrl;
  final bool isValidated;
  final VoidCallback? onConsultDoctor;

  const _ChatHeader({
    required this.name,
    required this.initials,
    required this.color,
    required this.subtitle,
    required this.online,
    required this.isAi,
    this.conversationId,
    this.isValidated = false,
    this.avatarUrl,
    this.onConsultDoctor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
          child: Row(
            children: [
              const NexoraBackButton(),
              const SizedBox(width: 10),

              // Avatar — real photo for doctors, gradient for AI
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (isAi || avatarUrl == null || avatarUrl!.isEmpty)
                          ? (isAi
                              ? AppGradients.primary
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [color.withAlpha(220), color.withAlpha(150)],
                                ))
                          : null,
                      color: (!isAi && avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? AppColors.surfaceElevated
                          : null,
                    ),
                    child: ClipOval(
                      child: isAi
                          ? Image.asset(
                              'assets/images/nexora1.png',
                              fit: BoxFit.cover,
                            )
                          : (avatarUrl != null && avatarUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: fixStorageUrl(avatarUrl!),
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: color.withAlpha(200),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: color.withAlpha(200),
                                    child: Center(
                                      child: Text(
                                        initials,
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                  if (online)
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: OnlinePresenceDot(size: 11),
                    ),
                ],
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isValidated && !isAi) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                              key: ValueKey(online),
                              online ? '$subtitle · En ligne' : '$subtitle · Hors ligne',
                              style: AppTextStyles.caption.copyWith(
                                color: online
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              _HeaderAction(
                icon: Icons.more_vert_rounded,
                onTap: () => _showOptions(context),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatOptionsSheet(
        isAi: isAi,
        conversationId: conversationId,
        expertName: name,
        onConsultDoctor: onConsultDoctor,
      ),
    );
  }
}

class _ChatOptionsSheet extends StatelessWidget {
  final bool isAi;
  final int? conversationId;
  final String expertName;
  final VoidCallback? onConsultDoctor;

  const _ChatOptionsSheet({
    required this.isAi,
    required this.conversationId,
    required this.expertName,
    this.onConsultDoctor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              isAi ? 'Assistant IA Nexora' : expertName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          if (!isAi) ...[
            _OptionTile(
              icon: Icons.info_outline_rounded,
              label: 'Informations sur la consultation',
              onTap: () => Navigator.pop(context),
            ),
            _OptionTile(
              icon: Icons.stop_circle_outlined,
              label: 'Terminer la consultation',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.pop(context);
                _confirmEndConsultation(context);
              },
            ),
            _OptionTile(
              icon: Icons.flag_outlined,
              label: 'Signaler un problème',
              color: const Color(0xFFEF4444),
              onTap: () async {
                Navigator.pop(context);
                final url = Uri.parse(
                    'mailto:support@nexora.ma?subject=Problème%20consultation%20$conversationId');
                if (await canLaunchUrl(url)) launchUrl(url);
              },
            ),
          ] else ...[
            _OptionTile(
              icon: Icons.help_outline_rounded,
              label: 'À propos de l\'IA Nexora',
              onTap: () => Navigator.pop(context),
            ),
            _OptionTile(
              icon: Icons.medical_services_outlined,
              label: 'Consulter un médecin',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                onConsultDoctor?.call();
              },
            ),
            _OptionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Effacer la conversation',
              color: const Color(0xFFEF4444),
              onTap: () => Navigator.pop(context),
            ),
          ],
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 12),
        ],
      ),
    );
  }

  void _confirmEndConsultation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Terminer la consultation ?',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text(
          'La consultation sera clôturée et un résumé sera généré.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Terminer',
                style: TextStyle(
                    color: Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withAlpha(20),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              color: color != null ? c : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date separator
// ─────────────────────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Aujourd\'hui',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.divider)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble dispatcher
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String expertInitials;
  final Color expertColor;
  final VoidCallback? onLongPress;
  final bool isAiMode;

  const _MessageBubble({
    required this.message,
    required this.expertInitials,
    required this.expertColor,
    this.onLongPress,
    this.isAiMode = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (message.isDeleted) {
      child = _DeletedPlaceholder(isUser: message.type == MessageType.user);
    } else {
      child = switch (message.type) {
        MessageType.system => _SystemMessage(text: message.text),
        MessageType.user   => message.contentType == MessageContentType.audio
            ? _AudioBubble(message: message, isUser: true)
            : message.contentType == MessageContentType.file
                ? _FileBubble(message: message, isUser: true)
                : _UserBubble(message: message),
        MessageType.ai     => message.contentType == MessageContentType.audio
            ? _AudioBubble(message: message, isUser: false)
            : message.contentType == MessageContentType.file
                ? _FileBubble(message: message, isUser: false)
                : _AiBubble(message: message, isAiMode: isAiMode),
        MessageType.expert => message.contentType == MessageContentType.audio
            ? _AudioBubble(
                message: message,
                isUser: false,
                expertInitials: expertInitials,
                expertColor: expertColor,
              )
            : message.contentType == MessageContentType.file
                ? _FileBubble(
                    message: message,
                    isUser: false,
                    initials: expertInitials,
                    color: expertColor,
                  )
                : _ExpertBubble(
                    message: message,
                    initials: expertInitials,
                    color: expertColor,
                  ),
      };
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: onLongPress != null
          ? GestureDetector(onLongPress: onLongPress, child: child)
          : child,
    );
  }
}

// ── Deleted placeholder ──────────────────────────────────────────────────────

class _DeletedPlaceholder extends StatelessWidget {
  final bool isUser;
  const _DeletedPlaceholder({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) const SizedBox(width: 38), // avatar space
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Ce message a été supprimé',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        if (isUser) const SizedBox(width: 0),
      ],
    );
  }
}

// ── Delete message sheet ─────────────────────────────────────────────────────

class _DeleteMessageSheet extends StatelessWidget {
  final VoidCallback onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;

  const _DeleteMessageSheet({
    required this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444).withAlpha(20),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Supprimer le message',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          if (onDeleteForEveryone != null)
            _SheetTile(
              icon: Icons.delete_sweep_rounded,
              label: 'Supprimer pour tout le monde',
              subtitle: 'Tous les participants ne verront plus ce message',
              color: const Color(0xFFEF4444),
              onTap: onDeleteForEveryone!,
            ),
          _SheetTile(
            icon: Icons.person_remove_outlined,
            label: 'Supprimer pour moi',
            subtitle: 'Visible uniquement pour vous',
            color: AppColors.textSecondary,
            onTap: onDeleteForMe,
          ),
          _SheetTile(
            icon: Icons.close_rounded,
            label: 'Annuler',
            color: AppColors.textTertiary,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withAlpha(20),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            )
          : null,
    );
  }
}

// ── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.73;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 60),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white, height: 1.5),
                  ),
                ),
                const SizedBox(height: 3),
                Text(message.timeFormatted, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── AI bubble ────────────────────────────────────────────────────────────────

class _AiBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isAiMode;
  const _AiBubble({required this.message, this.isAiMode = false});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.73;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI avatar
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/nexora1.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 8),

        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender label
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    'IA Nexora',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: AppColors.primary.withAlpha(40)),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ),
                if (message.metadata != null && message.metadata!['type'] == 'expert_recommendation') ...[
                  const SizedBox(height: 8),
                  _RichActionCard(expertData: message.metadata!['expert'] as Map<String, dynamic>, isAiMode: isAiMode),
                ] else if (message.metadata?['actions'] is List &&
                    (message.metadata!['actions'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _AiActionButtons(
                    actions: List<Map<String, dynamic>>.from(
                      (message.metadata!['actions'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
                    ),
                    specialty: message.metadata?['specialty_suggested'] as String?,
                    isAiMode: isAiMode,
                  ),
                ],
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(message.timeFormatted, style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 60),
      ],
    );
  }
}

// ── Expert bubble ─────────────────────────────────────────────────────────────

class _ExpertBubble extends StatelessWidget {
  final ChatMessage message;
  final String initials;
  final Color color;

  const _ExpertBubble({
    required this.message,
    required this.initials,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expert avatar
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withAlpha(220), color.withAlpha(150)],
            ),
          ),
          child: Center(
            child: Text(
              initials,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.73,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expert badge
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withAlpha(22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(60)),
                    ),
                    child: Text(
                      'Expert',
                      style: AppTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: color.withAlpha(40)),
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(message.timeFormatted, style: AppTextStyles.caption),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 60),
      ],
    );
  }
}

// ── Attachment option tile ────────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── File bubble ──────────────────────────────────────────────────────────────

class _FileBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  final String? initials;
  final Color? color;

  const _FileBubble({
    required this.message,
    required this.isUser,
    this.initials,
    this.color,
  });

  bool get _isImage => message.metadata?['is_image'] == true ||
      (message.mediaUrl != null &&
          RegExp(r'\.(jpe?g|png|gif|webp)$', caseSensitive: false)
              .hasMatch(message.mediaUrl!));

  @override
  Widget build(BuildContext context) {
    final uploadFailed = message.metadata?['upload_failed'] == true;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: color ?? AppColors.primary,
            child: Text(
              initials ?? 'IA',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.68,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primary.withAlpha(220)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: !isUser
                ? Border.all(color: AppColors.border.withAlpha(60))
                : null,
          ),
          child: uploadFailed
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Échec de l\'envoi',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                )
              : _isImage && message.mediaUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: message.mediaUrl!.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: message.mediaUrl!,
                              width: 220,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                width: 220,
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            )
                          : Image.file(
                              // Local file before upload completes
                              // ignore: avoid_dynamic_calls
                              dart_io.File(message.mediaUrl!),
                              width: 220,
                              fit: BoxFit.cover,
                            ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file_rounded,
                            size: 20,
                            color: isUser
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              message.text.isNotEmpty
                                  ? message.text
                                  : 'Fichier',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: isUser
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
        if (isUser) const SizedBox(width: 4),
      ],
    );
  }
}

// ── Audio bubble ─────────────────────────────────────────────────────────────

// Fixed waveform heights — looks like a natural voice recording
const _kWaveHeights = [
  0.4, 0.6, 0.9, 0.5, 0.7, 0.4, 0.8, 0.6, 0.3, 0.9,
  0.5, 0.7, 0.4, 0.6, 0.8, 0.5, 0.3, 0.7, 0.9, 0.4,
  0.6, 0.5, 0.8, 0.3, 0.6, 0.9, 0.4, 0.7, 0.5, 0.6,
];

class _AudioBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isUser;
  final String? expertInitials;
  final Color? expertColor;

  const _AudioBubble({
    required this.message,
    required this.isUser,
    this.expertInitials,
    this.expertColor,
  });

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    final metaDur = widget.message.metadata?['duration_seconds'] as int?;
    if (metaDur != null && metaDur > 0) {
      _duration = Duration(seconds: metaDur);
    }
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });

    // Probe duration without touching the main player
    if (_duration == Duration.zero) {
      _probeDuration();
    }
  }

  Future<void> _probeDuration() async {
    final url = widget.message.mediaUrl;
    if (url == null) return;
    // Use a throw-away player so the main _player stays clean for playback
    final probe = AudioPlayer();
    try {
      if (url.startsWith('http')) {
        await probe.setSource(UrlSource(url));
      } else {
        await probe.setSource(DeviceFileSource(url));
      }
      final dur = await probe.getDuration();
      if (dur != null && dur.inMilliseconds > 0 && mounted) {
        setState(() => _duration = dur);
      }
    } catch (_) {} finally {
      await probe.dispose();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final url = widget.message.mediaUrl;
    if (url == null) return;
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      if (url.startsWith('http')) {
        await _player.play(UrlSource(url));
      } else {
        await _player.play(DeviceFileSource(url));
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final timeLabel = isPlaying || _position.inSeconds > 0
        ? _fmt(_position)
        : _fmt(_duration);

    // ── Bubble content ───────────────────────────────────────────────────────
    final activeColor = widget.isUser ? Colors.white : AppColors.primary;
    final inactiveColor = widget.isUser
        ? Colors.white.withAlpha(50)
        : Colors.white.withAlpha(25);
    final timeColor = widget.isUser
        ? Colors.white.withAlpha(180)
        : AppColors.textSecondary;

    final bubbleContent = SizedBox(
      width: 210,
      child: Row(
        children: [
          // Play / pause button
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isUser
                    ? Colors.white.withAlpha(40)
                    : AppColors.primary.withAlpha(25),
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 22,
                color: activeColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Waveform + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform bars
                SizedBox(
                  height: 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_kWaveHeights.length, (i) {
                      final filled = (i / _kWaveHeights.length) <= progress;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 80),
                            height: 30 * _kWaveHeights[i],
                            decoration: BoxDecoration(
                              color: filled ? activeColor : inactiveColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final uploadFailed = widget.message.metadata?['upload_failed'] == true;

    // ── User bubble (right-aligned) ──────────────────────────────────────────
    if (widget.isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 60),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: bubbleContent,
              ),
              const SizedBox(height: 3),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (uploadFailed) ...[
                  const Icon(Icons.error_outline_rounded,
                      size: 12, color: Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  const Text('Échec envoi',
                      style: TextStyle(
                          fontSize: 10, color: Color(0xFFEF4444))),
                  const SizedBox(width: 6),
                ],
                Text(widget.message.timeFormatted,
                    style: AppTextStyles.caption),
              ]),
            ],
          ),
        ],
      );
    }

    // ── Received bubble (left-aligned, with avatar) ──────────────────────────
    final avatarGradient = widget.expertColor != null
        ? LinearGradient(colors: [
            widget.expertColor!.withAlpha(220),
            widget.expertColor!.withAlpha(150),
          ])
        : AppGradients.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: avatarGradient,
          ),
          child: Center(
            child: widget.expertInitials != null
                ? Text(
                    widget.expertInitials!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  )
                : ClipOval(
                    child: Image.asset(
                      'assets/images/nexora1.png',
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: bubbleContent,
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(widget.message.timeFormatted,
                  style: AppTextStyles.caption),
            ),
          ],
        ),
        const SizedBox(width: 60),
      ],
    );
  }
}

// ── Upgrade Nudge Card ───────────────────────────────────────────────────────
// Shown inline inside the AI message when a free user asks for a doctor.

class _UpgradeNudgeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeNudgeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(18),
            const Color(0xFF8B5CF6).withAlpha(18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nexora Pro',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      )),
                  Text('249 MAD / mois',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Consultez un médecin en quelques secondes.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          // Perks
          _Perk('3 consultations médecin / mois'),
          _Perk('Réponses IA illimitées'),
          _Perk('Ordonnances & certificats'),
          const SizedBox(height: 14),
          // CTA button
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: AppGradients.button,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Passer au Pro',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  final String text;
  const _Perk(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── AI Action Buttons ────────────────────────────────────────────────────────
// Renders the actions[] array from AI message metadata.
// Mirrors the web UI: "Voir les médecins disponibles" / "Non, continuer avec l'IA"

class _AiActionButtons extends ConsumerWidget {
  final List<Map<String, dynamic>> actions;
  final String? specialty;
  final bool isAiMode;

  const _AiActionButtons({required this.actions, this.specialty, this.isAiMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFindExpert = actions.any((a) => a['type'] == 'find_expert');
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isFree = user == null || user.plan == 'free' || !user.planIsActive;

    // Free user + doctor suggestion → show inline upgrade card
    if (hasFindExpert && isFree) {
      return _UpgradeNudgeCard(
        onTap: () => context.push(AppRoutes.upgrade, extra: {'reason': 'no_plan'}),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        final type = action['type'] as String? ?? '';
        final label = action['type'] == 'find_expert'
            ? 'Voir les médecins'
            : action['type'] == 'continue_ai'
                ? 'Continuer avec l\'IA'
                : action['label'] as String? ?? type;

        final isPrimary = type == 'find_expert';
        final isDanger = type == 'call_samu';

        return GestureDetector(
          onTap: () => _handleAction(context, ref, action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isPrimary ? AppGradients.button : null,
              color: isPrimary
                  ? null
                  : isDanger
                      ? const Color(0xFFEF4444).withAlpha(20)
                      : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPrimary
                    ? Colors.transparent
                    : isDanger
                        ? const Color(0xFFEF4444).withAlpha(80)
                        : AppColors.primary.withAlpha(60),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPrimary
                      ? Icons.person_search_rounded
                      : isDanger
                          ? Icons.phone_rounded
                          : Icons.smart_toy_rounded,
                  size: 13,
                  color: isPrimary
                      ? Colors.white
                      : isDanger
                          ? const Color(0xFFEF4444)
                          : AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isPrimary
                        ? Colors.white
                        : isDanger
                            ? const Color(0xFFEF4444)
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, Map<String, dynamic> action) {
    final type = action['type'] as String? ?? '';
    final actionSpecialty = action['specialty'] as String? ?? specialty ?? 'medecine-generale';

    switch (type) {
      case 'find_expert':
        // Plan barrier — mirror the same check as _handleConsultDoctor in ChatScreen
        final user = ref.read(currentUserProvider).valueOrNull;
        if (user == null || user.plan == 'free' || !user.planIsActive) {
          context.push(AppRoutes.upgrade, extra: {'reason': 'no_plan'});
          return;
        }
        if (user.consultationCredits <= 0) {
          context.push(AppRoutes.upgrade, extra: {'reason': 'no_credits'});
          return;
        }
        _showDoctorPanel(context, ref, actionSpecialty);
        break;
      case 'call_samu':
        launchUrl(Uri.parse('tel:15'));
        break;
      case 'continue_ai':
        // Nothing to do — user just continues typing
        break;
    }
  }

  void _showDoctorPanel(BuildContext context, WidgetRef ref, String specialty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoctorPickerSheet(specialty: specialty, isAiMode: isAiMode),
    );
  }
}

// ── Doctor Picker Sheet ───────────────────────────────────────────────────────

class _DoctorPickerSheet extends ConsumerStatefulWidget {
  final String specialty;
  final bool isAiMode;
  const _DoctorPickerSheet({required this.specialty, this.isAiMode = false});

  @override
  ConsumerState<_DoctorPickerSheet> createState() => _DoctorPickerSheetState();
}

class _DoctorPickerSheetState extends ConsumerState<_DoctorPickerSheet> {
  List<Map<String, dynamic>> _doctors = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/experts', queryParameters: {
        'specialty': widget.specialty,
        'available': 1,
        'per_page': 5,
        'sort': 'rating',
      });
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _doctors = List<Map<String, dynamic>>.from(
          (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Impossible de charger les médecins.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.local_hospital_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text('Médecins disponibles',
                    style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            )
          else if (_doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text('Aucun médecin disponible pour le moment.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doctors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final doc = _doctors[i];
                final user = doc['user'] as Map<String, dynamic>? ?? {};
                final category = doc['category'] as Map<String, dynamic>? ?? {};
                final name = user['name'] as String? ?? 'Médecin';
                final categoryName = category['name'] as String? ?? widget.specialty;
                final rating = (doc['rating_avg'] as num?)?.toDouble() ?? 0.0;
                final avatarUrl = user['avatar_url'] as String?;
                final initials = name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(initials, style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryLight))
                        : null,
                  ),
                  title: Text(name,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      Text(categoryName, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                      const SizedBox(width: 8),
                      Icon(Icons.star_rounded, size: 12, color: const Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  trailing: _EscalateButton(expertId: doc['id'] as int?, isAiMode: widget.isAiMode),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Escalate button inside the sheet ─────────────────────────────────────────

class _EscalateButton extends ConsumerWidget {
  final int? expertId;
  final bool isAiMode;
  const _EscalateButton({this.expertId, this.isAiMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEscalating = isAiMode
        ? ref.watch(aiChatProvider).isEscalating
        : ref.watch(chatProvider).isEscalating;

    return GestureDetector(
      onTap: isEscalating ? null : () {
        Navigator.of(context).pop();
        if (isAiMode) {
          ref.read(aiChatProvider.notifier).escalateToDoctor(expertId: expertId);
        } else {
          ref.read(chatProvider.notifier).escalateToDoctor(expertId: expertId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isEscalating ? null : AppGradients.button,
          color: isEscalating ? AppColors.border : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isEscalating
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text('Consulter',
                style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Rich Action Card ────────────────────────────────────────────────────────

class _RichActionCard extends ConsumerWidget {
  final Map<String, dynamic> expertData;
  final bool isAiMode;

  const _RichActionCard({required this.expertData, this.isAiMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = expertData['name'] as String;
    final specialty = expertData['specialty'] as String;
    final rating = (expertData['rating'] as num?)?.toDouble() ?? 0.0;
    final expertId = expertData['id'] as int?;
    final initials = name.split(RegExp(r'\s+')).last[0].toUpperCase();
    final isEscalating = isAiMode
        ? ref.watch(aiChatProvider).isEscalating
        : ref.watch(chatProvider).isEscalating;

    return Container(
      width: 240, // Fixed width for the card inside the chat
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(30),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 4),
              Text(
                rating.toString(),
                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isEscalating ? null : () {
                  if (isAiMode) {
                    ref.read(aiChatProvider.notifier).escalateToDoctor(expertId: expertId);
                  } else {
                    ref.read(chatProvider.notifier).escalateToDoctor(expertId: expertId);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isEscalating ? null : AppGradients.button,
                    color: isEscalating ? AppColors.border : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isEscalating
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : Text(
                          'Connecter',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── System message ────────────────────────────────────────────────────────────

class _SystemMessage extends StatelessWidget {
  final String text;
  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 12,
              color: AppColors.primaryLight,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Empty State — shown when the AI conversation has no messages yet
// ─────────────────────────────────────────────────────────────────────────────

class _AiEmptyState extends StatelessWidget {
  final void Function(String text) onSuggestion;

  const _AiEmptyState({required this.onSuggestion});

  static const _suggestions = [
    ('🤒', "J'ai de la fièvre depuis 2 jours"),
    ('💊', 'Quels médicaments pour un mal de tête ?'),
    ('🩺', 'Quand dois-je consulter un médecin ?'),
    ('😴', "J'ai des troubles du sommeil, que faire ?"),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nexora logo / avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
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
            const SizedBox(height: 16),
            Text(
              'Assistant Médical Nexora',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Posez votre question médicale ou choisissez une suggestion ci-dessous.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: _suggestions.map((s) {
                final (emoji, label) = s;
                return GestureDetector(
                  onTap: () => onSuggestion(label),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            label,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Disclaimer
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Text(
                'ℹ️  Les informations ne remplacent pas une consultation médicale. '
                'Urgence : appelez le 141 (SAMU).',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryLight,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing indicator
// ─────────────────────────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  final bool isAi;
  final String initials;
  final Color color;

  const _TypingBubble({
    required this.isAi,
    required this.initials,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isAi
                ? AppGradients.primary
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withAlpha(220), color.withAlpha(150)],
                  ),
          ),
          child: isAi
              ? ClipOval(
                  child: Image.asset(
                    'assets/images/nexora1.png',
                    fit: BoxFit.cover,
                  ),
                )
              : Center(child: Text(
                    initials,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),

        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(delay: Duration.zero),
              const SizedBox(width: 4),
              _TypingDot(delay: const Duration(milliseconds: 180)),
              const SizedBox(width: 4),
              _TypingDot(delay: const Duration(milliseconds: 360)),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _TypingDot extends StatefulWidget {
  final Duration delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, -5 * _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat input bar (with hold-to-record audio)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool hasText;
  final double bottomPadding;
  final VoidCallback onSend;
  final Future<void> Function(String path, int durationSeconds) onAudioSend;
  final Future<void> Function(String path, String fileName, String mimeType) onFileSend;
  final bool canAttach;

  const _ChatInputBar({
    required this.controller,
    required this.hasText,
    required this.bottomPadding,
    required this.onSend,
    required this.onAudioSend,
    required this.onFileSend,
    this.canAttach = false,
  });

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  final _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _recorderReady = false;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('[Recorder] Microphone permission denied');
        return;
      }
      await _recorder.openRecorder();
      if (mounted) setState(() => _recorderReady = true);
    } catch (e) {
      debugPrint('[Recorder] Failed to open: $e');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    if (!_recorderReady) {
      // Permission was denied — prompt user to re-enable
      final status = await Permission.microphone.status;
      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autorisez le micro dans les paramètres de l\'application.'),
              duration: Duration(seconds: 3),
            ),
          );
          await openAppSettings();
        }
      } else {
        await _initRecorder();
        if (!_recorderReady) return;
      }
      if (!_recorderReady) return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacMP4,
      sampleRate: 44100,   // CD quality sample rate
      bitRate: 128000,     // 128 kbps — clear voice
      numChannels: 1,      // mono is fine for voice messages
    );
    if (mounted) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    final recorded = _recordingSeconds; // capture before reset
    final path = await _recorder.stopRecorder();
    if (mounted) setState(() => _isRecording = false);
    if (path != null) await widget.onAudioSend(path, recorded);
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null || !mounted) return;
      final mimeType = picked.mimeType ?? 'image/jpeg';
      await widget.onFileSend(picked.path, picked.name, mimeType);
    } catch (e) {
      debugPrint('[File] Image pick failed: $e');
    }
  }

  void _showAttachmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111631),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Joindre un fichier',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _AttachOption(
                  icon: Icons.image_rounded,
                  label: 'Photo',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                const SizedBox(width: 12),
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Caméra',
                  color: const Color(0xFF8B5CF6),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                        maxWidth: 1280,
                      );
                      if (picked == null) return;
                      await widget.onFileSend(
                          picked.path, picked.name, picked.mimeType ?? 'image/jpeg');
                    } catch (e) {
                      debugPrint('[File] Camera pick failed: $e');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    await _recorder.stopRecorder(); // discard — don't send
    if (mounted) setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + widget.bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border.withAlpha(80)),
        ),
      ),
      child: _isRecording ? _buildRecordingRow() : _buildNormalRow(),
    );
  }

  Widget _buildRecordingRow() {
    final mins = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordingSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        // Recording indicator — inside same unified container
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.red.withAlpha(80)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _PulsatingDot(),
                const SizedBox(width: 10),
                Text(
                  '$mins:$secs',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Enregistrement…',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                // Cancel
                GestureDetector(
                  onTap: _cancelRecording,
                  child: Icon(Icons.delete_outline_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red,
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildNormalRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Single styled TextField — no wrapper container ──────────────────
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: null,
            textInputAction: TextInputAction.newline,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: 'Écrivez un message…',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: widget.canAttach
                  ? GestureDetector(
                      onTap: () => _showAttachmentSheet(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.add_rounded,
                            size: 22, color: AppColors.textSecondary),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ── Send / mic circle (outside, right) ─────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: widget.hasText
              ? _SendButton(key: const ValueKey('send'), onTap: widget.onSend)
              : GestureDetector(
                  key: const ValueKey('mic-fab'),
                  onLongPress: _startRecording,
                  onTap: _startRecording,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _recorderReady
                          ? AppGradients.primary
                          : LinearGradient(colors: [
                              AppColors.border,
                              AppColors.border,
                            ]),
                    ),
                    child: const Icon(Icons.mic_rounded,
                        size: 22, color: Colors.white),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Pulsating red dot ─────────────────────────────────────────────────────────

class _PulsatingDot extends StatefulWidget {
  @override
  State<_PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<_PulsatingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withAlpha((80 + (_ctrl.value * 175).round())),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Consultation summary card
// ─────────────────────────────────────────────────────────────────────────────

class _ConvSummaryCard extends StatelessWidget {
  final String? summary;
  final bool downloading;
  final VoidCallback onDownload;

  const _ConvSummaryCard({
    required this.summary,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6366F1);
    const purpleLight = Color(0xFFC4B5FD);
    const surfaceBg = Color(0xFF0D1020);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x144F46E5), Color(0xFF0D1020)],
        ),
        border: Border.all(color: purple.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: purple.withValues(alpha: 0.35)),
                  ),
                  child: const Icon(Icons.summarize_outlined, size: 14, color: purpleLight),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'RÉSUMÉ DE CONSULTATION',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: purpleLight,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                // Download button
                GestureDetector(
                  onTap: downloading ? null : onDownload,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: downloading
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                      color: downloading ? Colors.white10 : null,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: downloading
                            ? Colors.white12
                            : purple.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (downloading)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: purpleLight,
                            ),
                          )
                        else
                          const Icon(Icons.picture_as_pdf_outlined,
                              size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          downloading ? 'Chargement…' : 'Rapport PDF',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: downloading ? purpleLight : Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: Color(0x1F6366F1), height: 1),
            const SizedBox(height: 12),

            // Summary text
            summary != null && summary!.isNotEmpty
                ? Text(
                    summary!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFCBD5E1),
                      height: 1.65,
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Résumé en cours de génération…',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                const Icon(Icons.smart_toy_outlined,
                    size: 11, color: Color(0xFF6366F1)),
                const SizedBox(width: 5),
                Text(
                  'Généré automatiquement par l\'IA après clôture',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
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
// Rating bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RatingBottomSheet extends StatefulWidget {
  final int conversationId;
  final String expertName;
  final void Function(int rating, String? comment) onSubmit;

  const _RatingBottomSheet({
    required this.conversationId,
    required this.expertName,
    required this.onSubmit,
  });

  @override
  State<_RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<_RatingBottomSheet> {
  int _selected = 0;
  int _hovered = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == 0) return;
    setState(() => _submitting = true);
    try {
      widget.onSubmit(_selected, _commentController.text.trim().isEmpty ? null : _commentController.text.trim());
      setState(() { _submitting = false; _submitted = true; });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111631),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (_submitted) ...[
            const SizedBox(height: 8),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withAlpha(20),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF34D399), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Merci pour votre évaluation !',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Text(
              'Évaluez votre consultation',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'avec ${widget.expertName}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final n = i + 1;
                final active = n <= (_hovered > 0 ? _hovered : _selected);
                return GestureDetector(
                  onTap: () => setState(() => _selected = n),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hovered = n),
                    onExit: (_) => setState(() => _hovered = 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: active ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          active ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 40,
                          color: active ? const Color(0xFFFCD34D) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Comment field (visible after picking stars)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _selected > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          maxLength: 2000,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Commentaire facultatif…',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            counterStyle: TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Submit
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: (_selected == 0 || _submitting) ? null : _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: _selected > 0
                        ? AppGradients.button
                        : LinearGradient(colors: [AppColors.border, AppColors.border]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Envoyer',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Skip
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text(
                'Plus tard',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.button,
        ),
        child: const Icon(
          Icons.send_rounded,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }
}
