import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const ChatScreen({
    super.key,
    required this.name,
    required this.initials,
    required this.color,
    required this.subtitle,
    required this.online,
    required this.isAi,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).initialize(isAi: widget.isAi);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
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
    ref.read(chatProvider.notifier).sendMessage(_controller.text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
              // Header
              _ChatHeader(
                name: widget.name,
                initials: widget.initials,
                color: widget.color,
                subtitle: widget.subtitle,
                online: widget.online,
                isAi: widget.isAi,
              ),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: chatState.messages.length +
                      (chatState.isTyping ? 2 : 1), // +1 date, +1 typing
                  itemBuilder: (context, i) {
                    // Date separator first
                    if (i == 0) return const _DateSeparator();

                    final msgIndex = i - 1;

                    // Typing indicator last
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

  const _ChatHeader({
    required this.name,
    required this.initials,
    required this.color,
    required this.subtitle,
    required this.online,
    required this.isAi,
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
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
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
                    Row(
                      children: [
                        if (online)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                          ),
                        Text(
                          online ? subtitle : '$subtitle · Hors ligne',
                          style: AppTextStyles.caption.copyWith(
                            color: online
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              _HeaderAction(
                icon: Icons.videocam_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 6),
              _HeaderAction(
                icon: Icons.more_vert_rounded,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
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

  const _MessageBubble({
    required this.message,
    required this.expertInitials,
    required this.expertColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: switch (message.type) {
        MessageType.user => _UserBubble(message: message),
        MessageType.ai => _AiBubble(message: message),
        MessageType.expert => _ExpertBubble(
            message: message,
            initials: expertInitials,
            color: expertColor,
          ),
        MessageType.system => _SystemMessage(text: message.text),
      },
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
// Chat input bar
// ─────────────────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasText;
  final double bottomPadding;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.hasText,
    required this.bottomPadding,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment
          _InputIconButton(
            icon: Icons.attach_file_rounded,
            onTap: () {},
          ),

          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: controller,
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

          // Mic / Send (animated switch)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: hasText
                ? _SendButton(key: const ValueKey('send'), onTap: onSend)
                : _InputIconButton(
                    key: const ValueKey('mic'),
                    icon: Icons.mic_rounded,
                    onTap: () {},
                    isPrimary: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _InputIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
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
          color: isPrimary ? AppColors.primary : AppColors.surfaceElevated,
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isPrimary ? Colors.white : AppColors.textSecondary,
        ),
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
