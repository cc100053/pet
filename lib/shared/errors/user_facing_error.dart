import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/crash/crash_reporting_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Classification of an error that was surfaced to the user.
///
/// The category doubles as a Crashlytics custom key, so a spike in one category
/// (for example [network] vs [unexpected]) is visible without reading through
/// individual reports.
enum UserFacingErrorCategory {
  authReauthRequired,
  imageTooLarge,
  invalidInvite,
  mediaPermissionDenied,
  permissionDenied,
  petNameInvalid,
  network,
  notFound,
  unexpected,
}

extension on UserFacingErrorCategory {
  /// `unexpected` is the only category we failed to recognise, so it is the one
  /// worth triaging: the rest are understood, handled states.
  bool get isActionable => this == UserFacingErrorCategory.unexpected;

  String get key => name;
}

/// Converts [error] into a localized message for display, and reports it to
/// Crashlytics as a non-fatal.
///
/// Every user-visible error message funnels through here, so this is the single
/// place that makes "the user saw an error" imply "we have a crash report".
/// Reporting is fire-and-forget and never throws: failing to report must not
/// break the UI path that is already handling a failure.
String userFacingError(
  BuildContext context,
  Object error, {
  StackTrace? stackTrace,
  String? source,
}) {
  final l10n = AppLocalizations.of(context)!;
  final summary = _errorSummary(error);
  final category = _classify(error, summary);

  // Captured here rather than at the call site: most callers pass no stack
  // trace, and `StackTrace.current` still includes the calling frames, which is
  // what gives Crashlytics per-call-site grouping.
  _report(
    error: error,
    stackTrace: stackTrace ?? StackTrace.current,
    category: category,
    summary: summary,
    source: source,
  );

  return _message(l10n, category);
}

/// Reports an error whose message the caller renders itself.
///
/// Use this when a screen has bespoke copy for a failure and so cannot call
/// [userFacingError] for the message, but the error must still be reported.
void reportUserVisibleError(
  Object error,
  StackTrace stackTrace, {
  required String source,
}) {
  final summary = _errorSummary(error);
  _report(
    error: error,
    stackTrace: stackTrace,
    category: _classify(error, summary),
    summary: summary,
    source: source,
  );
}

/// Reports an error that was handled without showing the user a message.
///
/// Use this instead of a bare `catch (_) {}` for best-effort work (cache reads,
/// telemetry, prefetching). The failure stays silent in the UI but stops being
/// invisible in Crashlytics.
void reportSwallowedError(
  Object error,
  StackTrace stackTrace, {
  required String source,
}) {
  final summary = _errorSummary(error);
  _report(
    error: error,
    stackTrace: stackTrace,
    category: _classify(error, summary),
    summary: summary,
    source: source,
    swallowed: true,
  );
}

/// Errors repeat: a failing poll or a retry loop can surface the same message
/// many times a minute. Without a throttle those flood Crashlytics and bury the
/// long tail of rarer, more interesting failures.
const Duration _dedupWindow = Duration(minutes: 2);
const int _dedupCacheLimit = 64;
final Map<String, DateTime> _recentReports = <String, DateTime>{};

@visibleForTesting
void resetUserFacingErrorDedupCache() => _recentReports.clear();

void _report({
  required Object error,
  required StackTrace stackTrace,
  required UserFacingErrorCategory category,
  required String summary,
  required String? source,
  bool swallowed = false,
}) {
  final prefix = swallowed ? 'swallowed_error' : 'ui_error';
  final normalizedSource = (source == null || source.trim().isEmpty)
      ? prefix
      : '$prefix:${source.trim()}';

  if (kDebugMode) {
    debugPrint('[$normalizedSource][${category.key}] $error');
  }

  if (!_shouldReport(normalizedSource, category, summary)) {
    return;
  }

  unawaited(
    _send(
      error: error,
      stackTrace: stackTrace,
      category: category,
      summary: summary,
      source: normalizedSource,
      swallowed: swallowed,
    ),
  );
}

Future<void> _send({
  required Object error,
  required StackTrace stackTrace,
  required UserFacingErrorCategory category,
  required String summary,
  required String source,
  required bool swallowed,
}) async {
  try {
    await CrashReportingService.instance.reportError(
      error: error,
      stackTrace: stackTrace,
      source: source,
      // Handled errors are non-fatal by definition: the app kept running and
      // told the user what happened.
      fatal: false,
      reason: '$source/${category.key}',
      information: <Object>[
        'category: ${category.key}',
        'actionable: ${category.isActionable}',
        'user_visible: ${!swallowed}',
        'summary: ${_truncate(summary)}',
      ],
    );
    await CrashReportingService.instance.setCustomKeys(<String, Object?>{
      'last_handled_error': category.key,
      'last_handled_error_source': source,
    });
  } catch (_) {
    // Reporting is best-effort; never let it surface as a new error.
  }
}

