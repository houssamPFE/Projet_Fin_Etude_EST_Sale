import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static const _kConversations = 'cached_conversations';

  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kConversations, jsonEncode(conversations));
    } catch (e) {
      debugPrint('[Cache] Save failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kConversations);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('[Cache] Load failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConversations);
  }
}

final offlineCacheProvider =
    Provider<OfflineCacheService>((_) => OfflineCacheService());
