import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pet/services/crash/crash_reporting_service.dart';

void main() {
  group('CrashReportingService.shouldRecordAsFatal', () {
    test('keeps requested non-fatal errors non-fatal', () {
      expect(
        CrashReportingService.shouldRecordAsFatal(
          Exception('anything'),
          requestedFatal: false,
        ),
        isFalse,
      );
    });

    test('downgrades retryable auth/network exceptions', () {
      expect(
        CrashReportingService.shouldRecordAsFatal(
          Exception(
            'AuthRetryableFetchException(message: ClientException: Bad file descriptor)',
          ),
          requestedFatal: true,
        ),
        isFalse,
      );
      expect(
        CrashReportingService.shouldRecordAsFatal(
          const SocketException("Failed host lookup: 'fonts.gstatic.com'"),
          requestedFatal: true,
        ),
        isFalse,
      );
      expect(
        CrashReportingService.shouldRecordAsFatal(
          TimeoutException('request timed out'),
          requestedFatal: true,
        ),
        isFalse,
      );
      expect(
        CrashReportingService.shouldRecordAsFatal(
          Exception(
            'ClientException with SocketException: Operation timed out '
            '(OS Error: Operation timed out, errno = 60), '
            'uri=https://ilxzpszgirhwxpeocygs.supabase.co/rest/v1/rpc/'
            'tick_pet_state',
          ),
          requestedFatal: true,
        ),
        isFalse,
      );
    });

    test('keeps genuine app errors fatal when requested', () {
      expect(
        CrashReportingService.shouldRecordAsFatal(
          StateError('unexpected null state'),
          requestedFatal: true,
        ),
        isTrue,
      );
    });
  });
}
