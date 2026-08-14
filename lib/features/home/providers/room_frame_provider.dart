import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/settings/app_settings_repository.dart';
import '../widgets/room_frame_skins.dart';

/// Which casing each room card wears on 房間選擇.
///
/// Which casings are *available* is not stored: it is derived from the room's
/// level by [RoomFrameSkins.isUnlocked].
///
/// Backed by [AppSettingsRepository] (Hive). Frames are a per-device preference
/// today; when the shop-backed `items` rows and the server column land, only
/// this notifier changes — the views read it through the same shape.
class RoomFrameNotifier extends Notifier<Map<String, RoomFrameStyle>> {
  @override
  Map<String, RoomFrameStyle> build() {
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

  /// Equips [style] on [roomId]. The level gate lives in the 換相框 sheet,
  /// which is the only surface that knows the room's level.
  Future<void> equip(String roomId, RoomFrameStyle style) async {
    if (roomId.isEmpty) {
      return;
    }
    state = {...state, roomId: style};
    await AppSettingsRepository.instance.setRoomFrameStyle(
      roomId,
      style.storageKey,
    );
  }
}

final roomFrameProvider =
    NotifierProvider<RoomFrameNotifier, Map<String, RoomFrameStyle>>(
      RoomFrameNotifier.new,
    );
