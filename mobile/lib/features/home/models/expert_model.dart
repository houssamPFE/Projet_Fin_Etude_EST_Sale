import 'package:flutter/material.dart';

class ExpertModel {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int categoryId;
  final String specialty; // category name
  final String specialtyIcon;
  final String bio;
  final int hourlyRate;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  /// Real-time online presence — true when the doctor's heartbeat Redis key is alive.
  final bool isOnline;

  const ExpertModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.categoryId,
    required this.specialty,
    required this.specialtyIcon,
    required this.bio,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    this.isOnline = false,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    return (parts.first.substring(0, 1) + (parts.length > 1 ? parts.last.substring(0, 1) : ''))
        .toUpperCase();
  }

  Color get avatarColor {
    // Deterministic color based on id
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFD946EF),
      const Color(0xFFF43F5E),
      const Color(0xFFFB923C),
    ];
    return colors[id % colors.length];
  }

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    return ExpertModel(
      id: json['id'] as int,
      name: user?['name'] as String? ?? 'Expert',
      email: user?['email'] as String? ?? '',
      avatarUrl: user?['avatar_url'] as String?,
      categoryId: category?['id'] as int? ?? 0,
      specialty: category?['name'] as String? ?? 'Unknown',
      specialtyIcon: category?['icon'] as String? ?? '🏥',
      bio: json['bio'] as String? ?? '',
      hourlyRate: _parseIntOrDouble(json['hourly_rate']).toInt(),
      rating: _parseIntOrDouble(json['rating_avg']),
      reviewCount: json['total_reviews'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? false,
      isOnline: user?['is_online'] as bool? ?? false,
    );
  }

  static double _parseIntOrDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
