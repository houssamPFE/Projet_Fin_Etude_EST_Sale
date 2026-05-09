import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AboutScreen
// ─────────────────────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0';
  static const _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.05,
            right: -size.width * 0.25,
            child: BlurOrb(
              width: size.width * 0.70,
              height: size.height * 0.30,
              color: const Color(0x1A6366F1),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.04,
            left: -size.width * 0.20,
            child: BlurOrb(
              width: size.width * 0.55,
              height: size.height * 0.18,
              color: const Color(0x128B5CF6),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: Row(
                    children: [
                      const NexoraBackButton(),
                      const SizedBox(width: 10),
                      Text('À propos', style: AppTextStyles.headlineSmall),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Logo + version hero
                _HeroCard(version: _version, buildNumber: _buildNumber)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 500.ms)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // Mission
                _SectionLabel(label: 'Notre mission'),
                const SizedBox(height: 10),
                _MissionCard()
                    .animate()
                    .fadeIn(delay: 140.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // Stack technique
                _SectionLabel(label: 'Technologie'),
                const SizedBox(height: 10),
                _TechCard()
                    .animate()
                    .fadeIn(delay: 180.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // Conformité & sécurité
                _SectionLabel(label: 'Conformité & données'),
                const SizedBox(height: 10),
                _ComplianceCard()
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // Liens légaux
                _SectionLabel(label: 'Informations légales'),
                const SizedBox(height: 10),
                _LegalCard()
                    .animate()
                    .fadeIn(delay: 260.ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 24),

                // Disclaimer
                _DisclaimerBanner().animate().fadeIn(
                  delay: 300.ms,
                  duration: 400.ms,
                ),

                const SizedBox(height: 24),

                // Copyright
                Center(
                  child: Text(
                    '© ${DateTime.now().year} Nexora. Tous droits réservés.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 340.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

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
// Hero card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String version;
  final String buildNumber;
  const _HeroCard({required this.version, required this.buildNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cardGlow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          // Logo circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(80),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nexora',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Plateforme de télémédecine IA',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Version badge
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(
                ClipboardData(text: 'v$version (build $buildNumber)'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Version copiée'),
                  backgroundColor: AppColors.surfaceElevated,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Version $version (build $buildNumber)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mission card
// ─────────────────────────────────────────────────────────────────────────────

class _MissionCard extends StatelessWidget {
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
          Text(
            'Nexora connecte les patients francophones d\'Afrique avec des médecins qualifiés, assistés par une intelligence artificielle de pointe.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _FeatureRow(
            icon: Icons.psychology_rounded,
            label: 'Triage IA instantané',
            subtitle: 'GPT-4 analyse vos symptômes en temps réel',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.verified_user_rounded,
            label: 'Médecins vérifiés',
            subtitle: 'Diplôme + inscription à l\'Ordre des Médecins',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.language_rounded,
            label: 'Multilingue',
            subtitle: 'Français & Arabe, conçu pour l\'Afrique francophone',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tech card
// ─────────────────────────────────────────────────────────────────────────────

class _TechCard extends StatelessWidget {
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
          _TechRow(label: 'IA & LLM', value: 'OpenAI GPT-4o', isFirst: true),
          Container(height: 1, color: AppColors.divider),
          _TechRow(label: 'Reconnaissance vocale', value: 'OpenAI Whisper'),
          Container(height: 1, color: AppColors.divider),
          _TechRow(label: 'Synthèse vocale', value: 'ElevenLabs TTS'),
          Container(height: 1, color: AppColors.divider),
          _TechRow(label: 'Base vectorielle', value: 'Qdrant RAG'),
          Container(height: 1, color: AppColors.divider),
          _TechRow(label: 'Temps réel', value: 'Laravel Reverb WebSocket'),
          Container(height: 1, color: AppColors.divider),
          _TechRow(
            label: 'Stockage sécurisé',
            value: 'AWS S3 (chiffrement AES-256)',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _TechRow({
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compliance card
// ─────────────────────────────────────────────────────────────────────────────

class _ComplianceCard extends StatelessWidget {
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
          _ComplianceRow(
            icon: Icons.lock_outline_rounded,
            label: 'Chiffrement de bout en bout',
            isFirst: true,
          ),
          Container(height: 1, color: AppColors.divider),
          _ComplianceRow(
            icon: Icons.delete_forever_outlined,
            label: 'Suppression douce uniquement',
          ),
          Container(height: 1, color: AppColors.divider),
          _ComplianceRow(
            icon: Icons.visibility_off_outlined,
            label: 'Aucun partage de données tiers',
          ),
          Container(height: 1, color: AppColors.divider),
          _ComplianceRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Journaux d\'audit sur accès admin',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ComplianceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isFirst;
  final bool isLast;

  const _ComplianceRow({
    required this.icon,
    required this.label,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal card
// ─────────────────────────────────────────────────────────────────────────────

class _LegalCard extends StatelessWidget {
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
          _LegalRow(
            label: 'Conditions d\'utilisation',
            isFirst: true,
            onTap: () => _showLegalSheet(
              context,
              title: 'Conditions d\'utilisation',
              body:
                  'Nexora accompagne les échanges de santé à distance. Les réponses IA sont informatives et doivent être confirmées par un professionnel de santé quand la situation le nécessite. L’utilisateur reste responsable de fournir des informations exactes et de contacter les urgences en cas de symptôme grave.',
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          _LegalRow(
            label: 'Politique de confidentialité',
            onTap: () => _showLegalSheet(
              context,
              title: 'Politique de confidentialité',
              body:
                  'Les données de profil, conversations et préférences servent uniquement à fournir l’expérience Nexora. Les accès sensibles sont limités, les contenus médicaux restent privés, et les préférences locales restent stockées sur l’appareil quand aucune synchronisation serveur n’est requise.',
            ),
          ),
          Container(height: 1, color: AppColors.divider),
          _LegalRow(
            label: 'Mentions légales',
            isLast: true,
            onTap: () => _showLegalSheet(
              context,
              title: 'Mentions légales',
              body:
                  'Nexora v1.0.0 est une application de télémédecine assistée par IA. Support : support@nexora.ma. En cas d’urgence médicale au Maroc, appelez le 141 ou rendez-vous au service d’urgence le plus proche.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final String label;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _LegalRow({
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          isFirst ? 16 : 12,
          16,
          isLast ? 16 : 12,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.titleSmall)),
            const Icon(
              Icons.open_in_new_rounded,
              size: 15,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

void _showLegalSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.overlay,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              Text(
                body,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppGradients.button,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Compris',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Disclaimer banner
// ─────────────────────────────────────────────────────────────────────────────

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryLight,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les informations fournies par Nexora ne remplacent pas une consultation médicale. En cas d\'urgence, appelez le 141 (SAMU Maroc) ou rendez-vous aux urgences.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
