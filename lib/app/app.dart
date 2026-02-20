import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../features/auth/auth_gate.dart';
import '../shared/localization/app_locale_controller.dart';
import '../shared/theme/app_theme.dart';
import '../shared/ui/app_ui_scale.dart';
import '../shared/ui/status_bar_style.dart';
import '../shared/force_update/force_update_gate.dart';

class PicPetApp extends ConsumerWidget {
  const PicPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(appLocaleProvider);
    return AnnotatedRegion(
      value: AppStatusBarStyles.light,
      child: MaterialApp(
        title: 'PicPet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: localeState.locale,
        localeResolutionCallback: (locale, supportedLocales) {
          if (locale == null) {
            return supportedLocales.first;
          }
          if (locale.languageCode == 'zh') {
            final scriptCode = locale.scriptCode?.toLowerCase();
            final countryCode = locale.countryCode?.toUpperCase();
            if (scriptCode == 'hant' ||
                countryCode == 'TW' ||
                countryCode == 'HK' ||
                countryCode == 'MO') {
              return const Locale('zh', 'TW');
            }
            return const Locale('zh');
          }
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
          return supportedLocales.first;
        },
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final scale = appUiScale(mediaQuery.size.width);
          if (child == null || (scale - 1.0).abs() < 0.001) {
            return child ?? const SizedBox.shrink();
          }
          final theme = Theme.of(context);
          final scaledTheme = theme.copyWith(
            textTheme: theme.textTheme.apply(fontSizeFactor: scale),
            primaryTextTheme: theme.primaryTextTheme.apply(
              fontSizeFactor: scale,
            ),
            iconTheme: theme.iconTheme.copyWith(
              size: (theme.iconTheme.size ?? 24) * scale,
            ),
          );
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
            child: Theme(data: scaledTheme, child: child),
          );
        },
        home: const ForceUpdateGate(child: AuthGate()),
      ),
    );
  }
}
