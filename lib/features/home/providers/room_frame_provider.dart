import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/settings/app_settings_repository.dart';
import '../widgets/room_frame_skins.dart';

/// Which casing each room card wears on 房間選擇, and which casings the player
/// may equip.
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

  Future<void> equip(String roomId, RoomFrameStyle style) async {
    if (roomId.isEmpty || !ownedStyles.contains(style)) {
      return;
    }
    state = {...state, roomId: style};
    await AppSettingsRepository.instance.setRoomFrameStyle(
      roomId,
      style.storageKey,
    );
  }

  /// Casings the player may equip. Free casings are always available; priced
  /// ones unlock through the shop, which does not carry frame items yet.
  Set<RoomFrameStyle> get ownedStyles {
    return {
      for (final style in RoomFrameStyle.values)
        if (RoomFrameSkins.candyPrice(style) == null) style,
    };
  }
}

final roomFrameProvider =
    NotifierProvider<RoomFrameNotifier, Map<String, RoomFrameStyle>>(
      RoomFrameNotifier.new,
    );
