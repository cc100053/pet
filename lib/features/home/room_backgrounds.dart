import 'package:flutter/material.dart';

class RoomBackgroundDefinition {
  const RoomBackgroundDefinition({
    required this.key,
    required this.decoration,
    this.isDark = false,
    BoxDecoration? previewDecoration,
  }) : previewDecoration = previewDecoration ?? decoration;

  final String key;
  final BoxDecoration decoration;
  final BoxDecoration previewDecoration;
  final bool isDark;
}

class RoomBackgrounds {
  static const String defaultKey = 'default';
  static const String testKey = 'test';
  static const String test1Key = 'test1';
  static const String sageFrameKey = 'sage_frame';
  static const String lilacFrameKey = 'lilac_frame';
  static const String bubbleSkyKey = 'bubble_sky';
  static const String starlitDreamKey = 'starlit_dream';

  static final Map<String, RoomBackgroundDefinition> definitions = {
    defaultKey: RoomBackgroundDefinition(
      key: defaultKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF9E5), Color(0xFFFFECE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    testKey: RoomBackgroundDefinition(
      key: testKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBF4FF), Color(0xFFDCCBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      previewDecoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDBF4FF), Color(0xFFDCCBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    test1Key: RoomBackgroundDefinition(
      key: test1Key,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg/test1.png'),
          fit: BoxFit.cover,
        ),
      ),
      isDark: true,
    ),
    sageFrameKey: RoomBackgroundDefinition(
      key: sageFrameKey,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg/free/backgound-free-01.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    lilacFrameKey: RoomBackgroundDefinition(
      key: lilacFrameKey,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg/free/backgound-free-02.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    bubbleSkyKey: RoomBackgroundDefinition(
      key: bubbleSkyKey,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg/paid/backgounr-Paid-01.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    starlitDreamKey: RoomBackgroundDefinition(
      key: starlitDreamKey,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg/paid/backgound-Paid-02.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      isDark: true,
    ),
  };

  static bool supportsKey(String? key) {
    if (key == null || key.isEmpty) {
      return true;
    }
    return definitions.containsKey(key);
  }

  static RoomBackgroundDefinition resolve(String? key) {
    return definitions[key] ?? definitions[defaultKey]!;
  }
}
