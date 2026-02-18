import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSummary {
  const ProfileSummary({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
  });

  final String userId;
  final String? nickname;
  final String? avatarUrl;
}

class ProfileCacheService {
  ProfileCacheService._();

  static final ProfileCacheService instance = ProfileCacheService._();

  final Map<String, ProfileSummary> _cache = {};

  Future<ProfileSummary?> getProfile(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = _cache[userId];
      if (cached != null) {
        return cached;
      }
    }

    final profiles = await getProfiles([userId], forceRefresh: forceRefresh);
    return profiles[userId];
  }

  Future<Map<String, ProfileSummary>> getProfiles(
    Iterable<String> userIds, {
    bool forceRefresh = false,
  }) async {
    final deduped = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (deduped.isEmpty) {
      return const <String, ProfileSummary>{};
    }

    if (!forceRefresh && deduped.every(_cache.containsKey)) {
      return {for (final userId in deduped) userId: _cache[userId]!};
    }

    final idsToFetch = forceRefresh
        ? deduped.toList(growable: false)
        : deduped
              .where((id) => !_cache.containsKey(id))
              .toList(growable: false);

    if (idsToFetch.isNotEmpty) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('user_id,nickname,avatar_url')
          .inFilter('user_id', idsToFetch);
      final rows = response as List<dynamic>;
      for (final row in rows) {
        final userId = row['user_id'] as String?;
        if (userId == null || userId.isEmpty) {
          continue;
        }
        _cache[userId] = ProfileSummary(
          userId: userId,
          nickname: row['nickname'] as String?,
          avatarUrl: row['avatar_url'] as String?,
        );
      }
    }

    return {
      for (final userId in deduped.where(_cache.containsKey))
        userId: _cache[userId]!,
    };
  }

  void prime(ProfileSummary profile) {
    _cache[profile.userId] = profile;
  }

  void clear() {
    _cache.clear();
  }
}
