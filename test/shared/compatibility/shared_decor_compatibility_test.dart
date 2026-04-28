import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/compatibility/shared_decor_compatibility.dart';

void main() {
  group('SharedDecorCompatibility', () {
    test('supports ungated shared items for unknown and old app versions', () {
      expect(
        SharedDecorCompatibility.supportsAppVersion(
          minAppVersion: null,
          appVersion: null,
        ),
        isTrue,
      );
      expect(
        SharedDecorCompatibility.supportsAppVersion(
          minAppVersion: '',
          appVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('gates shared items by minimum app version', () {
      expect(
        SharedDecorCompatibility.supportsAppVersion(
          minAppVersion: '1.1.0',
          appVersion: null,
        ),
        isFalse,
      );
      expect(
        SharedDecorCompatibility.supportsAppVersion(
          minAppVersion: '1.1.0',
          appVersion: '1.0.9',
        ),
        isFalse,
      );
      expect(
        SharedDecorCompatibility.supportsAppVersion(
          minAppVersion: '1.1.0',
          appVersion: '1.1.0',
        ),
        isTrue,
      );
    });

    test('requires known background key and supported app version', () {
      expect(
        SharedDecorCompatibility.canRenderBackground(
          isBackground: true,
          minAppVersion: '1.1.0',
          appVersion: '1.1.0',
          backgroundKeySupported: true,
        ),
        isTrue,
      );
      expect(
        SharedDecorCompatibility.canRenderBackground(
          isBackground: true,
          minAppVersion: '1.1.0',
          appVersion: '1.0.9',
          backgroundKeySupported: true,
        ),
        isFalse,
      );
      expect(
        SharedDecorCompatibility.canRenderBackground(
          isBackground: true,
          minAppVersion: null,
          appVersion: '1.1.0',
          backgroundKeySupported: false,
        ),
        isFalse,
      );
    });

    test('requires furniture category and supported app version', () {
      expect(
        SharedDecorCompatibility.canRenderFurniture(
          isFurniture: true,
          minAppVersion: '1.1.2',
          appVersion: '1.1.2',
        ),
        isTrue,
      );
      expect(
        SharedDecorCompatibility.canRenderFurniture(
          isFurniture: true,
          minAppVersion: '1.1.2',
          appVersion: '1.1.1',
        ),
        isFalse,
      );
      expect(
        SharedDecorCompatibility.canRenderFurniture(
          isFurniture: false,
          minAppVersion: null,
          appVersion: '1.1.2',
        ),
        isFalse,
      );
    });

    test('requires known pet and supported app version', () {
      expect(
        SharedDecorCompatibility.canRenderPet(
          petExists: true,
          minAppVersion: '1.1.0',
          appVersion: '1.1.0',
        ),
        isTrue,
      );
      expect(
        SharedDecorCompatibility.canRenderPet(
          petExists: true,
          minAppVersion: '1.1.0',
          appVersion: '1.0.9',
        ),
        isFalse,
      );
      expect(
        SharedDecorCompatibility.canRenderPet(
          petExists: false,
          minAppVersion: null,
          appVersion: '1.1.0',
        ),
        isFalse,
      );
    });

    test('derives room compatibility prompt state and stable key', () {
      final state = SharedDecorCompatibility.promptState(
        unsupportedPetType: 'tiger',
        unsupportedBackgroundItemIds: {'background-a'},
        activeBackgroundItemId: 'background-a',
        unsupportedPlacedFurnitureCount: 2,
      );

      expect(state.shouldPrompt, isTrue);
      expect(state.hasUnsupportedPet, isTrue);
      expect(state.hasUnsupportedBackground, isTrue);
      expect(state.hasUnsupportedFurniture, isTrue);
      expect(
        state.keyFor(roomId: 'room-a', appVersion: '1.0.9'),
        'room-a:1.0.9:pet:bg:furniture',
      );
    });

    test('does not prompt for inactive unsupported background ownership', () {
      final state = SharedDecorCompatibility.promptState(
        unsupportedPetType: null,
        unsupportedBackgroundItemIds: {'background-a'},
        activeBackgroundItemId: 'background-b',
        unsupportedPlacedFurnitureCount: 0,
      );

      expect(state.shouldPrompt, isFalse);
      expect(
        state.keyFor(roomId: 'room-a', appVersion: null),
        'room-a:unknown:no-pet:no-bg:no-furniture',
      );
    });
  });
}
