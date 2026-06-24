import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/category_model.dart';
import '../models/expert_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Categories (static, no polling needed)
// ─────────────────────────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/categories');
  final data = res.data!['data'] as List;
  return data
      .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
      .toList();
});

// ─────────────────────────────────────────────────────────────────────────────
// Experts — silent background polling every 20 s
//
// Uses AsyncNotifier so presence updates never cause a loading flash:
//   - First build → shows AsyncLoading → fetches → AsyncData
//   - Every 20 s   → fetches silently  → jumps straight to AsyncData
//     (no AsyncLoading, no shimmer, no counter reset)
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertsNotifier extends AsyncNotifier<List<ExpertModel>> {
  Timer? _timer;

  @override
  Future<List<ExpertModel>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _silentRefresh(),
    );
    return _fetch();
  }

  Future<List<ExpertModel>> _fetch() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get<Map<String, dynamic>>('/experts');
    final data = res.data!['data'] as List;
    return data
        .map((e) => ExpertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _silentRefresh() async {
    try {
      final fresh = await _fetch();
      state = AsyncData(fresh); // skip loading state entirely
    } catch (_) {
      // keep previous data on transient error — don't show error screen
    }
  }

  // Allow pull-to-refresh from UI without shimmer flash
  Future<void> manualRefresh() => _silentRefresh();
}

final expertsProvider =
    AsyncNotifierProvider<_ExpertsNotifier, List<ExpertModel>>(
        _ExpertsNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Single expert (profile page) — same silent-poll pattern
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertLiveNotifier extends FamilyAsyncNotifier<ExpertModel, int> {
  Timer? _timer;

  @override
  Future<ExpertModel> build(int id) async {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _silentRefresh(id),
    );
    return _fetch(id);
  }

  Future<ExpertModel> _fetch(int id) async {
    final dio = ref.read(dioProvider);
    final res = await dio.get<Map<String, dynamic>>('/experts/$id');
    return ExpertModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> _silentRefresh(int id) async {
    try {
      final fresh = await _fetch(id);
      state = AsyncData(fresh);
    } catch (_) {}
  }
}

final expertLiveProvider =
    AsyncNotifierProvider.family<_ExpertLiveNotifier, ExpertModel, int>(
        _ExpertLiveNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Expert reviews
// ─────────────────────────────────────────────────────────────────────────────

final expertReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, expertId) async {
  final dio = ref.watch(dioProvider);
  final res =
      await dio.get<Map<String, dynamic>>('/experts/$expertId/reviews');
  final data = res.data!['data'] as List? ?? [];
  return data.map((r) => r as Map<String, dynamic>).toList();
});
