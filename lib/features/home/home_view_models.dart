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
  });

  final String latestImageUrl;
  final String? latestCaption;
  final String? latestSenderId;
  final List<String> imageUrls;
  final List<String?> imageCaptions;
  final List<String?> imageSenderIds;
  final List<DateTime?> imageSentAts;
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

class _PlacedFurniture {
  _PlacedFurniture({
    required this.id,
    required this.itemId,
    required this.ownerUserId,
    required this.emoji,
    required this.normalizedPosition,
    required this.isPending,
  });

  String id;
  String itemId;
  String? ownerUserId;
  String emoji;
  Offset normalizedPosition;
  bool isPending;
}

class _PoopSpot {
  const _PoopSpot({required this.index, required this.normalized});

  final int index;
  final Offset normalized;
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
