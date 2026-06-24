import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Plan definitions — single source of truth for the mobile app
// ─────────────────────────────────────────────────────────────────────────────

enum PlanTier { free, pro, premium }

class PlanModel {
  final PlanTier tier;
  final String id;
  final String name;
  final double price;         // MAD / month (0 for free)
  final int credits;          // consultations per month
  final Color accentColor;
  final Color accentBg;
  final String badge;
  final bool highlighted;
  final List<String> features;

  const PlanModel({
    required this.tier,
    required this.id,
    required this.name,
    required this.price,
    required this.credits,
    required this.accentColor,
    required this.accentBg,
    required this.badge,
    required this.highlighted,
    required this.features,
  });

  bool get isFree => tier == PlanTier.free;
}

const kPlans = [
  PlanModel(
    tier: PlanTier.free,
    id: 'free',
    name: 'Gratuit',
    price: 0,
    credits: 0,
    accentColor: Color(0xFF64748B),
    accentBg: Color(0x1264748B),
    badge: 'Actuel',
    highlighted: false,
    features: [
      'Accès à l\'IA Nexora',
      'Analyses médicales générales',
      'Historique des conversations',
      'Triage et orientation',
    ],
  ),
  PlanModel(
    tier: PlanTier.pro,
    id: 'pro',
    name: 'Pro',
    price: 249,
    credits: 3,
    accentColor: Color(0xFF3B82F6),
    accentBg: Color(0x153B82F6),
    badge: 'Populaire',
    highlighted: false,
    features: [
      'Tout du plan Gratuit',
      '3 consultations médecin / mois',
      'Réponses prioritaires de l\'IA',
      'Rappels de santé personnalisés',
      'Support par email',
    ],
  ),
  PlanModel(
    tier: PlanTier.premium,
    id: 'premium',
    name: 'Premium',
    price: 449,
    credits: 6,
    accentColor: Color(0xFF8B5CF6),
    accentBg: Color(0x158B5CF6),
    badge: 'Meilleure valeur',
    highlighted: true,
    features: [
      'Tout du plan Pro',
      '6 consultations médecin / mois',
      'Accès aux spécialistes prioritaires',
      'Ordonnances numériques',
      'Support prioritaire 24/7',
      'Résumés médicaux PDF',
    ],
  ),
];
