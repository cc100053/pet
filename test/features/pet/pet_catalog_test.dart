import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_catalog.dart';

void main() {
  test(
    'gingerbread man is selectable only from 5.1.0 with old-room fallback',
    () {
      for (final version in <String?>[null, '4.1.0', '5.0.0', '5.0.9']) {
        expect(
          PetCatalog.supportsIdOnAppVersion('gingerbread_man', version),
          isFalse,
        );
        expect(
          PetCatalog.visiblePetsForAppVersion(version).map((pet) => pet.id),
          isNot(contains('gingerbread_man')),
        );
        expect(
          PetCatalog.resolveIdForAppVersion(
            'gingerbread_man',
            appVersion: version,
          ),
          PetCatalog.defaultPetId,
        );
      }
      for (final version in ['5.1.0', '5.2.0']) {
        expect(
          PetCatalog.supportsIdOnAppVersion('gingerbread_man', version),
          isTrue,
        );
        expect(
          PetCatalog.visiblePetsForAppVersion(version).map((pet) => pet.id),
          contains('gingerbread_man'),
        );
        expect(
          PetCatalog.resolveIdForAppVersion(
            'gingerbread_man',
            appVersion: version,
          ),
          'gingerbread_man',
        );
      }
    },
  );

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
