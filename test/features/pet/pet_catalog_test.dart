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

  test('chicken stays gated until version 2.2.6', () {
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.4'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.5'), isFalse);
    expect(PetCatalog.supportsIdOnAppVersion('chicken', '2.2.6'), isTrue);
    expect(
      PetCatalog.visiblePetsForAppVersion(
        '2.2.5',
      ).map((pet) => pet.id).contains('chicken'),
      isFalse,
    );
    expect(
      PetCatalog.resolveIdForAppVersion('chicken', appVersion: '2.2.5'),
      PetCatalog.defaultPetId,
    );
  });
}
