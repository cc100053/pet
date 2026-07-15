part of 'home_view.dart';

extension _HomeDataHelpers on _HomeViewState {
  int _extractRewardAmount(dynamic payload) {
    if (payload == null) {
      return 0;
    }
    if (payload is int) {
      return payload;
    }
    if (payload is num) {
      return payload.round();
    }
    if (payload is String) {
      return int.tryParse(payload) ?? 0;
    }
    if (payload is List) {
      if (payload.isEmpty) {
        return 0;
      }
      return _extractRewardAmount(payload.first);
    }
    if (payload is Map) {
      final dynamic row = payload['coins_awarded'] ?? payload['reward'];
      return _extractRewardAmount(row);
    }
    return 0;
  }

  List<Map<String, double>> _normalizePoopPositions(dynamic raw) {
    final positions = <Map<String, double>>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map) {
          final x = (entry['x'] as num?)?.toDouble();
          final y = (entry['y'] as num?)?.toDouble();
          if (x == null || y == null) {
            continue;
          }
          positions.add({
            'x': x.clamp(0.05, 0.95).toDouble(),
            'y': y.clamp(0.05, 0.95).toDouble(),
          });
        }
      }
    }
    return positions;
  }

  _PetExpUpdate _applyExpDelta({
    required int level,
    required int exp,
    required int delta,
  }) {
    var nextLevel = level < 1 ? 1 : level;
    var nextExp = exp < 0 ? 0 : exp;
    nextExp += delta;
    if (nextExp < 0) {
      nextExp = 0;
    }
    while (nextLevel < kMaxPetLevel) {
      final required = xpRequiredForNextLevel(nextLevel);
      if (required <= 0 || nextExp < required) {
        break;
      }
      nextExp -= required;
      nextLevel += 1;
    }
    if (nextLevel >= kMaxPetLevel) {
      nextLevel = kMaxPetLevel;
      nextExp = 0;
    }
    return _PetExpUpdate(level: nextLevel, exp: nextExp);
  }

  bool _isRoomLikelyDeparted(String roomId) {
    if (_departedPetsByRoom.containsKey(roomId)) {
      return true;
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final health = room['pet_health'] as num?;
      if (health != null && health <= 0) {
        return true;
      }
      break;
    }
    return false;
  }

  bool _isAdminClaim(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return false;
    }
    final direct =
        _asBool(data['is_admin']) ??
        _asBool(data['admin']) ??
        _asBool(data['isAdmin']);
    if (direct == true) {
      return true;
    }

    final role = data['role'] ?? data['app_role'] ?? data['user_role'];
    if (role is String && role.toLowerCase() == 'admin') {
      return true;
    }

    final roles = data['roles'];
    if (roles is List) {
      for (final roleEntry in roles) {
        if (roleEntry is String && roleEntry.toLowerCase() == 'admin') {
          return true;
        }
      }
    }
    return false;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  double _healthValueFromHunger(num? hunger) {
    final value = (hunger?.toDouble() ?? 0.0) / 100;
    if (!value.isFinite) {
      return 0.0;
    }
    return value.clamp(0.0, 1.0);
  }

  double _healthValue() {
    return _healthValueFromHunger(petStatusHunger(_effectivePetState));
  }

  String _departureHeroTag(String petId) => 'pet_departure_note_$petId';

  DepartedPetInfo? _currentDepartedPetInfo() {
    final roomId = _roomId;
    if (roomId == null) {
      return null;
    }
    return _departedPetsByRoom[roomId];
  }

  List<DepartedPetInfo> _departedPetsForCurrentRoom() {
    final current = _currentDepartedPetInfo();
    if (current == null) {
      return const <DepartedPetInfo>[];
    }
    return <DepartedPetInfo>[current];
  }

  String _resolvePetNameForRoom(String roomId) {
    if (roomId == _roomId) {
      final name = _petName?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final name = (room['pet_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
      break;
    }
    return AppLocalizations.of(context)!.petNameUnknown;
  }

  String _resolvePetTypeForRoom(String roomId) {
    if (roomId == _roomId) {
      return PetCatalog.resolveIdForAppVersion(
        _petType,
        appVersion: _currentAppVersion,
      );
    }
    for (final room in _myRooms) {
      if (room['id'] != roomId) {
        continue;
      }
      final type = room['pet_type'] as String?;
      return PetCatalog.resolveIdForAppVersion(
        type,
        appVersion: _currentAppVersion,
      );
    }
    return PetCatalog.defaultPetId;
  }

  String _resolveFurnitureEmoji(String itemId, Map<String, dynamic> record) {
    final item = _furnitureCatalog[itemId];
    if (item?.emoji != null && item!.emoji!.isNotEmpty) {
      return item.emoji!;
    }
    final itemData = record['items'] as Map<String, dynamic>?;
    final metadata = (itemData?['metadata'] as Map?)?.cast<String, dynamic>();
    final emoji = metadata?['emoji'] as String?;
    return (emoji != null && emoji.isNotEmpty) ? emoji : '🪑';
  }

  String? _resolveFurnitureAssetPath(
    String itemId,
    Map<String, dynamic> record,
  ) {
    final catalogAssetPath = _furnitureCatalog[itemId]?.furnitureAssetPath;
    if (catalogAssetPath != null && catalogAssetPath.trim().isNotEmpty) {
      return catalogAssetPath.trim();
    }
    final itemData = record['items'] as Map<String, dynamic>?;
    final metadata = (itemData?['metadata'] as Map?)?.cast<String, dynamic>();
    final assetPath = metadata?['asset_path'] as String?;
    return (assetPath != null && assetPath.trim().isNotEmpty)
        ? assetPath.trim()
        : null;
  }

  double _clampFurnitureScale(double scale) {
    return clampRoomFurnitureScale(scale);
  }

  double _parseFurnitureScale(dynamic value) {
    if (value is num) {
      return _clampFurnitureScale(value.toDouble());
    }
    if (value is String) {
      return _clampFurnitureScale(double.tryParse(value) ?? 1.0);
    }
    return 1.0;
  }

  /// Center fraction (0..1) of a placed piece inside the fixed RoomCanvas.
  /// Prefers the authoritative canvas coord; falls back to the legacy top-left
  /// fraction for old rows (a close approximation for small items).
  Offset _canvasCenterFraction(_PlacedFurniture item) {
    final canvas = item.canvasPosition;
    if (canvas != null) {
      return canvas;
    }
    return Offset(
      item.normalizedPosition.dx.clamp(0.0, 1.0),
      item.normalizedPosition.dy.clamp(0.0, 1.0),
    );
  }

  bool _supportsBackgroundItem(ShopItem item) {
    return SharedDecorCompatibility.canRenderBackground(
      isBackground: item.isBackground,
      minAppVersion: item.minAppVersion,
      appVersion: _currentAppVersion,
      backgroundKeySupported: RoomBackgrounds.supportsKey(item.backgroundKey),
    );
  }

  bool _supportsPlacedFurniture(Map<String, dynamic>? itemData) {
    if (itemData == null) {
      return false;
    }
    final item = ShopItem.fromJson(itemData);
    return SharedDecorCompatibility.canRenderFurniture(
      isFurniture: item.isFurniture,
      minAppVersion: item.minAppVersion,
      appVersion: _currentAppVersion,
    );
  }

  Offset _positionFromNormalizedSized(
    Offset normalized,
    Size fieldSize,
    Size itemSize,
  ) {
    final maxX = max(0.0, fieldSize.width - itemSize.width);
    final maxY = max(0.0, fieldSize.height - itemSize.height);
    return Offset(normalized.dx * maxX, normalized.dy * maxY);
  }

  Map<String, dynamic>? _coerceFurnitureTransformResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return response.cast<String, dynamic>();
    }
    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return first.cast<String, dynamic>();
      }
    }
    return null;
  }

  bool _shouldFallbackToLegacyFurnitureTransform(Object error) {
    if (error is! PostgrestException) {
      return false;
    }
    final summary = [
      error.message,
      error.details,
      error.hint,
      error.code,
    ].whereType<String>().join(' ').toLowerCase();
    return summary.contains('update_room_furniture_transform') &&
        (summary.contains('does not exist') ||
            summary.contains('could not find') ||
            summary.contains('not found in schema cache'));
  }

  bool _shouldFallbackToLegacyFurniturePlacement(Object error) {
    if (error is! PostgrestException) {
      return false;
    }
    final summary = [
      error.message,
      error.details,
      error.hint,
      error.code,
    ].whereType<String>().join(' ').toLowerCase();
    return summary.contains('place_room_furniture') &&
        (summary.contains('does not exist') ||
            summary.contains('could not find') ||
            summary.contains('not found in schema cache'));
  }

  Offset? _canvasOffsetFromRow(Map<String, dynamic>? row) {
    if (row == null) {
      return null;
    }
    final x = (row['canvas_position_x'] as num?)?.toDouble();
    final y = (row['canvas_position_y'] as num?)?.toDouble();
    if (x == null || y == null) {
      return null;
    }
    return Offset(x, y);
  }
}
