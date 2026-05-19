part of 'home_view.dart';

class _RoomLatestFeed {
  _RoomLatestFeed({
    required this.latestImageUrl,
    required this.latestCaption,
    required this.latestSenderId,
    required this.imageUrls,
    required this.imageCaptions,
    required this.imageSenderIds,
    required this.imageSentAts,
    required this.imageMessageIds,
  });

  final String latestImageUrl;
  final String? latestCaption;
  final String? latestSenderId;
  final List<String> imageUrls;
  final List<String?> imageCaptions;
  final List<String?> imageSenderIds;
  final List<DateTime?> imageSentAts;
  final List<String?> imageMessageIds;
}

class _RoomPetSummary {
  const _RoomPetSummary({
    required this.petType,
    required this.healthValue,
    required this.petName,
    required this.petLevel,
  });

  final String petType;
  final double healthValue;
  final String? petName;
  final int? petLevel;
}

class _RoomPet {
  const _RoomPet({
    required this.petId,
    required this.petType,
    required this.isMain,
  });

  final String petId;
  final String petType;
  final bool isMain;
}

class _PlacedFurniture {
  _PlacedFurniture({
    required this.id,
    required this.itemId,
    required this.ownerUserId,
    required this.emoji,
    required this.assetPath,
    required this.normalizedPosition,
    required this.persistedNormalizedPosition,
    required this.scale,
    required this.persistedScale,
    required this.flipX,
    required this.persistedFlipX,
    required this.isPending,
  });

  String id;
  String itemId;
  String? ownerUserId;
  String emoji;
  String? assetPath;
  Offset normalizedPosition;
  Offset persistedNormalizedPosition;
  double scale;
  double persistedScale;
  bool flipX;
  bool persistedFlipX;
  bool isPending;
}

class _PoopSpot {
  const _PoopSpot({required this.index, required this.normalized});

  final int index;
  final Offset normalized;
}

class _EquippedPetItem {
  const _EquippedPetItem({required this.itemId, required this.sku});

  final String itemId;
  final String sku;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
