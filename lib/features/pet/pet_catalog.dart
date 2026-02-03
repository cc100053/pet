import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

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
  ];

  static PetDefinition byId(String? id) {
    if (id == null) {
      return pets.first;
    }
    for (final pet in pets) {
      if (pet.id == id) {
        return pet;
      }
    }
    return pets.first;
  }

  static String resolveId(String? id) {
    return byId(id).id;
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
