import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/errors/user_facing_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pumps a widget that resolves [userFacingError] against real localizations,
/// so the test exercises the same path the UI does.
Future<String> _resolveMessage(WidgetTester tester, Object error) async {
  late String message;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          message = userFacingError(context, error, source: 'test');
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return message;
}

void main() {
  setUp(resetUserFacingErrorDedupCache);

  group('classifyUserFacingError', () {
    test('maps 401 edge function failures to a re-auth prompt', () {
      expect(
        classifyUserFacingError(
          const FunctionException(status: 401, reasonPhrase: 'Unauthorized'),
        ),
        UserFacingErrorCategory.authReauthRequired,
      );
    });

    test('maps 413 edge function failures to image-too-large', () {
      expect(
        classifyUserFacingError(
          const FunctionException(status: 413, reasonPhrase: 'Too Large'),
        ),
        UserFacingErrorCategory.imageTooLarge,
      );
    });

    test('classifies transport failures as network', () {
      expect(
        classifyUserFacingError(Exception('SocketException: failed')),
        UserFacingErrorCategory.network,
      );
      expect(
        classifyUserFacingError(Exception('Connection timed out')),
        UserFacingErrorCategory.network,
      );
    });

    test('reads Postgrest codes rather than only the message', () {
      expect(
        classifyUserFacingError(
          const PostgrestException(message: 'no rows', code: 'PGRST116'),
        ),
        UserFacingErrorCategory.notFound,
      );
      expect(
        classifyUserFacingError(
          const PostgrestException(message: 'denied', code: '42501'),
        ),
        UserFacingErrorCategory.permissionDenied,
      );
    });

    test('maps image_picker access codes to the media-permission category', () {
      for (final code in const <String>[
        'camera_access_denied',
        'camera_access_restricted',
        'photo_access_denied',
        'photo_access_restricted',
      ]) {
        expect(
          classifyUserFacingError(PlatformException(code: code)),
          UserFacingErrorCategory.mediaPermissionDenied,
          reason: code,
        );
      }
    });

    test('leaves other platform codes unexpected', () {
      expect(
        classifyUserFacingError(PlatformException(code: 'create_error')),
        UserFacingErrorCategory.unexpected,
      );
    });

    test('falls back to unexpected for unrecognised errors', () {
      expect(
        classifyUserFacingError(StateError('something entirely new')),
        UserFacingErrorCategory.unexpected,
      );
    });
  });

  group('userFacingError', () {
    testWidgets('returns a localized message and never leaks raw error text', (
      tester,
    ) async {
      final message = await _resolveMessage(
        tester,
        StateError('PostgrestException internal detail leak'),
      );

      expect(message, isNotEmpty);
      expect(message, isNot(contains('PostgrestException')));
      expect(message, isNot(contains('internal detail leak')));
    });

    testWidgets('maps a network failure to the network message', (
      tester,
    ) async {
      final networkMessage = await _resolveMessage(
        tester,
        Exception('Failed host lookup: supabase.co'),
      );
      final unexpectedMessage = await _resolveMessage(
        tester,
        StateError('brand new failure'),
      );

      expect(networkMessage, isNot(equals(unexpectedMessage)));
    });

    testWidgets('does not throw when Crashlytics is unavailable', (
      tester,
    ) async {
      // Firebase is not initialized under test; reporting must degrade quietly
      // rather than turning a handled error into a crash.
      final message = await _resolveMessage(tester, StateError('boom'));
      expect(message, isNotEmpty);
    });
  });
}
