import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

const _kSupportTicketsPref = 'profile.support.tickets';
const _supportTopics = [
  'Compte',
  'Consultation',
  'Paiement',
  'Sécurité',
  'Technique',
];
const _supportPriorities = ['Normal', 'Urgent'];

// ─────────────────────────────────────────────────────────────────────────────
// HelpScreen
// ─────────────────────────────────────────────────────────────────────────────

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final filtered = _allFaqs
        .where(
          (f) =>
              _query.isEmpty ||
              f.question.toLowerCase().contains(_query.toLowerCase()) ||
              f.answer.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    final grouped = <String, List<_FaqItem>>{};
    for (final f in filtered) {
      grouped.putIfAbsent(f.category, () => []).add(f);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -size.height * 0.04,
            right: -size.width * 0.22,
            child: BlurOrb(
              width: size.width * 0.65,
              height: size.height * 0.28,
              color: const Color(0x1A6366F1),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.03,
            left: -size.width * 0.18,
            child: BlurOrb(
              width: size.width * 0.50,
              height: size.height * 0.16,
              color: const Color(0x128B5CF6),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
                  child: Row(
                    children: [
                      const NexoraBackButton(),
                      const SizedBox(width: 10),
                      Text(
                        'Aide & Support',
                        style: AppTextStyles.headlineSmall,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchBar(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

                const SizedBox(height: 8),

                // FAQ list
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptySearch(query: _query)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                          children: [
                            for (final entry in grouped.entries) ...[
                              _CategoryHeader(
                                label: entry.key,
                              ).animate().fadeIn(delay: 100.ms),
                              const SizedBox(height: 8),
                              _FaqGroup(items: entry.value)
                                  .animate()
                                  .fadeIn(delay: 140.ms, duration: 400.ms)
                                  .slideY(
                                    begin: 0.05,
                                    end: 0,
                                    curve: Curves.easeOut,
                                  ),
                              const SizedBox(height: 20),
                            ],
                            _ContactCard()
                                .animate()
                                .fadeIn(delay: 220.ms, duration: 400.ms)
                                .slideY(
                                  begin: 0.05,
                                  end: 0,
                                  curve: Curves.easeOut,
                                ),
                            const SizedBox(height: 12),
                            _UrgencyBanner().animate().fadeIn(
                              delay: 280.ms,
                              duration: 400.ms,
                            ),
                          ],
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
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Rechercher dans l\'aide…',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category header
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.overline.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.8,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ group (expandable items inside a card)
// ─────────────────────────────────────────────────────────────────────────────

class _FaqGroup extends StatelessWidget {
  final List<_FaqItem> items;
  const _FaqGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) Container(height: 1, color: AppColors.divider),
            _FaqTile(item: items[i], isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  final bool isLast;
  const _FaqTile({required this.item, required this.isLast});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _anim;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _rotate = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              _expanded ? 8 : (widget.isLast ? 16 : 16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: AppTextStyles.titleSmall,
                  ),
                ),
                const SizedBox(width: 12),
                RotationTransition(
                  turns: _rotate,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, widget.isLast ? 16 : 16),
            child: Text(
              widget.item.answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact card
// ─────────────────────────────────────────────────────────────────────────────

class _ContactCard extends StatefulWidget {
  const _ContactCard();

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _topic = _supportTopics.first;
  String _priority = _supportPriorities.first;
  List<_SupportTicket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final rawTickets = prefs.getStringList(_kSupportTicketsPref) ?? const [];
    final tickets = <_SupportTicket>[];

    for (final raw in rawTickets) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          tickets.add(_SupportTicket.fromJson(decoded));
        }
      } catch (_) {
        // Ignore malformed local drafts.
      }
    }

    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (!mounted) return;
    setState(() => _tickets = tickets.take(3).toList());
  }

  Future<void> _persistTickets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kSupportTicketsPref,
      _tickets.map((ticket) => jsonEncode(ticket.toJson())).toList(),
    );
  }

  Future<void> _submitTicket() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.length < 3 || message.length < 12) {
      _showSnack('Ajoutez un sujet et un message plus précis.');
      return;
    }

    final ticket = _SupportTicket(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topic: _topic,
      priority: _priority,
      subject: subject,
      message: message,
      status: _priority == 'Urgent' ? 'Prioritaire' : 'Ouvert',
      createdAt: DateTime.now(),
    );

    setState(() {
      _tickets = [ticket, ..._tickets].take(3).toList();
      _subjectController.clear();
      _messageController.clear();
      _topic = _supportTopics.first;
      _priority = _supportPriorities.first;
    });
    await _persistTickets();
    HapticFeedback.lightImpact();
    _showSnack('Demande support enregistrée localement.');
  }

  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@nexora.ma'));
    HapticFeedback.selectionClick();
    _showSnack('Email support copié.');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 18,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Text('Contacter le support', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'support@nexora.ma',
            onTap: _copyEmail,
            actionIcon: Icons.copy_rounded,
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.access_time_rounded,
            label: 'Disponibilité',
            value: 'Lun-Ven, 9h-18h (GMT+1)',
          ),
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.timer_outlined,
            label: 'Délai de réponse',
            value: 'Sous 24 heures ouvrables',
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 18),
          Text('Nouvelle demande', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          _SupportSelect(
            label: 'Sujet',
            icon: Icons.category_outlined,
            value: _topic,
            options: _supportTopics,
            onChanged: (value) => setState(() => _topic = value),
          ),
          const SizedBox(height: 10),
          _SupportSelect(
            label: 'Priorité',
            icon: Icons.flag_outlined,
            value: _priority,
            options: _supportPriorities,
            onChanged: (value) => setState(() => _priority = value),
          ),
          const SizedBox(height: 10),
          _SupportTextField(
            controller: _subjectController,
            label: 'Sujet',
            hint: 'Ex: Problème de paiement',
            icon: Icons.short_text_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          _SupportTextField(
            controller: _messageController,
            label: 'Message',
            hint: 'Décrivez ce qui bloque...',
            icon: Icons.notes_rounded,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _submitTicket,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withAlpha(70)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Créer la demande',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_tickets.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 16),
            Text('Dernières demandes', style: AppTextStyles.titleSmall),
            const SizedBox(height: 10),
            for (final ticket in _tickets) ...[
              _TicketTile(ticket: ticket),
              if (ticket != _tickets.last) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final IconData? actionIcon;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionIcon != null) ...[
            const SizedBox(width: 8),
            Icon(actionIcon, size: 14, color: AppColors.primaryLight),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Urgency banner
// ─────────────────────────────────────────────────────────────────────────────

class _SupportSelect extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SupportSelect({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(
            '$label :',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                iconEnabledColor: AppColors.textTertiary,
                style: AppTextStyles.titleSmall,
                items: [
                  for (final option in options)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (next) {
                  if (next != null) onChanged(next);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputAction textInputAction;

  const _SupportTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: maxLines,
      textInputAction: textInputAction,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        fillColor: AppColors.surfaceElevated,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  final _SupportTicket ticket;

  const _TicketTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final urgent = ticket.priority == 'Urgent';
    final color = urgent ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withAlpha(150),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: ticket.status, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket.topic} • ${_formatTicketDate(ticket.createdAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: color)),
    );
  }
}

class _UrgencyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x15EF4444),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40EF4444)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.emergency_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urgence médicale ?',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'En cas d\'urgence, appelez le 141 (SAMU Maroc) ou rendez-vous aux urgences. Nexora ne remplace pas les secours d\'urgence.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
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
// Empty search state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.textTertiary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat pour "$query"',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'autres mots-clés ou contactez le support.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ data
// ─────────────────────────────────────────────────────────────────────────────

class _FaqItem {
  final String category;
  final String question;
  final String answer;
  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class _SupportTicket {
  final String id;
  final String topic;
  final String priority;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  const _SupportTicket({
    required this.id,
    required this.topic,
    required this.priority,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory _SupportTicket.fromJson(Map<String, dynamic> json) {
    return _SupportTicket(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? 'Compte',
      priority: json['priority'] as String? ?? 'Normal',
      subject: json['subject'] as String? ?? 'Demande support',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'Ouvert',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'topic': topic,
    'priority': priority,
    'subject': subject,
    'message': message,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}

String _formatTicketDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

const _allFaqs = [
  // Utilisation de la plateforme
  _FaqItem(
    category: 'Utilisation de la plateforme',
    question: 'Comment consulter un médecin sur Nexora ?',
    answer:
        'Commencez une conversation depuis l\'écran d\'accueil. Notre IA analyse votre question, détermine la spécialité médicale adaptée et vous répond immédiatement. Si nécessaire, elle escalade automatiquement votre cas vers le médecin disponible le plus adapté.',
  ),
  _FaqItem(
    category: 'Utilisation de la plateforme',
    question: 'Qu\'est-ce que l\'IA fait exactement ?',
    answer:
        'L\'IA analyse vos symptômes, classifie la spécialité médicale, évalue l\'urgence et répond aux questions d\'ordre général. Elle ne pose pas de diagnostic et ne prescrit aucun médicament. En cas de doute ou d\'urgence, elle vous met en relation avec un médecin humain.',
  ),
  _FaqItem(
    category: 'Utilisation de la plateforme',
    question: 'Quand suis-je mis en relation avec un médecin humain ?',
    answer:
        'Trois situations déclenchent une escalade : la confiance de l\'IA est inférieure à 75 %, l\'urgence est élevée (symptômes graves), ou vous demandez explicitement à parler à un médecin. La mise en relation est automatique et rapide.',
  ),
  _FaqItem(
    category: 'Utilisation de la plateforme',
    question: 'Puis-je envoyer des messages vocaux ?',
    answer:
        'Oui. Maintenez le bouton micro dans la fenêtre de chat pour enregistrer un message audio. Il est automatiquement transcrit par l\'IA avant analyse, et le médecin peut vous répondre également en audio.',
  ),

  // Compte & Sécurité
  _FaqItem(
    category: 'Compte & Sécurité',
    question: 'Comment modifier mes informations personnelles ?',
    answer:
        'Dans votre profil, appuyez sur "Modifier" en haut à droite. Vous pouvez changer votre nom, numéro de téléphone et photo de profil. L\'email n\'est pas modifiable car il sert d\'identifiant unique.',
  ),
  _FaqItem(
    category: 'Compte & Sécurité',
    question: 'Comment activer l\'authentification à deux facteurs ?',
    answer:
        'Allez dans Profil → Confidentialité & sécurité → Authentification à deux facteurs → Activer. Scannez le QR code avec Google Authenticator ou Authy, puis entrez le code à 6 chiffres pour confirmer.',
  ),
  _FaqItem(
    category: 'Compte & Sécurité',
    question: 'J\'ai oublié mon mot de passe, que faire ?',
    answer:
        'Sur l\'écran de connexion, appuyez sur "Mot de passe oublié". Entrez votre email et vous recevrez un code OTP à 6 chiffres valable 10 minutes pour réinitialiser votre mot de passe.',
  ),
  _FaqItem(
    category: 'Compte & Sécurité',
    question: 'Mes données médicales sont-elles sécurisées ?',
    answer:
        'Oui. Toutes les conversations sont privées et chiffrées. Les messages audio sont chiffrés au repos sur nos serveurs. Vos données ne sont jamais partagées avec des tiers sans votre consentement. Seuls vous et votre médecin avez accès à vos échanges.',
  ),

  // Paiements
  _FaqItem(
    category: 'Paiements',
    question: 'Quels modes de paiement sont acceptés ?',
    answer:
        'Nexora accepte les cartes bancaires internationales via Stripe (Visa, Mastercard) ainsi que les paiements locaux via CMI pour les clients au Maroc.',
  ),
  _FaqItem(
    category: 'Paiements',
    question: 'Comment obtenir une facture ?',
    answer:
        'Une facture PDF est générée automatiquement après chaque paiement et envoyée à votre adresse email. Vous pouvez également les retrouver dans la section Paiements de votre profil.',
  ),
  _FaqItem(
    category: 'Paiements',
    question: 'Puis-je obtenir un remboursement ?',
    answer:
        'Les remboursements sont traités au cas par cas. Contactez le support à support@nexora.ma avec votre référence de paiement. Les demandes sont examinées dans un délai de 5 jours ouvrables.',
  ),

  // Médecins
  _FaqItem(
    category: 'Médecins',
    question: 'Comment les médecins sont-ils vérifiés ?',
    answer:
        'Chaque médecin passe par un processus de validation en 4 étapes : vérification d\'identité (CNIE ou passeport), diplôme de Doctorat en Médecine, numéro d\'inscription à l\'Ordre National des Médecins du Maroc (INPE), et certification de spécialité le cas échéant.',
  ),
  _FaqItem(
    category: 'Médecins',
    question: 'Comment évaluer un médecin après une consultation ?',
    answer:
        'À la fin de chaque conversation avec un médecin, une option d\'évaluation apparaît. Vous pouvez attribuer une note de 1 à 5 étoiles et laisser un commentaire facultatif.',
  ),
];
