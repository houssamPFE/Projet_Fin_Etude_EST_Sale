import 'package:flutter/material.dart';

class ExpertModel {
  final String name;
  final String specialty;
  final String category;
  final double rating;
  final int reviewCount;
  final int rate;
  final String initials;
  final Color color;
  final bool online;

  const ExpertModel({
    required this.name,
    required this.specialty,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.rate,
    required this.initials,
    required this.color,
    this.online = true,
  });
}
