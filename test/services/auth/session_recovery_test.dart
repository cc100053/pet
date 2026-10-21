import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet/services/auth/session_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _session(int expiresAt) => jsonEncode({
  'access_token':
      'e30.${base64Url.encode(utf8.encode(jsonEncode({'exp': expiresAt})))}.test',
  'refresh_token': 'test-refresh-token',
  'token_type': 'bearer',
  'user': {'id': 'test-user'},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reused refresh token signs out without escaping any listener', () async {
    final auth = GoTrueClient(
      url: 'https://example.invalid/auth/v1',
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
    addTearDown(auth.dispose);
    final events = <AuthChangeEvent>[];
    // Recovery broadcasts errors to every subscriber, even when its Future
    // is caught. One listener without onError re-enters the global crash path.
    final listeners = List.generate(
      3,
      (_) => auth.onAuthStateChange.listen(
        (state) => events.add(state.event),
        onError: reportAuthStateError,
      ),
    );
    addTearDown(() async {
      for (final listener in listeners) {
        await listener.cancel();
      }
    });
    await auth.setInitialSession(_session(1));
    await expectLater(
      auth.recoverSession(_session(1)),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.code,
          'code',
          'refresh_token_already_used',
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(auth.currentSession, isNull);
    expect(
      events.where((event) => event == AuthChangeEvent.signedOut),
      hasLength(3),
    );

    await auth.setInitialSession(_session(4102444800));
    await Future<void>.delayed(Duration.zero);
    expect(auth.currentSession?.user.id, 'test-user');
  });

  test('temporary auth stream errors preserve the current session', () async {
    final auth = GoTrueClient(url: 'https://example.invalid/auth/v1');
    addTearDown(auth.dispose);
    final listener = auth.onAuthStateChange.listen(
      (_) {},
      onError: reportAuthStateError,
    );
    addTearDown(listener.cancel);
    await auth.setInitialSession(_session(4102444800));
    final session = auth.currentSession;
    // The SDK emits retryable refresh failures through this same stream.
    // ignore: invalid_use_of_internal_member
    auth.notifyException(AuthRetryableFetchException(message: 'offline'));
    await Future<void>.delayed(Duration.zero);
    expect(auth.currentSession, same(session));
  });

  test('unexpected errors retain the original crash path', () {
    final error = StateError('unexpected');
    expect(
      () => reportAuthStateError(error, StackTrace.current),
      throwsA(same(error)),
    );
  });

  test('every manual auth subscription supplies an error handler', () {
    for (final path in [
      'lib/features/auth/auth_gate.dart',
      'lib/features/home/home_view.dart',
      'lib/services/fcm_service.dart',
    ]) {
      final source = File(path).readAsStringSync();
      final subscription = RegExp(
        r'onAuthStateChange\s*\.listen\([\s\S]*?\n\s*\}\s*,\s*onError:',
      ).allMatches(source);
      final manualSubscriptions = RegExp(
        r'onAuthStateChange\s*\.listen\(',
      ).allMatches(source);
      expect(manualSubscriptions, isNotEmpty, reason: path);
      expect(subscription.length, manualSubscriptions.length, reason: path);
    }
  });
}
