import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/widgets.dart';
import '../../home/models/expert_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceData {
  final String name;
  final String description;
  final String duration;
  final int price;
  final IconData icon;
  const _ServiceData({
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.icon,
  });
}

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
// Mock bios
// ─────────────────────────────────────────────────────────────────────────────

const _kDefaultBio =
    "Expert qualifié avec plus de 8 ans d'expérience dans son domaine. "
    "Approche personnalisée et rigoureuse, combinant expertise technique et écoute active. "
    "Disponible pour des consultations en français et en arabe, avec un engagement fort "
    "pour la satisfaction et l'accompagnement de chaque client.";

const _kBios = {
  'Médecine':
      "Médecin généraliste diplômée de la Faculté de Médecine de Casablanca, avec "
          "plus de 8 ans d'expérience en médecine générale et préventive. Spécialisée "
          "dans le diagnostic et le suivi des maladies chroniques : diabète, hypertension "
          "et maladies respiratoires. Approche centrée sur le patient, combinant médecine "
          "préventive et curative. Consultations disponibles en français et en arabe.",
  'Droit':
      "Avocat inscrit au Barreau de Casablanca depuis 2015, expert en droit des "
          "affaires et droit commercial. Fort de 9 ans d'expérience dans l'accompagnement "
          "juridique des entreprises et des particuliers. Intervenant régulier pour les "
          "contrats commerciaux, litiges et conseils en création d'entreprise. "
          "Membre de l'Association des Avocats d'Affaires du Maroc.",
  'Fiscalité':
      "Expert-comptable et conseiller fiscal agréé avec 10 ans d'expérience dans "
          "l'optimisation fiscale pour PME et indépendants. Maîtrise parfaite du code "
          "général des impôts marocain, TVA, IR et IS. Accompagnement complet de la "
          "déclaration fiscale au contrôle fiscal, avec un réseau solide d'experts.",
  'Finance':
      "Analyste financier certifié avec 11 ans d'expérience en gestion de patrimoine, "
          "marchés boursiers et planification financière. Expertise en investissement, "
          "épargne et stratégies de diversification adaptées au marché marocain et africain. "
          "Ancien conseiller senior dans un cabinet de conseil financier international.",
  'Technologie':
      "Ingénieur en informatique diplômé de l'ENSIAS, spécialisé en développement "
          "logiciel, intelligence artificielle et transformation digitale. 7 ans d'expérience "
          "en startups et grands groupes. Expert en architecture cloud, APIs RESTful et "
          "solutions IA pour entreprises. Contributeur open-source actif.",
  'Éducation':
      "Conseillère pédagogique avec 12 ans d'expérience dans l'orientation scolaire "
          "et universitaire. Maîtrise des systèmes éducatifs marocain, français et international. "
          "Accompagnement personnalisé pour lycéens et étudiants dans leur choix de filière "
          "et préparation aux concours des grandes écoles.",
  'Entrepreneuriat':
      "Entrepreneur et mentor reconnu, fondateur de 3 startups à succès au Maroc "
          "et en Afrique subsaharienne. Expert en business planning, levée de fonds, "
          "stratégie go-to-market et développement commercial B2B. Mentor dans plusieurs "
          "programmes d'incubation et accélération au Maroc.",
  'Administration':
      "Ancienne fonctionnaire et consultante en administration publique depuis 15 ans. "
          "Expertise dans les démarches administratives, marchés publics, permis de "
          "construire et formalités légales. Facilite les relations avec l'administration "
          "marocaine avec transparence et efficacité.",
};

// ─────────────────────────────────────────────────────────────────────────────
// Mock services
// ─────────────────────────────────────────────────────────────────────────────

const _kDefaultServices = [
  _ServiceData(
    name: 'Consultation standard',
    description: "Analyse de votre situation et conseils personnalisés",
    duration: '30 min',
    price: 150,
    icon: Icons.chat_outlined,
  ),
  _ServiceData(
    name: 'Accompagnement complet',
    description: "Suivi approfondi avec plan d'action détaillé",
    duration: '60 min',
    price: 280,
    icon: Icons.support_agent_rounded,
  ),
  _ServiceData(
    name: 'Session premium',
    description: 'Session intensive avec rapport et recommandations',
    duration: '90 min',
    price: 450,
    icon: Icons.workspace_premium_outlined,
  ),
];

