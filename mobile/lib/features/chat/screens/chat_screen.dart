import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';
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

  const ChatScreen({
    super.key,
    required this.name,
    required this.initials,
    required this.color,
    required this.subtitle,
    required this.online,
    required this.isAi,
    this.conversationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  Timer? _typingTimer;

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
      ref.read(chatProvider.notifier).initialize(
        isAi: widget.isAi,
        conversationId: widget.conversationId,
        otherOnline: widget.online,
      );
      _scrollToBottom();
    });
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
    ref.read(chatProvider.notifier).sendTyping(isTyping: false);
    ref.read(chatProvider.notifier).sendMessage(_controller.text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendAudio(String path, int durationSeconds) async {
    await ref.read(chatProvider.notifier).sendAudioMessage(path, durationSeconds: durationSeconds);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _showDeleteSheet(BuildContext context, ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteMessageSheet(
        onDeleteForMe: () {
          Navigator.pop(context);
          ref.read(chatProvider.notifier).deleteForMe(message.id);
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
    final chatState = ref.watch(chatProvider);

    ref.listen<ChatState>(chatProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });

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
              ),

              // Messages
              Expanded(
                child: chatState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
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
                            ? const Center(
                                child: Text('Aucun message'),
                              )
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
                                    onLongPress: msg.type == MessageType.user && !msg.isDeleted
                                        ? () => _showDeleteSheet(context, msg)
                                        : null,
                                  );
                                },
                              ),
              ),

              // Input bar
              _ChatInputBar(
                controller: _controller,
                hasText: _hasText,
                bottomPadding: bottom,
                onSend: _sendMessage,
                onAudioSend: _sendAudio,
              ),
            ],
          ),
        ],
      ),
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

  const _ChatHeader({
    required this.name,
    required this.initials,
    required this.color,
    required this.subtitle,
    required this.online,
    required this.isAi,
    this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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

              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isAi
                          ? AppGradients.primary
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color.withAlpha(220),
                                color.withAlpha(150),
                              ],
                            ),
                    ),
                    child: Center(
                      child: isAi
                          ? const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : Text(
                              initials,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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
                    Text(
                      name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      child: online
                          ? Row(
                              key: const ValueKey('status-online'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OnlinePresenceDot(size: 6, showBorder: false),
                                const SizedBox(width: 5),
                                Text(
                                  subtitle,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Text(
                              key: const ValueKey('status-offline'),
                              '$subtitle · Hors ligne',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
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
      ),
    );
  }
}

class _ChatOptionsSheet extends StatelessWidget {
  final bool isAi;
  final int? conversationId;
  final String expertName;

  const _ChatOptionsSheet({
    required this.isAi,
    required this.conversationId,
    required this.expertName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111631),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              isAi ? 'Assistant IA Nexora' : expertName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const Divider(color: Color(0xFF1E2A42), height: 1),
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
        backgroundColor: const Color(0xFF111631),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terminer la consultation ?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'La consultation sera clôturée et un résumé sera généré.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
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
              color: color != null ? c : Colors.white,
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

  const _MessageBubble({
    required this.message,
    required this.expertInitials,
    required this.expertColor,
    this.onLongPress,
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
            : _UserBubble(message: message),
        MessageType.ai     => message.contentType == MessageContentType.audio
            ? _AudioBubble(message: message, isUser: false)
            : _AiBubble(message: message),
        MessageType.expert => message.contentType == MessageContentType.audio
            ? _AudioBubble(
                message: message,
                isUser: false,
                expertInitials: expertInitials,
                expertColor: expertColor,
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
      decoration: const BoxDecoration(
        color: Color(0xFF111631),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              color: Colors.white.withAlpha(30),
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
                const Text(
                  'Supprimer le message',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E2A42), height: 1),
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
          color: Colors.white,
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
                  decoration: const BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.only(
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
  const _AiBubble({required this.message});

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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 15,
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
                  _RichActionCard(expertData: message.metadata!['expert'] as Map<String, dynamic>),
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
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
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
                decoration: const BoxDecoration(
                  gradient: AppGradients.button,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: bubbleContent,
              ),
              const SizedBox(height: 3),
              Text(widget.message.timeFormatted, style: AppTextStyles.caption),
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
                : const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 15),
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

// ── Rich Action Card ────────────────────────────────────────────────────────

class _RichActionCard extends StatelessWidget {
  final Map<String, dynamic> expertData;

  const _RichActionCard({required this.expertData});

  @override
  Widget build(BuildContext context) {
    final name = expertData['name'] as String;
    final specialty = expertData['specialty'] as String;
    final rating = expertData['rating'] as double;
    final initials = name.split(RegExp(r'\s+')).last[0].toUpperCase();

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
                onTap: () {}, // Action to connect with expert
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
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
            const Icon(
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
          child: Center(
            child: isAi
                ? const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 15)
                : Text(
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
          decoration: const BoxDecoration(
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

  const _ChatInputBar({
    required this.controller,
    required this.hasText,
    required this.bottomPadding,
    required this.onSend,
    required this.onAudioSend,
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
      // File sending wired in S20 (S3 upload pipeline)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Envoi de fichiers bientôt disponible'),
          backgroundColor: const Color(0xFF1A1F35),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {}
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
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + widget.bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: _isRecording ? _buildRecordingRow() : _buildNormalRow(),
    );
  }

  Widget _buildRecordingRow() {
    final mins = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_recordingSeconds % 60).toString().padLeft(2, '0');

    return Row(
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Enregistrement...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
        // Cancel — discard recording
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        // Send — stop + send
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 44,
            height: 44,
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
        _InputIconButton(icon: Icons.attach_file_rounded, onTap: _pickImage),

        const SizedBox(width: 10),

        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Écrivez un message...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: widget.hasText
              ? _SendButton(key: const ValueKey('send'), onTap: widget.onSend)
              : GestureDetector(
                  key: const ValueKey('mic'),
                  onTap: _startRecording,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _recorderReady ? AppColors.primary : AppColors.border,
                    ),
                    child: const Icon(Icons.mic_rounded,
                        size: 20, color: Colors.white),
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

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _InputIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
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
        decoration: const BoxDecoration(
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