bool _shouldReport(
  String source,
  UserFacingErrorCategory category,
  String summary,
) {
  final now = DateTime.now();
  final signature =
      '$source|${category.key}|${_truncate(summary, maxLength: 200)}';
  final lastSeen = _recentReports[signature];
  if (lastSeen != null && now.difference(lastSeen) < _dedupWindow) {
    return false;
  }

  if (_recentReports.length >= _dedupCacheLimit) {
    _recentReports.removeWhere(
      (_, seenAt) => now.difference(seenAt) >= _dedupWindow,
    );
    if (_recentReports.length >= _dedupCacheLimit) {
      final oldest = _recentReports.entries.reduce(
        (a, b) => a.value.isBefore(b.value) ? a : b,
      );
      _recentReports.remove(oldest.key);
    }
  }

  _recentReports[signature] = now;
  return true;
}

@visibleForTesting
UserFacingErrorCategory classifyUserFacingError(Object error) =>
    _classify(error, _errorSummary(error));

/// `image_picker` platform codes that mean "the OS refused media access",
/// not "the app is broken". iOS raises the camera codes from
/// `UIImagePickerController` and the photo codes from the legacy
/// `PHPhotoLibrary` path; Android raises the same two families.
const Set<String> _mediaPermissionCodes = <String>{
  'camera_access_denied',
  'camera_access_restricted',
  'photo_access_denied',
  'photo_access_restricted',
};

UserFacingErrorCategory _classify(Object error, String rawSummary) {
  final summary = rawSummary.toLowerCase();

  // Platform channel failures carry a stable `code`; matching on it beats
  // substring-matching the rendered message, which varies per OS locale.
  if (error is PlatformException &&
      _mediaPermissionCodes.contains(error.code)) {
    return UserFacingErrorCategory.mediaPermissionDenied;
  }
  if (error is FunctionException && error.status == 401) {
    return UserFacingErrorCategory.authReauthRequired;
  }
  if (error is FunctionException && error.status == 413) {
    return UserFacingErrorCategory.imageTooLarge;
  }
  if (summary.contains('invalid_invite')) {
    return UserFacingErrorCategory.invalidInvite;
  }
  if (summary.contains('not_owner')) {
    return UserFacingErrorCategory.permissionDenied;
  }
  if (summary.contains('not_member') ||
      summary.contains('invite_code_limit_reached')) {
    return UserFacingErrorCategory.permissionDenied;
  }
  if (summary.contains('invalid_pet_name') ||
      summary.contains('pet_name_invalid') ||
      summary.contains('name_too_long') ||
      summary.contains('name_too_short') ||
      summary.contains('name contains')) {
    return UserFacingErrorCategory.petNameInvalid;
  }
  if (summary.contains('permission denied') ||
      summary.contains('forbidden') ||
      summary.contains('not allowed') ||
      summary.contains('42501')) {
    return UserFacingErrorCategory.permissionDenied;
  }
  if (summary.contains('image_too_large') ||
      summary.contains('payload_too_large')) {
    return UserFacingErrorCategory.imageTooLarge;
  }
  if (summary.contains('network') ||
      summary.contains('socketexception') ||
      summary.contains('timeout') ||
      summary.contains('timed out') ||
      summary.contains('failed host lookup')) {
    return UserFacingErrorCategory.network;
  }
  if (summary.contains('not found') || summary.contains('pgrst116')) {
    return UserFacingErrorCategory.notFound;
  }

  return UserFacingErrorCategory.unexpected;
}

String _message(AppLocalizations l10n, UserFacingErrorCategory category) {
  switch (category) {
    case UserFacingErrorCategory.authReauthRequired:
      return l10n.authReauthRequired;
    case UserFacingErrorCategory.imageTooLarge:
      return l10n.errorImageTooLarge;
    case UserFacingErrorCategory.invalidInvite:
      return l10n.errorInvalidInviteCode;
    case UserFacingErrorCategory.mediaPermissionDenied:
      return l10n.errorMediaPermissionDenied;
    case UserFacingErrorCategory.permissionDenied:
      return l10n.errorPermissionDenied;
    case UserFacingErrorCategory.petNameInvalid:
      return l10n.errorPetNameInvalid;
    case UserFacingErrorCategory.network:
      return l10n.errorNetwork;
    case UserFacingErrorCategory.notFound:
      return l10n.errorNotFound;
    case UserFacingErrorCategory.unexpected:
      return l10n.errorUnexpected;
  }
}

String _truncate(String value, {int maxLength = 512}) {
  if (value.length <= maxLength) {
    return value;
  }
  return value.substring(0, maxLength);
}

String _errorSummary(Object error) {
  if (error is PostgrestException) {
    return [
      error.message,
      error.code,
      error.details,
      error.hint,
    ].whereType<String>().join(' | ');
  }
  if (error is FunctionException) {
    return [
      '${error.status}',
      error.reasonPhrase,
      error.details?.toString(),
    ].whereType<String>().join(' | ');
  }
  if (error is AuthException) {
    return '${error.message} | ${error.statusCode}';
  }
  if (error is PlatformException) {
    // `toString()` appends the native stack trace, which differs on every
    // occurrence and would defeat both dedup and Crashlytics grouping.
    return [
      error.code,
      error.message,
      error.details?.toString(),
    ].whereType<String>().join(' | ');
  }
  return error.toString();
}
