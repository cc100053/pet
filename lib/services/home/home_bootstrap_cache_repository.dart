import 'package:hive_flutter/hive_flutter.dart';

class HomeBootstrapCacheRepository {
  HomeBootstrapCacheRepository._();

  static final HomeBootstrapCacheRepository instance =
      HomeBootstrapCacheRepository._();

  static const String _boxName = 'home_bootstrap_cache';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<Map<String, dynamic>?> loadForUser(String userId) async {
    final box = _box;
    if (box == null) {
      return null;
    }
    final raw = box.get(userId);
    if (raw is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<void> saveForUser({
    required String userId,
    required Map<String, dynamic> snapshot,
  }) async {
    final box = _box;
    if (box == null) {
      return;
    }
    final payload = <String, dynamic>{
      ...snapshot,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    };
    await box.put(userId, payload);
  }
}
