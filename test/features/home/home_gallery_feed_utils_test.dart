import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/home_gallery_feed_utils.dart';

void main() {
  group('PetHomeGalleryFeedData', () {
    test('truncates prepended feeds to 10 items', () {
      var data = const PetHomeGalleryFeedData.empty();
      for (var i = 0; i < 10; i++) {
        data = data.prependEntry(
          imageUrl: 'https://example.com/$i.jpg',
          caption: 'caption $i',
          senderId: 'sender-$i',
          sentAt: DateTime.utc(2026, 3, 12, 0, i),
        );
      }

      final next = data.prependEntry(
        imageUrl: 'https://example.com/latest.jpg',
        caption: 'latest',
        senderId: 'sender-latest',
        sentAt: DateTime.utc(2026, 3, 12, 1),
      );

      expect(next.imageUrls, hasLength(kPetHomeGalleryMaxPhotos));
      expect(next.imageUrls.first, 'https://example.com/latest.jpg');
      expect(next.imageUrls, isNot(contains('https://example.com/0.jpg')));
    });

    test('reconciles optimistic local image with canonical remote image', () {
      final pending = PendingPetHomeOptimisticFeed(
        tempId: 'temp-1',
        roomId: 'room-1',
        senderId: 'user-1',
        localImagePath: '/tmp/local.jpg',
        caption: 'Dinner',
        clientCreatedAt: DateTime.utc(2026, 3, 12, 12),
      );
      final existing = const PetHomeGalleryFeedData.empty()
          .prependEntry(
            imageUrl: 'https://example.com/older.jpg',
            caption: 'Older',
            senderId: 'user-2',
            sentAt: DateTime.utc(2026, 3, 11, 12),
          )
          .prependEntry(
            imageUrl: pending.localImagePath,
            caption: pending.caption,
            senderId: pending.senderId,
            sentAt: pending.clientCreatedAt,
          );

      final reconciled = existing.reconcilePendingRealtime(
        pending: pending,
        roomId: 'room-1',
        imageUrl: 'https://example.com/remote.jpg',
        caption: 'Dinner',
        senderId: 'user-1',
        messageId: 'message-1',
        clientCreatedAt: pending.clientCreatedAt,
        createdAt: pending.clientCreatedAt.add(const Duration(seconds: 1)),
      );

      expect(reconciled.matchedPending, isTrue);
      expect(
        reconciled.data.imageUrls,
        equals([
          'https://example.com/remote.jpg',
          'https://example.com/older.jpg',
        ]),
      );
      expect(
        reconciled.data.imageUrls,
        isNot(contains(pending.localImagePath)),
      );
    });

    test('stores 10 gallery items in room snapshots', () {
      final snapshot = <String, dynamic>{
        'id': 'room-1',
        'latest_photo': 'https://example.com/0.jpg',
        'latest_photos': List<String>.generate(
          12,
          (index) => 'https://example.com/$index.jpg',
        ),
        'latest_photo_captions': List<String?>.generate(
          12,
          (index) => 'caption $index',
        ),
        'latest_photo_sender_ids': List<String?>.generate(
          12,
          (index) => 'sender-$index',
        ),
        'latest_photo_created_ats': List<String>.generate(
          12,
          (index) => DateTime.utc(2026, 3, 12, 0, index).toIso8601String(),
        ),
        'latest_caption': 'caption 0',
        'latest_sender_id': 'sender-0',
      };

      final data = PetHomeGalleryFeedData.fromRoomSnapshot(snapshot);
      final applied = data.applyToRoomSnapshot(snapshot);

      expect(data.imageUrls, hasLength(kPetHomeGalleryMaxPhotos));
      expect(applied['latest_photos'], hasLength(kPetHomeGalleryMaxPhotos));
      expect(applied['latest_photo'], 'https://example.com/0.jpg');
    });
  });

  test('compact summary photo urls remain capped at 3 items', () {
    final compact = compactSummaryPhotoUrls(
      List<String>.generate(10, (index) => 'https://example.com/$index.jpg'),
    );

    expect(compact, hasLength(kHomeSummaryPhotoPreviewMaxPhotos));
    expect(
      compact,
      equals([
        'https://example.com/0.jpg',
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]),
    );
  });
}
