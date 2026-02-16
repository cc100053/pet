import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../services/settings/app_settings_repository.dart';

enum AppLanguageOption {
  system,
  english,
  japanese,
  korean,
  chineseSimplified,
  chineseTraditional,
}

class AppLocaleState {
  const AppLocaleState({required this.option, required this.locale});

  final AppLanguageOption option;
  final Locale? locale;
}

final appLocaleProvider =
    StateNotifierProvider<AppLocaleController, AppLocaleState>(
      (ref) => AppLocaleController(AppSettingsRepository.instance),
    );

class AppLocaleController extends StateNotifier<AppLocaleState> {
  AppLocaleController(this._settings)
    : super(
        AppLocaleState(
          option: _optionFromTag(_settings.preferredLocaleTag),
          locale: _localeFromTag(_settings.preferredLocaleTag),
        ),
      );

  final AppSettingsRepository _settings;

  Future<void> setOption(AppLanguageOption option) async {
    final tag = _tagFromOption(option);
    await _settings.setPreferredLocaleTag(tag);
    state = AppLocaleState(option: option, locale: _localeFromTag(tag));
  }

  static AppLanguageOption _optionFromTag(String? tag) {
    switch (tag) {
      case 'en':
        return AppLanguageOption.english;
      case 'ja':
        return AppLanguageOption.japanese;
      case 'ko':
        return AppLanguageOption.korean;
      case 'zh-CN':
      case 'zh-Hans':
      case 'zh':
        return AppLanguageOption.chineseSimplified;
      case 'zh-TW':
      case 'zh-Hant':
        return AppLanguageOption.chineseTraditional;
      default:
        return AppLanguageOption.system;
    }
  }

  static Locale? _localeFromTag(String? tag) {
    switch (tag) {
      case 'en':
        return const Locale('en');
      case 'ja':
        return const Locale('ja');
      case 'ko':
        return const Locale('ko');
      case 'zh-CN':
      case 'zh-Hans':
      case 'zh':
        return const Locale('zh');
      case 'zh-TW':
      case 'zh-Hant':
        return const Locale('zh', 'TW');
      default:
        return null;
    }
  }

  static String? _tagFromOption(AppLanguageOption option) {
    switch (option) {
      case AppLanguageOption.system:
        return null;
      case AppLanguageOption.english:
        return 'en';
      case AppLanguageOption.japanese:
        return 'ja';
      case AppLanguageOption.korean:
        return 'ko';
      case AppLanguageOption.chineseSimplified:
        return 'zh-Hans';
      case AppLanguageOption.chineseTraditional:
        return 'zh-TW';
    }
  }
}