const _kServices = {
  'Médecine': [
    _ServiceData(name: 'Consultation médicale', description: 'Diagnostic, conseils et ordonnance si nécessaire', duration: '30 min', price: 150, icon: Icons.medical_services_outlined),
    _ServiceData(name: 'Suivi chronique', description: 'Suivi mensuel pour diabète, HTA, asthme...', duration: '45 min', price: 200, icon: Icons.favorite_outline_rounded),
    _ServiceData(name: 'Bilan de santé complet', description: 'Analyse globale et plan de prévention personnalisé', duration: '60 min', price: 350, icon: Icons.health_and_safety_outlined),
  ],
  'Droit': [
    _ServiceData(name: 'Consultation juridique', description: 'Analyse et conseils pour votre situation légale', duration: '45 min', price: 200, icon: Icons.gavel_rounded),
    _ServiceData(name: 'Rédaction de contrat', description: 'Rédaction, révision et validation de contrats', duration: '60 min', price: 350, icon: Icons.description_outlined),
    _ServiceData(name: 'Gestion de litige', description: 'Stratégie et soutien pour résolution de conflits', duration: '90 min', price: 500, icon: Icons.balance_rounded),
  ],
  'Fiscalité': [
    _ServiceData(name: 'Déclaration fiscale', description: 'Préparation et optimisation de votre déclaration', duration: '45 min', price: 120, icon: Icons.receipt_long_outlined),
    _ServiceData(name: 'Audit fiscal', description: 'Analyse complète de votre situation fiscale', duration: '60 min', price: 250, icon: Icons.account_balance_outlined),
    _ServiceData(name: 'Accompagnement contrôle', description: "Assistance lors d'un contrôle fiscal", duration: '90 min', price: 400, icon: Icons.shield_outlined),
  ],
  'Finance': [
    _ServiceData(name: 'Bilan patrimonial', description: 'Analyse de votre patrimoine et objectifs financiers', duration: '45 min', price: 180, icon: Icons.pie_chart_outline_rounded),
    _ServiceData(name: "Stratégie d'investissement", description: "Plan d'investissement personnalisé selon votre profil", duration: '60 min', price: 300, icon: Icons.trending_up_rounded),
    _ServiceData(name: 'Planification retraite', description: 'Préparez votre retraite avec un plan sur mesure', duration: '60 min', price: 280, icon: Icons.savings_outlined),
  ],
  'Technologie': [
    _ServiceData(name: 'Audit technique', description: 'Analyse de votre infrastructure et stack technique', duration: '60 min', price: 250, icon: Icons.search_rounded),
    _ServiceData(name: 'Architecture projet', description: 'Conception architecture logicielle scalable', duration: '90 min', price: 450, icon: Icons.account_tree_outlined),
    _ServiceData(name: 'Coaching développeur', description: 'Session personnalisée pour monter en compétences', duration: '60 min', price: 300, icon: Icons.code_rounded),
  ],
  'Éducation': [
    _ServiceData(name: "Bilan d'orientation", description: 'Identification de votre profil et filières adaptées', duration: '60 min', price: 90, icon: Icons.school_outlined),
    _ServiceData(name: 'Préparation concours', description: 'Stratégie et planning pour les grandes écoles', duration: '45 min', price: 120, icon: Icons.emoji_events_outlined),
    _ServiceData(name: 'Suivi mensuel', description: "Accompagnement régulier tout au long de l'année", duration: '30 min', price: 80, icon: Icons.calendar_month_outlined),
  ],
  'Entrepreneuriat': [
    _ServiceData(name: 'Validation de projet', description: "Analyse de votre idée et plan de validation marché", duration: '45 min', price: 200, icon: Icons.lightbulb_outline_rounded),
    _ServiceData(name: 'Business Plan', description: 'Rédaction BP complet et investisseur-ready', duration: '90 min', price: 450, icon: Icons.business_center_outlined),
    _ServiceData(name: 'Pitch Investor', description: 'Préparation pitch deck et simulation investisseurs', duration: '60 min', price: 350, icon: Icons.rocket_launch_outlined),
  ],
  'Administration': [
    _ServiceData(name: 'Démarche administrative', description: 'Assistance pour vos formalités administratives', duration: '30 min', price: 100, icon: Icons.assignment_outlined),
    _ServiceData(name: "Création d'entreprise", description: 'Accompagnement complet pour créer votre société', duration: '60 min', price: 200, icon: Icons.store_outlined),
    _ServiceData(name: "Appel d'offres public", description: "Aide à la préparation d'un dossier marchés publics", duration: '90 min', price: 350, icon: Icons.handshake_outlined),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// Mock reviews (shared across all profiles)
// ─────────────────────────────────────────────────────────────────────────────

const _kReviews = [
  _ReviewData(
    reviewer: 'Ahmed Benali',
    initials: 'AB',
    reviewerColor: Color(0xFF6366F1),
    rating: 5,
    comment: "Très professionnel et à l'écoute. Les explications sont claires et les conseils vraiment utiles. Je recommande vivement !",
    date: 'Il y a 3 jours',
  ),
  _ReviewData(
    reviewer: 'Fatima Moussaoui',
    initials: 'FM',
    reviewerColor: Color(0xFF8B5CF6),
    rating: 5,
    comment: "Excellente expérience ! La réponse a été rapide et le suivi très professionnel. Exactement ce dont j'avais besoin.",
    date: 'Il y a 1 semaine',
  ),
  _ReviewData(
    reviewer: 'Youssef Kadiri',
    initials: 'YK',
    reviewerColor: Color(0xFF3B82F6),
    rating: 4,
    comment: "Très bonne expertise. Je suis satisfait de la consultation et reviendrai certainement pour un suivi approfondi.",
    date: 'Il y a 2 semaines',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// ExpertProfileScreen
// ─────────────────────────────────────────────────────────────────────────────

class ExpertProfileScreen extends StatelessWidget {
  final ExpertModel expert;

  const ExpertProfileScreen({
    super.key,
    required this.expert,
  });

  String get name => expert.name;
  String get specialty => expert.specialty;
  double get rating => expert.rating;
  int get reviewCount => expert.reviewCount;
  int get rate => expert.hourlyRate;
  String get initials => expert.initials;
  Color get color => expert.avatarColor;
  bool get online => expert.isAvailable;

  String get _bio => expert.bio;
  List<_ServiceData> get _services => _kServices[expert.specialty] ?? _kDefaultServices;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

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
                  color: color,
                  online: online,
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

                // ── Services ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Services proposés'),
                      const SizedBox(height: 12),
                      ..._services.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ServiceCard(service: s, color: color),
                        ),
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
                      ..._kReviews.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReviewCard(review: r),
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
              rate: rate,
              bottomPadding: bottomPadding,
              name: name,
              initials: initials,
              color: color,
              specialty: specialty,
              online: online,
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
  final Color color;
  final bool online;

  const _HeroSection({
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.initials,
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primary,
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
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
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
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
        const SizedBox(width: 10),
        const _StatCard(
          icon: Icons.work_outline_rounded,
          iconColor: AppColors.secondary,
          value: '8 ans',
          label: 'Expérience',
        ),
        const SizedBox(width: 10),
        const _StatCard(
          icon: Icons.flash_on_rounded,
          iconColor: AppColors.accent,
          value: '< 5 min',
          label: 'Réponse',
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
// Service card
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceData service;
  final Color color;
  const _ServiceCard({required this.service, required this.color});

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
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(55)),
            ),
            child: Icon(service.icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  service.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Duration chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 11,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            service.duration,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${service.price} MAD',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
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

class _BottomCTA extends StatelessWidget {
  final int rate;
  final double bottomPadding;
  final String name;
  final String initials;
  final Color color;
  final String specialty;
  final bool online;

  const _BottomCTA({
    required this.rate,
    required this.bottomPadding,
    required this.name,
    required this.initials,
    required this.color,
    required this.specialty,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(242),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'À partir de',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '$rate MAD/h',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: NexoraGradientButton(
              label: 'Démarrer une conversation',
              onTap: () => context.push(AppRoutes.chat, extra: {
                'name': name,
                'initials': initials,
                'color': color,
                'subtitle': specialty,
                'online': online,
                'isAi': false,
              }),
              height: 50,
            ),
          ),
        ],
      ),
    );
  }
}
