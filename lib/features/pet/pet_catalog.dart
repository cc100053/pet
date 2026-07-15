import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../shared/compatibility/shared_decor_compatibility.dart';
import '../../shared/theme/app_theme.dart';

class PetDefinition {
  const PetDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.stayAsset,
    required this.sleepAsset,
    required this.walkAsset,
    required this.accent,
    required this.gradient,
    this.isStarter = false,
    this.minAppVersion,
  });

  final String id;
  final String Function(AppLocalizations) name;
  final String Function(AppLocalizations) tagline;
  final String stayAsset;
  final String sleepAsset;
  final String walkAsset;
  final Color accent;
  final LinearGradient gradient;
  final bool isStarter;
  final String? minAppVersion;

  bool isSupportedOnAppVersion(String? appVersion) {
    return SharedDecorCompatibility.supportsAppVersion(
      minAppVersion: minAppVersion,
      appVersion: appVersion,
    );
  }
}

class PetCatalog {
  static const String colorDnaTypeKey = 'pet_type';
  static const String defaultPetId = 'ghost';

  static final List<PetDefinition> pets = [
    PetDefinition(
      id: defaultPetId,
      name: (l10n) => l10n.petTypeGhostName,
      tagline: (l10n) => l10n.petTypeGhostTagline,
      stayAsset: 'assets/pet/ghost/ghost_stay.gif',
      sleepAsset: 'assets/pet/ghost/ghost_sleep.gif',
      walkAsset: 'assets/pet/ghost/ghost_walking.gif',
      accent: AppTheme.primaryColor,
      gradient: AppTheme.primaryGradient,
      isStarter: true,
    ),
    PetDefinition(
      id: 'cat',
      name: (l10n) => l10n.petTypeCatName,
      tagline: (l10n) => l10n.petTypeCatTagline,
      stayAsset: 'assets/pet/cat/cat_stay.gif',
      sleepAsset: 'assets/pet/cat/cat_sleep.gif',
      walkAsset: 'assets/pet/cat/cat_moving.gif',
      accent: AppTheme.secondaryColor,
      gradient: const LinearGradient(
        colors: [Color(0xFFFFC27A), Color(0xFFFF9F68)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    PetDefinition(
      id: 'fish',
      name: (l10n) => l10n.petTypeFishName,
      tagline: (l10n) => l10n.petTypeFishTagline,
      stayAsset: 'assets/pet/fish/fish_stay.gif',
      sleepAsset: 'assets/pet/fish/fish_sleep.gif',
      walkAsset: 'assets/pet/fish/fish_moving.gif',
      accent: const Color(0xFF4FB8D9),
      gradient: const LinearGradient(
        colors: [Color(0xFF6ED1F2), Color(0xFF4FB8D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    PetDefinition(
      id: 'tiger',
      name: (l10n) => l10n.petTypeTigerName,
      tagline: (l10n) => l10n.petTypeTigerTagline,
      stayAsset: 'assets/pet/tiger/tiger_stay.gif',
      sleepAsset: 'assets/pet/tiger/tiger_sleep.gif',
      walkAsset: 'assets/pet/tiger/tiger_moving.gif',
      accent: const Color(0xFFDE8B37),
      gradient: const LinearGradient(
        colors: [Color(0xFFF7C86B), Color(0xFFDE8B37)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      minAppVersion: '1.1.0',
    ),
    PetDefinition(
      id: 'chicken',
      name: (l10n) => l10n.petTypeChickenName,
      tagline: (l10n) => l10n.petTypeChickenTagline,
      stayAsset: 'assets/pet_sequences/chicken/chicken-stay/chicken-stay.gif',
      sleepAsset:
          'assets/pet_sequences/chicken/chicken-sleep/chicken-sleep.gif',
      walkAsset:
          'assets/pet_sequences/chicken/chicken-moving/chicken-moving.gif',
      accent: const Color(0xFF8A5A32),
      gradient: const LinearGradient(
        colors: [Color(0xFFD7A66A), Color(0xFF8A5A32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      minAppVersion: '2.2.6',
    ),
  ];

  static PetDefinition? _byIdOrNull(String? id) {
    if (id == null) {
      return null;
    }
    for (final pet in pets) {
      if (pet.id == id) {
        return pet;
      }
    }
    return null;
  }

  static PetDefinition byId(String? id) {
    return _byIdOrNull(id) ?? pets.first;
  }

  static String resolveId(String? id) {
    return byId(id).id;
  }

  static bool supportsIdOnAppVersion(String? id, String? appVersion) {
    final pet = _byIdOrNull(id);
    return SharedDecorCompatibility.canRenderPet(
      petExists: pet != null,
      minAppVersion: pet?.minAppVersion,
      appVersion: appVersion,
    );
  }

  static PetDefinition byIdForAppVersion(String? id, {String? appVersion}) {
    final pet = _byIdOrNull(id);
    if (pet == null) {
      return pets.first;
    }
    if (!pet.isSupportedOnAppVersion(appVersion)) {
      return pets.first;
    }
    return pet;
  }

  static String resolveIdForAppVersion(String? id, {String? appVersion}) {
    return byIdForAppVersion(id, appVersion: appVersion).id;
  }

  static List<PetDefinition> visiblePetsForAppVersion(String? appVersion) {
    return pets
        .where((pet) => pet.isSupportedOnAppVersion(appVersion))
        .toList(growable: false);
  }

  static String? typeFromColorDna(Object? colorDna) {
    if (colorDna is Map) {
      final value = colorDna[colorDnaTypeKey];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static List<String> assetPaths(PetDefinition pet) {
    return [pet.stayAsset, pet.sleepAsset, pet.walkAsset];
  }
}
