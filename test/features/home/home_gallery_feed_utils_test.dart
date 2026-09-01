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
          messageId: 'message-$i',
        );
      }

      final next = data.prependEntry(
        imageUrl: 'https://example.com/latest.jpg',
        caption: 'latest',
        senderId: 'sender-latest',
        sentAt: DateTime.utc(2026, 3, 12, 1),
        messageId: 'message-latest',
      );

      expect(next.imageUrls, hasLength(kPetHomeGalleryMaxPhotos));
      expect(next.imageUrls.first, 'https://example.com/latest.jpg');
      expect(next.messageIds.first, 'message-latest');
      expect(next.imageUrls, isNot(contains('https://example.com/0.jpg')));
    });

    test('removeByMessageId drops the recalled photo and keeps the rest', () {
      var data = const PetHomeGalleryFeedData.empty();
      for (var i = 0; i < 3; i++) {
        data = data.prependEntry(
          imageUrl: 'https://example.com/$i.jpg',
          caption: 'caption $i',
          senderId: 'sender-$i',
          sentAt: DateTime.utc(2026, 5, 21, 0, i),
          messageId: 'message-$i',
        );
      }

      final next = data.removeByMessageId('message-1');

      expect(next.messageIds, isNot(contains('message-1')));
      expect(next.imageUrls, isNot(contains('https://example.com/1.jpg')));
      expect(next.messageIds, hasLength(2));
      expect(next.messageIds, containsAll(<String>['message-0', 'message-2']));
      // Unknown ids leave the data untouched.
      expect(identical(next.removeByMessageId('missing'), next), isTrue);
    });

    test('updateCaptionByMessageId rewrites only the edited photo', () {
      var data = const PetHomeGalleryFeedData.empty();
      for (var i = 0; i < 3; i++) {
        data = data.prependEntry(
          imageUrl: 'https://example.com/$i.jpg',
          caption: 'caption $i',
          senderId: 'sender-$i',
          sentAt: DateTime.utc(2026, 9, 1, 0, i),
          messageId: 'message-$i',
        );
      }

      final next = data.updateCaptionByMessageId('message-1', 'edited');

      expect(next.messageIds, data.messageIds);
      expect(next.imageUrls, data.imageUrls);
      expect(next.captions[next.messageIds.indexOf('message-1')], 'edited');
      expect(next.captions[next.messageIds.indexOf('message-2')], 'caption 2');
      // The newest photo's caption drives the room card preview line.
      expect(
        data.updateCaptionByMessageId('message-2', 'newest').latestCaption,
        'newest',
      );
      // Unknown ids leave the data untouched.
      expect(
        identical(next.updateCaptionByMessageId('missing', 'x'), next),
        isTrue,
      );
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
            messageId: 'message-older',
          )
          .prependEntry(
            imageUrl: pending.localImagePath,
            caption: pending.caption,
            senderId: pending.senderId,
            sentAt: pending.clientCreatedAt,
            messageId: null,
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
      expect(reconciled.data.messageIds.first, 'message-1');
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
        'latest_photo_message_ids': List<String?>.generate(
          12,
          (index) => 'message-$index',
        ),
        'latest_caption': 'caption 0',
        'latest_sender_id': 'sender-0',
      };

      final data = PetHomeGalleryFeedData.fromRoomSnapshot(snapshot);
      final applied = data.applyToRoomSnapshot(snapshot);

      expect(data.imageUrls, hasLength(kPetHomeGalleryMaxPhotos));
      expect(data.messageIds.first, 'message-0');
      expect(applied['latest_photos'], hasLength(kPetHomeGalleryMaxPhotos));
      expect(
        applied['latest_photo_message_ids'],
        hasLength(kPetHomeGalleryMaxPhotos),
      );
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
