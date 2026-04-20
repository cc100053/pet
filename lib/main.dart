import 'dart:async';
import 'dart:isolate';

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
import 'services/crash/crash_reporting_service.dart';
import 'services/home/home_bootstrap_cache_repository.dart';
import 'services/invite/invite_link_service.dart';
import 'services/performance/performance_service.dart';
import 'services/settings/app_settings_repository.dart';
import 'features/feed/feed_upload_repository.dart';
import 'shared/force_update/crash_update_guard.dart';

RawReceivePort? _isolateErrorPort;

const int _maxImageCacheEntries = 150;
const int _maxImageCacheBytes = 192 * 1024 * 1024;

Future<void> main() async {
  runZonedGuarded(
    () async {
      final appStartTime = DateTime.now();
      WidgetsFlutterBinding.ensureInitialized();
      _configureImageCache();
      await dotenv.load(fileName: '.env');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      await CrashReportingService.instance.initialize();
      _registerIsolateErrorListener();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(
          CrashReportingService.instance.reportFlutterFatalError(
            details: details,
            source: 'flutter_error',
          ),
        );
        AppCrashSignal.instance.report(
          error: details.exception,
          stackTrace: details.stack ?? StackTrace.current,
          source: 'flutter_error',
        );
      };
      ErrorWidget.builder = (details) {
        unawaited(
          CrashReportingService.instance.reportError(
            error: details.exception,
            stackTrace: details.stack ?? StackTrace.current,
            source: 'error_widget_builder',
            fatal: true,
          ),
        );
        final stack = details.stack ?? StackTrace.current;
        AppCrashSignal.instance.report(
          error: details.exception,
          stackTrace: stack,
          source: 'error_widget',
        );
        return const SizedBox.shrink();
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          CrashReportingService.instance.reportError(
            error: error,
            stackTrace: stack,
            source: 'platform_dispatcher',
            fatal: true,
          ),
        );
        AppCrashSignal.instance.report(
          error: error,
          stackTrace: stack,
          source: 'platform_dispatcher',
        );
        return true;
      };

      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          detectSessionInUri: kIsWeb,
        ),
      );

      await Hive.initFlutter();
      await AppSettingsRepository.instance.init();
      await AppInviteLinkService.instance.initialize();
      await ChatMessageRepository.instance.init();
      await HomeBootstrapCacheRepository.instance.init();
      await FeedUploadRepository.instance.init();
      PerformanceService.instance.markAppStart(appStartTime);

      runApp(const ProviderScope(child: PicPetApp()));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceService.instance.markFirstFrameRendered();
        unawaited(AnalyticsService.instance.configureCollection());
        unawaited(
          CrashReportingService.instance.setContext(
            feature: 'app_bootstrap',
            lastAction: 'first_frame_rendered',
          ),
        );
      });
    },
    (error, stack) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: stack,
          source: 'zoned_guarded',
          fatal: true,
        ),
      );
      AppCrashSignal.instance.report(
        error: error,
        stackTrace: stack,
        source: 'zoned_guarded',
      );
    },
  );
}

void _configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = _maxImageCacheEntries;
  imageCache.maximumSizeBytes = _maxImageCacheBytes;
}

void _registerIsolateErrorListener() {
  _isolateErrorPort?.close();
  _isolateErrorPort = RawReceivePort((dynamic pair) {
    final payload = pair is List ? pair : <dynamic>[pair];
    final errorObject = payload.isNotEmpty ? payload.first : 'isolate_error';
    final stackObject = payload.length > 1 ? payload[1] : null;
    final normalizedError = errorObject is Object
        ? errorObject
        : Exception(errorObject.toString());
    final stackTrace = stackObject is StackTrace
        ? stackObject
        : StackTrace.fromString(stackObject?.toString() ?? '');
    unawaited(
      CrashReportingService.instance.reportError(
        error: normalizedError,
        stackTrace: stackTrace,
        source: 'isolate_error',
        fatal: true,
      ),
    );
    AppCrashSignal.instance.report(
      error: normalizedError,
      stackTrace: stackTrace,
      source: 'isolate_error',
    );
  });
  Isolate.current.addErrorListener(_isolateErrorPort!.sendPort);
}
