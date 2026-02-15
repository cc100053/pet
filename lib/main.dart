import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'services/chat/chat_message_repository.dart';
import 'services/env.dart';
import 'services/analytics/analytics_service.dart';
import 'services/home/home_bootstrap_cache_repository.dart';
import 'services/performance/performance_service.dart';
import 'services/settings/app_settings_repository.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      final appStartTime = DateTime.now();
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: '.env');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await AnalyticsService.instance.configureCollection();

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
      );

      await Hive.initFlutter();
      await AppSettingsRepository.instance.init();
      await ChatMessageRepository.instance.init();
      await HomeBootstrapCacheRepository.instance.init();
      PerformanceService.instance.markAppStart(appStartTime);

      runApp(const ProviderScope(child: PicPetApp()));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceService.instance.markFirstFrameRendered();
      });
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
