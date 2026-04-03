import 'package:flutter_test/flutter_test.dart';
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

  test('supports known keys and rejects unknown keys', () {
    expect(RoomBackgrounds.supportsKey(RoomBackgrounds.sageFrameKey), isTrue);
    expect(RoomBackgrounds.supportsKey('future_background'), isFalse);
  });
}
