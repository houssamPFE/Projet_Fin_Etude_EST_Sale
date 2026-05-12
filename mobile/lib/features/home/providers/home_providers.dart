import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/category_model.dart';
import '../models/expert_model.dart';

/// Emits an incrementing int every 20 s.
/// Any FutureProvider that watches this will re-execute automatically,
/// keeping expert online-presence dots fresh without manual refreshes.
final _presencePollProvider = StreamProvider<int>((ref) {
  var i = 0;
  return Stream.periodic(const Duration(seconds: 20), (_) => i++);
});

// Fetch all categories (medical specialties)
// GET /api/v1/categories → { data: [...] }
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/categories');
  final data = res.data!['data'] as List;
  return data
      .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
      .toList();
});

// Fetch all experts (doctors) — refreshes every 20 s for live online dots.
// GET /api/v1/experts → { data: [...] }
final expertsProvider = FutureProvider<List<ExpertModel>>((ref) async {
  ref.watch(_presencePollProvider); // re-run every 20 s
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/experts');
  final data = res.data!['data'] as List;
  return data
      .map((e) => ExpertModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Fetch a single expert by ID — refreshes every 20 s so the profile page
/// shows an accurate "En ligne" dot without leaving the screen.
/// GET /api/v1/experts/{id} → { data: {...} }
final expertLiveProvider =
    FutureProvider.family<ExpertModel, int>((ref, id) async {
  ref.watch(_presencePollProvider); // re-run every 20 s
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/experts/$id');
  final data = res.data!['data'] as Map<String, dynamic>;
  return ExpertModel.fromJson(data);
});

// Fetch reviews for a specific expert
// GET /api/v1/experts/{id}/reviews → { data: [...] }
final expertReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, expertId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/experts/$expertId/reviews');
  final data = res.data!['data'] as List? ?? [];
  return data.map((r) => r as Map<String, dynamic>).toList();
});
