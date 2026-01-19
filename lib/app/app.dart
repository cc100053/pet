import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../features/auth/auth_gate.dart';
import '../shared/localization/app_locale_controller.dart';
import '../shared/force_update/force_update_gate.dart';

class PicPetApp extends ConsumerWidget {
  const PicPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(appLocaleProvider);
    return MaterialApp(
      title: 'PicPet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeState.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return supportedLocales.first;
        }
        if (locale.languageCode == 'zh') {
          return const Locale('zh', 'TW');
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
      home: const ForceUpdateGate(child: AuthGate()),
    );
  }
}
