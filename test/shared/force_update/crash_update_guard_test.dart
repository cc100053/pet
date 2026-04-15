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
}

Widget _buildApp(Widget child, {required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
