import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String userFacingError(
  BuildContext context,
  Object error, {
  StackTrace? stackTrace,
  String? source,
}) {
  final l10n = AppLocalizations.of(context)!;
  final summary = _errorSummary(error).toLowerCase();
  final tag = source == null ? 'ui_error' : 'ui_error:$source';
  debugPrint('[$tag] $error');
  if (stackTrace != null) {
    debugPrintStack(stackTrace: stackTrace);
  }

  if (error is FunctionException && error.status == 401) {
    return l10n.authReauthRequired;
  }
  if (error is FunctionException && error.status == 413) {
    return l10n.errorImageTooLarge;
  }
  if (summary.contains('invalid_invite')) {
    return l10n.errorInvalidInviteCode;
  }
  if (summary.contains('not_owner')) {
    return l10n.errorPermissionDenied;
  }
  if (summary.contains('not_member') ||
      summary.contains('invite_code_limit_reached')) {
    return l10n.errorPermissionDenied;
  }
  if (summary.contains('invalid_pet_name') ||
      summary.contains('pet_name_invalid') ||
      summary.contains('name_too_long') ||
      summary.contains('name_too_short') ||
      summary.contains('name contains')) {
    return l10n.errorPetNameInvalid;
  }
  if (summary.contains('permission denied') ||
      summary.contains('forbidden') ||
      summary.contains('not allowed') ||
      summary.contains('42501')) {
    return l10n.errorPermissionDenied;
  }
  if (summary.contains('image_too_large') ||
      summary.contains('payload_too_large')) {
    return l10n.errorImageTooLarge;
  }
  if (summary.contains('network') ||
      summary.contains('socketexception') ||
      summary.contains('timeout') ||
      summary.contains('timed out') ||
      summary.contains('failed host lookup')) {
    return l10n.errorNetwork;
  }
  if (summary.contains('not found') || summary.contains('pgrst116')) {
    return l10n.errorNotFound;
  }

  return l10n.errorUnexpected;
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
  return error.toString();
}
