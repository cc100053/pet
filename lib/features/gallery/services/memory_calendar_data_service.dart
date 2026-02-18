import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/profile/profile_cache_service.dart';
import '../models/memory_feed.dart';

class MemoryCalendarDataService {
  MemoryCalendarDataService._();

  static final MemoryCalendarDataService instance =
      MemoryCalendarDataService._();

  Future<Set<String>> loadBlockedUserIds({
    required String? currentUserId,
  }) async {
    final blocked = <String>{};
    if (currentUserId == null) {
      return blocked;
    }

    final response = await Supabase.instance.client
        .from('blocks')
        .select('blocked_user_id')
        .eq('blocker_id', currentUserId);

    final rows = response as List<dynamic>;
    for (final row in rows) {
      final id = row['blocked_user_id'] as String?;
      if (id != null && id.isNotEmpty) {
        blocked.add(id);
      }
    }
    return blocked;
  }

  Future<List<MemoryFeed>> loadMonthFeeds({
    required String roomId,
    required DateTime month,
    required Set<String> blockedUserIds,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final response = await Supabase.instance.client
        .from('messages')
        .select('id,sender_id,image_url,caption,created_at')
        .eq('room_id', roomId)
        .eq('type', 'image_feed')
        .gte('created_at', start.toUtc().toIso8601String())
        .lt('created_at', end.toUtc().toIso8601String())
        .order('created_at', ascending: true);

    final rows = response as List<dynamic>;
    return rows
        .map((row) => MemoryFeed.fromJson(row))
        .where((feed) => feed.imageUrl.isNotEmpty)
        .where(
          (feed) =>
              feed.senderId == null || !blockedUserIds.contains(feed.senderId),
        )
        .toList();
  }

  Future<List<MemoryFeed>> loadLatestFeeds({
    required String roomId,
    required Set<String> blockedUserIds,
    int limit = 10,
  }) async {
    final response = await Supabase.instance.client
        .from('messages')
        .select('id,sender_id,image_url,caption,created_at')
        .eq('room_id', roomId)
        .eq('type', 'image_feed')
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = response as List<dynamic>;
    return rows
        .map((row) => MemoryFeed.fromJson(row))
        .where((feed) => feed.imageUrl.isNotEmpty)
        .where(
          (feed) =>
              feed.senderId == null || !blockedUserIds.contains(feed.senderId),
        )
        .toList();
  }

  Future<Map<String, ProfileSummary>> loadSenderProfiles(
    Iterable<String> senderIds,
  ) async {
    return ProfileCacheService.instance.getProfiles(senderIds);
  }
}
