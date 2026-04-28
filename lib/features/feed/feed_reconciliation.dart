const Duration kFeedClientCreatedAtTolerance = Duration(seconds: 2);
const Duration kFeedServerCreatedAtTolerance = Duration(seconds: 45);

String normalizeFeedCaption(String? caption) => caption?.trim() ?? '';

DateTime? parseFeedDate(dynamic value) {
  if (value is DateTime) {
    return value.toUtc();
  }
  if (value is String) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}

bool matchesFeedIdentity({
  required String expectedRoomId,
  required String? expectedSenderId,
  required String? expectedCaption,
  required DateTime expectedClientCreatedAt,
  String? expectedMessageId,
  required String roomId,
  required String? senderId,
  required String? caption,
  String? messageId,
  DateTime? clientCreatedAt,
  DateTime? createdAt,
  Duration clientCreatedAtTolerance = kFeedClientCreatedAtTolerance,
  Duration serverCreatedAtTolerance = kFeedServerCreatedAtTolerance,
}) {
  if (roomId != expectedRoomId || senderId != expectedSenderId) {
    return false;
  }
  if (normalizeFeedCaption(caption) != normalizeFeedCaption(expectedCaption)) {
    return false;
  }

  final expectedId = expectedMessageId?.trim();
  final incomingId = messageId?.trim();
  if (expectedId != null &&
      expectedId.isNotEmpty &&
      incomingId != null &&
      incomingId.isNotEmpty) {
    return expectedId == incomingId;
  }

  final expectedClientAt = expectedClientCreatedAt.toUtc();
  final incomingClientAt = clientCreatedAt?.toUtc();
  if (incomingClientAt != null) {
    return incomingClientAt.difference(expectedClientAt).abs() <=
        clientCreatedAtTolerance;
  }

  final incomingCreatedAt = createdAt?.toUtc();
  if (incomingCreatedAt != null) {
    return incomingCreatedAt.difference(expectedClientAt).abs() <=
        serverCreatedAtTolerance;
  }

  return false;
}
