import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/settings/app_settings_repository.dart';
import '../../../shared/errors/user_facing_error.dart';
import '../widgets/room_frame_skins.dart';

final roomFrameClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Shared room casings, with Hive as the last-known/legacy fallback.
/// Local choices are never uploaded except on an explicit confirmation.
class RoomFrameNotifier extends Notifier<Map<String, RoomFrameStyle>> {
  final _updatedAtByRoom = <String, DateTime>{};
  int _generation = 0;

  @override
  Map<String, RoomFrameStyle> build() {
    ref.onDispose(stopSync);
    final stored = AppSettingsRepository.instance.roomFrameStyles;
    final resolved = <String, RoomFrameStyle>{};
    stored.forEach((roomId, styleKey) {
      final style = RoomFrameStyle.fromStorageKey(styleKey);
      if (style != null) {
        resolved[roomId] = style;
      }
    });
    return resolved;
  }

  /// Invalidates in-flight work when Home/session is torn down.
  void stopSync() {
    _generation++;
    _updatedAtByRoom.clear();
  }

  Future<void> refresh(List<String> roomIds) async {
    if (roomIds.isEmpty) {
      return;
    }
    final client = ref.read(roomFrameClientProvider);
    final userId = client.auth.currentUser?.id;
    final generation = _generation;
    try {
      final rows = await client
          .from('room_frame_state')
          .select('room_id, style, updated_at')
          .inFilter('room_id', roomIds)
          .timeout(const Duration(seconds: 10));
      if (generation != _generation || client.auth.currentUser?.id != userId) {
        return;
      }
      for (final row in rows) {
        if (generation != _generation ||
            client.auth.currentUser?.id != userId) {
          return;
        }
        await _applySharedRow(row);
      }
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'room_frame_refresh');
    }
  }

  /// Server validates membership and the same level ladder as the picker.
  Future<void> equip(String roomId, RoomFrameStyle style) async {
    if (roomId.isEmpty) {
      throw ArgumentError.value(roomId, 'roomId');
    }
    final client = ref.read(roomFrameClientProvider);
    final userId = client.auth.currentUser?.id;
    final generation = _generation;
    final row = await client
        .from('room_frame_state')
        .upsert({'room_id': roomId, 'style': style.storageKey})
        .select('room_id, style, updated_at')
        .single()
        .timeout(const Duration(seconds: 10));
    if (generation != _generation || client.auth.currentUser?.id != userId) {
      return;
    }
    await _applySharedRow(row);
  }

  Future<void> _applySharedRow(Map<String, dynamic> row) async {
    final roomId = row['room_id'] as String?;
    final updatedAt = DateTime.tryParse(row['updated_at'] as String? ?? '');
    if (roomId == null || updatedAt == null) {
      return;
    }
    final previous = _updatedAtByRoom[roomId];
    if (previous != null && updatedAt.isBefore(previous)) {
      return;
    }
    _updatedAtByRoom[roomId] = updatedAt;
    final style =
        RoomFrameStyle.fromStorageKey(row['style'] as String?) ??
        RoomFrameSkins.defaultStyle;
    state = {...state, roomId: style};
    try {
      await AppSettingsRepository.instance.setRoomFrameStyle(
        roomId,
        style.storageKey,
      );
    } catch (error, stackTrace) {
      // The server save already succeeded; a cache failure must not undo it.
      reportSwallowedError(error, stackTrace, source: 'room_frame_cache');
    }
  }
}

final roomFrameProvider =
    NotifierProvider<RoomFrameNotifier, Map<String, RoomFrameStyle>>(
      RoomFrameNotifier.new,
    );
