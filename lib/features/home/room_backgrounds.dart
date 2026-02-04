import 'package:flutter/material.dart';

class RoomBackgroundDefinition {
  const RoomBackgroundDefinition({
    required this.key,
    required this.decoration,
    BoxDecoration? previewDecoration,
  }) : previewDecoration = previewDecoration ?? decoration;

  final String key;
  final BoxDecoration decoration;
  final BoxDecoration previewDecoration;
}

class RoomBackgrounds {
  static const String defaultKey = 'default';
  static const String testKey = 'test';

  static final Map<String, RoomBackgroundDefinition> definitions = {
    defaultKey: RoomBackgroundDefinition(
      key: defaultKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF9E5),
            Color(0xFFFFECE5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
    testKey: RoomBackgroundDefinition(
      key: testKey,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFDBF4FF),
            Color(0xFFDCCBFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      previewDecoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFDBF4FF),
            Color(0xFFDCCBFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  };

  static RoomBackgroundDefinition resolve(String? key) {
    return definitions[key] ?? definitions[defaultKey]!;
  }
}
