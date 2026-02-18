import 'package:flutter_riverpod/flutter_riverpod.dart';

int resolveRoomUnreadCount(Map<String, dynamic> room) {
  final unread = room['unread_count'];
  if (unread is int) {
    return unread < 0 ? 0 : unread;
  }
  if (unread is num) {
    final value = unread.toInt();
    return value < 0 ? 0 : value;
  }
  return room['has_unread'] == true ? 1 : 0;
}

Map<String, int> unreadCountsByRoomFromRooms(List<Map<String, dynamic>> rooms) {
  final counts = <String, int>{};
  for (final room in rooms) {
    final roomId = room['id'] as String?;
    if (roomId == null || roomId.isEmpty) {
      continue;
    }
    counts[roomId] = resolveRoomUnreadCount(room);
  }
  return counts;
}

class HomeUnreadCountsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const <String, int>{};

  void replaceAll(Map<String, int> next) {
    final sanitized = <String, int>{};
    for (final entry in next.entries) {
      if (entry.key.isEmpty) {
        continue;
      }
      sanitized[entry.key] = entry.value < 0 ? 0 : entry.value;
    }
    state = sanitized;
  }

  void increment(String roomId) {
    if (roomId.isEmpty) {
      return;
    }
    final current = state[roomId] ?? 0;
    state = <String, int>{...state, roomId: current + 1};
  }

  void markRead(String roomId) {
    if (roomId.isEmpty) {
      return;
    }
    state = <String, int>{...state, roomId: 0};
  }

  void clear() {
    state = const <String, int>{};
  }
}

final homeUnreadCountsProvider =
    NotifierProvider<HomeUnreadCountsNotifier, Map<String, int>>(
      HomeUnreadCountsNotifier.new,
    );

final homeTotalUnreadCountProvider = Provider<int>((ref) {
  final counts = ref.watch(homeUnreadCountsProvider);
  return counts.values.fold(0, (sum, value) => sum + value);
});
