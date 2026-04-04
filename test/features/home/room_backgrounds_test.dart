import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:pet/features/home/room_backgrounds.dart';

void main() {
  test('resolves the new free and paid background keys', () {
    expect(
      RoomBackgrounds.resolve(RoomBackgrounds.sageFrameKey).key,
      RoomBackgrounds.sageFrameKey,
    );
    expect(
      RoomBackgrounds.resolve(RoomBackgrounds.lilacFrameKey).key,
      RoomBackgrounds.lilacFrameKey,
    );
    expect(
      RoomBackgrounds.resolve(RoomBackgrounds.bubbleSkyKey).key,
      RoomBackgrounds.bubbleSkyKey,
    );
    expect(
      RoomBackgrounds.resolve(RoomBackgrounds.starlitDreamKey).key,
      RoomBackgrounds.starlitDreamKey,
    );
  });

  test('marks the starlit dream background as dark', () {
    expect(
      RoomBackgrounds.resolve(RoomBackgrounds.starlitDreamKey).isDark,
      isTrue,
    );
  });

  test('uses the corrected asset paths for the new background images', () {
    final sage = RoomBackgrounds.resolve(RoomBackgrounds.sageFrameKey);
    final bubble = RoomBackgrounds.resolve(RoomBackgrounds.bubbleSkyKey);

    final sageImage = (sage.decoration.image!.image as AssetImage).assetName;
    final bubbleImage =
        (bubble.decoration.image!.image as AssetImage).assetName;

    expect(sageImage, 'assets/bg/free/background-free-01.jpg');
    expect(bubbleImage, 'assets/bg/paid/background-paid-01.jpg');
  });

  test('supports known keys and rejects unknown keys', () {
    expect(RoomBackgrounds.supportsKey(RoomBackgrounds.sageFrameKey), isTrue);
    expect(RoomBackgrounds.supportsKey('future_background'), isFalse);
  });
}
