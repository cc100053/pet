import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_catalog.dart';

void main() {
  test('version-gated pets stay hidden until the minimum app version', () {
    expect(
      PetCatalog.visiblePetsForAppVersion(
        '1.0.9',
      ).map((pet) => pet.id).contains('tiger'),
      isFalse,
    );
    expect(
      PetCatalog.visiblePetsForAppVersion(
        '1.1.0',
      ).map((pet) => pet.id).contains('tiger'),
      isTrue,
    );
  });

  test('unsupported shared pet types fall back to the default pet', () {
    expect(
      PetCatalog.resolveIdForAppVersion('tiger', appVersion: '1.0.9'),
      PetCatalog.defaultPetId,
    );
    expect(
      PetCatalog.resolveIdForAppVersion('tiger', appVersion: '1.1.0'),
      'tiger',
    );
  });

  test('chicken stays gated until version 2.3.0', () {
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.4'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.5'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.6'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.7'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.9'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.3.0'), isTrue);
    expect(
      PetCatalog.visiblePetsForAppVersion(
        '2.2.9',
      ).map((pet) => pet.id).contains('chicken'),
      isFalse,
    );
    expect(
      PetCatalog.resolveIdForAppVersion('chicken', appVersion: '2.2.9'),
      PetCatalog.defaultPetId,
    );
  });

  test('turtle stays gated until version 5.0.0', () {
    expect(PetCatalog.supportsIdOnAppVersion('turtle', '4.1.0'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('turtle', '4.9.9'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('turtle', '5.0.0'), isTrue);
    expect(
      PetCatalog.visiblePetsForAppVersion(
        '4.1.0',
      ).map((pet) => pet.id).contains('turtle'),
      isFalse,
    );
    expect(
      PetCatalog.visiblePetsForAppVersion(
        '5.0.0',
      ).map((pet) => pet.id).contains('turtle'),
      isTrue,
    );
    expect(
      PetCatalog.resolveIdForAppVersion('turtle', appVersion: '4.1.0'),
      PetCatalog.defaultPetId,
    );
  });
}
