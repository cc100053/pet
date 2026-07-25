import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/force_update/crash_update_guard.dart';

void main() {
  setUp(AppCrashSignal.instance.reset);
  tearDown(AppCrashSignal.instance.reset);

  testWidgets('crash fallback shows recovery copy instead of update copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        const CrashUpdateGuard(child: Text('Game home')),
        locale: const Locale('zh', 'TW'),
      ),
    );

    expect(find.text('Game home'), findsOneWidget);

    AppCrashSignal.instance.report(
      error: StateError('boom'),
      stackTrace: StackTrace.current,
      source: 'test_crash',
    );
    await tester.pumpAndSettle();

    expect(find.text('遊戲發生錯誤'), findsOneWidget);
    expect(
      find.text('遊戲剛才似乎異常中斷，請關閉 App 後重新開啟再試一次。若問題持續，請稍後再試。'),
      findsOneWidget,
    );
    expect(find.text('小寵物先陪你休息一下。'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('需要更新'), findsNothing);
    expect(find.text('立即更新'), findsNothing);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    expect(find.text('Game home'), findsOneWidget);
    expect(find.text('遊戲發生錯誤'), findsNothing);
  });

  testWidgets('retryable network errors do not replace the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        const CrashUpdateGuard(child: Text('Game home')),
        locale: const Locale('zh', 'TW'),
      ),
    );

    AppCrashSignal.instance.report(
      error: Exception(
        'ClientException with SocketException: Operation timed out '
        '(OS Error: Operation timed out, errno = 60), '
        'uri=https://ilxzpszgirhwxpeocygs.supabase.co/rest/v1/rpc/'
        'tick_pet_state',
      ),
      stackTrace: StackTrace.current,
      source: 'flutter_error',
    );
    await tester.pumpAndSettle();

    expect(find.text('Game home'), findsOneWidget);
    expect(find.text('遊戲發生錯誤'), findsNothing);
  });

  testWidgets(
    'reporting during a build/layout pass defers the recovery swap to a '
    'clean build scope',
    (tester) async {
      // Reproduces the crash path: ErrorWidget.builder / FlutterError.onError
      // call report() while a build/layout pass is in progress. Mutating the
      // notifier synchronously there would swap the live subtree mid-frame and
      // trip "wrong build scope" / InheritedElement `_dependents.isEmpty`.
      await tester.pumpWidget(
        _buildApp(
          CrashUpdateGuard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Establish an inherited dependency in the subtree, then report
                // while still inside the build phase.
                MediaQuery.of(context);
                AppCrashSignal.instance.report(
                  error: StateError('boom during build'),
                  stackTrace: StackTrace.current,
                  source: 'error_widget_builder',
                );
                return const Text('Game home');
              },
            ),
          ),
          locale: const Locale('zh', 'TW'),
        ),
      );

      // The swap is deferred: the original subtree finished its frame cleanly.
      expect(tester.takeException(), isNull);
      expect(find.text('Game home'), findsOneWidget);

      // The deferred post-frame callback swaps in the recovery screen safely.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('遊戲發生錯誤'), findsOneWidget);
    },
  );
}

Widget _buildApp(Widget child, {required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
