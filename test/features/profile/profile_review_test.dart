import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet/features/profile/profile_view.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/review/review_prompt_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const reviewChannel = MethodChannel('dev.britannio.in_app_review');
  late List<MethodCall> calls;
  late bool storeFails;

  setUp(() async {
    calls = [];
    storeFails = false;
    messenger.setMockMethodCallHandler(reviewChannel, (call) async {
      calls.add(call);
      if (storeFails) throw PlatformException(code: 'open_failed');
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : true,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => 'Asia/Tokyo',
    );
    await Supabase.initialize(
      url: 'https://example.invalid',
      anonKey: 'test-anon-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        detectSessionInUri: false,
        autoRefreshToken: false,
      ),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'user_id': 'test-user',
            'nickname': 'Pet keeper',
            'coins': 10,
            'timezone': 'Asia/Tokyo',
          }),
          200,
          request: request,
        ),
      ),
    );
    await Supabase.instance.client.auth.setInitialSession(
      jsonEncode({
        'access_token':
            'e30.${base64Url.encode(utf8.encode('{"exp":4102444800}'))}.test',
        'refresh_token': 'test-refresh',
        'token_type': 'bearer',
        'expires_at': 4102444800,
        'user': {'id': 'test-user', 'created_at': '2026-10-23T00:00:00Z'},
      }),
    );
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(reviewChannel, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
    await Supabase.instance.dispose();
  });

  Future<void> pumpProfile(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileView(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'iOS link is localized and opens store only on tap',
    (tester) async {
      for (final locale in AppLocalizations.supportedLocales) {
        await pumpProfile(tester, locale);
        final context = tester.element(find.byType(ProfileView));
        final label = AppLocalizations.of(context)!.profileWriteReview;
        expect(find.text(label), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(calls, isEmpty);
      final context = tester.element(find.byType(ProfileView));
      final link = find.text(AppLocalizations.of(context)!.profileWriteReview);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(calls.map((call) => call.method), ['openStoreListing']);
      expect(calls.single.arguments, ReviewPromptService.iosAppStoreId);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'store open failure displays localized error without leaving Profile',
    (tester) async {
      storeFails = true;
      await pumpProfile(tester, const Locale('en'));
      final context = tester.element(find.byType(ProfileView));
      final l10n = AppLocalizations.of(context)!;
      final link = find.text(l10n.profileWriteReview);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(l10n.errorUnexpected), findsOneWidget);
      expect(find.byType(ProfileView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant({TargetPlatform.iOS}),
  );

  testWidgets(
    'Android does not display iOS review link',
    (tester) async {
      await pumpProfile(tester, const Locale('en'));
      expect(find.text('Write a review'), findsNothing);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.android}),
  );
}
