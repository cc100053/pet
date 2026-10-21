import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet/features/auth/auth_gate.dart';
import 'package:pet/features/onboarding/onboarding_entry_view.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/fcm_service.dart';
import 'package:pet/shared/force_update/crash_update_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoPush extends FCMService {
  @override
  Future<void> initialize({bool askIfUndecided = false}) async {}

  @override
  Future<void> refreshTokenSync() async {}
}

Future<void> _pumpGate(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fcmServiceProvider.overrideWithValue(_NoPush())],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CrashUpdateGuard(child: AuthGate()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AppCrashSignal.instance.reset();
    await Supabase.initialize(
      url: 'https://example.invalid',
      anonKey: 'test-anon-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
      ),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'refresh_token_already_used',
            'msg': 'Invalid Refresh Token: Already Used',
          }),
          400,
          headers: {'x-supabase-api-version': '2024-01-01'},
        ),
      ),
    );
  });

  tearDown(() async {
    await Supabase.instance.dispose();
    AppCrashSignal.instance.reset();
  });

  testWidgets(
    'expired recovery stays usable and offers sign-in without restart',
    (tester) async {
      await _pumpGate(tester);
      final auth = Supabase.instance.client.auth;
      final expired = jsonEncode({
        'access_token':
            'e30.${base64Url.encode(utf8.encode('{"exp":1}'))}.test',
        'refresh_token': 'test-refresh-token',
        'token_type': 'bearer',
        'user': {'id': 'test-user', 'created_at': '2026-10-21T00:00:00Z'},
      });
      // Restore and reject before the next frame, as during app bootstrap.
      await auth.setInitialSession(expired);
      await expectLater(
        auth.recoverSession(expired),
        throwsA(isA<AuthApiException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(auth.currentSession, isNull);
      expect(find.byType(OnboardingEntryView), findsOneWidget);
      expect(find.text('Please sign in again.'), findsOneWidget);
      expect(AppCrashSignal.instance.listenable.value, isNull);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Already have an account? Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('temporary auth errors do not show a re-auth prompt', (
    tester,
  ) async {
    await _pumpGate(tester);
    // ignore: invalid_use_of_internal_member
    Supabase.instance.client.auth.notifyException(
      AuthRetryableFetchException(message: 'offline'),
    );
    await tester.pump();
    expect(find.byType(OnboardingEntryView), findsOneWidget);
    expect(find.text('Please sign in again.'), findsNothing);
    expect(AppCrashSignal.instance.listenable.value, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
