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
}
