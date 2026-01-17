import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class AccessTokenDebugResult {
  AccessTokenDebugResult({
    required this.token,
    required this.message,
    required this.refreshed,
    required this.expiresAt,
    required this.remaining,
    required this.claims,
  });

  final String? token;
  final String message;
  final bool refreshed;
  final DateTime? expiresAt;
  final Duration? remaining;
  final Map<String, dynamic>? claims;
}

Future<String?> ensureValidAccessToken({
  Duration minTtl = const Duration(seconds: 60),
}) async {
  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession;
  if (session == null) {
    return null;
  }

  final expiresAt = session.expiresAt;
  if (expiresAt != null) {
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
      isUtc: true,
    );
    final remaining = expiry.difference(DateTime.now().toUtc());
    if (remaining > minTtl) {
      return session.accessToken;
    }
  }

  try {
    final refreshed = await auth.refreshSession();
    return refreshed.session?.accessToken ??
        auth.currentSession?.accessToken ??
        session.accessToken;
  } catch (_) {
    return session.accessToken;
  }
}

Future<AccessTokenDebugResult> ensureValidAccessTokenWithDebug({
  Duration minTtl = const Duration(seconds: 60),
  bool forceRefresh = false,
}) async {
  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession;
  if (session == null) {
    return AccessTokenDebugResult(
      token: null,
      message: 'No active session.',
      refreshed: false,
      expiresAt: null,
      remaining: null,
      claims: null,
    );
  }

  final claims = _decodeJwtClaims(session.accessToken);
  DateTime? expiry;
  Duration? remaining;
  final expiresAt = session.expiresAt;
  if (expiresAt != null) {
    expiry = DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
      isUtc: true,
    );
    remaining = expiry.difference(DateTime.now().toUtc());
  }

  if (!forceRefresh && remaining != null && remaining > minTtl) {
    return AccessTokenDebugResult(
      token: session.accessToken,
      message: 'Session valid; no refresh needed.',
      refreshed: false,
      expiresAt: expiry,
      remaining: remaining,
      claims: claims,
    );
  }

  try {
    final refreshed = await auth.refreshSession();
    final token = refreshed.session?.accessToken ??
        auth.currentSession?.accessToken ??
        session.accessToken;
    final refreshedClaims = _decodeJwtClaims(token);
    return AccessTokenDebugResult(
      token: token,
      message: 'Session refreshed.',
      refreshed: true,
      expiresAt: expiry,
      remaining: remaining,
      claims: refreshedClaims ?? claims,
    );
  } catch (error) {
    return AccessTokenDebugResult(
      token: session.accessToken,
      message: 'Refresh failed: $error',
      refreshed: false,
      expiresAt: expiry,
      remaining: remaining,
      claims: claims,
    );
  }
}

Map<String, dynamic>? _decodeJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length < 2) {
    return null;
  }
  final payload = parts[1];
  final normalized = base64Url.normalize(payload);
  try {
    final decoded = utf8.decode(base64Url.decode(normalized));
    final jsonMap = json.decode(decoded);
    if (jsonMap is Map<String, dynamic>) {
      return jsonMap;
    }
  } catch (_) {}
  return null;
}
