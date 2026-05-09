import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/category_model.dart';
import '../models/expert_model.dart';

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

// Fetch all experts (doctors)
// GET /api/v1/experts → { data: [...] }
final expertsProvider = FutureProvider<List<ExpertModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/experts');
  final data = res.data!['data'] as List;
  return data
      .map((e) => ExpertModel.fromJson(e as Map<String, dynamic>))
      .toList();
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
