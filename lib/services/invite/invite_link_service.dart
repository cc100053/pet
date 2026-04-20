import 'dart:async';

import 'package:app_links/app_links.dart';

import '../settings/app_settings_repository.dart';
import 'pending_invite_code_store.dart';

abstract class InviteLinkGateway {
  Future<Uri?> getInitialLink();
  Stream<Uri> get uriLinkStream;
}

class AppLinksInviteLinkGateway implements InviteLinkGateway {
  AppLinksInviteLinkGateway([AppLinks? appLinks])
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  @override
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}

class AppInviteLinkService {
  AppInviteLinkService({
    required InviteLinkGateway gateway,
    required PendingInviteCodeStore settingsStore,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) : _gateway = gateway,
       _settingsStore = settingsStore,
       _onError = onError;

  AppInviteLinkService._default()
    : this(
        gateway: AppLinksInviteLinkGateway(),
        settingsStore: AppSettingsRepository.instance,
      );

  static final AppInviteLinkService instance = AppInviteLinkService._default();

  static const String inviteHost = 'pet-app-702be.web.app';
  static const String invitePath = '/invite';
  static const String customScheme = 'com.cc100053.pet';
  static const String customInviteHost = 'invite';
  static const String iosAppStoreUrl =
      'https://apps.apple.com/app/id6757725650';
  static final RegExp _inviteCodePattern = RegExp(r'^[A-Z0-9]{6}$');

  final InviteLinkGateway _gateway;
  final PendingInviteCodeStore _settingsStore;
  final void Function(Object error, StackTrace stackTrace)? _onError;
  final StreamController<String> _inviteCodeController =
      StreamController<String>.broadcast();

  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;
  String? _lastHandledCode;
  DateTime? _lastHandledAt;

  Stream<String> get inviteCodes => _inviteCodeController.stream;

  String? get pendingInviteCode => _settingsStore.pendingInviteCode;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _linkSubscription = _gateway.uriLinkStream.listen(
      _handleUri,
      onError: (Object error, StackTrace stackTrace) {
        _onError?.call(error, stackTrace);
      },
    );
    try {
      final initialLink = await _gateway.getInitialLink();
      if (initialLink != null) {
        await _handleUri(initialLink);
      }
    } catch (error, stackTrace) {
      _onError?.call(error, stackTrace);
    }
  }

  Future<void> dispose() async {
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    _initialized = false;
  }

  Future<void> clearPendingInviteCode() {
    return _settingsStore.setPendingInviteCode(null);
  }

  Future<void> rememberPendingInviteCode(String code) async {
    final normalized = normalizeInviteCode(code);
    if (normalized == null) {
      return;
    }
    await _settingsStore.setPendingInviteCode(normalized);
    _inviteCodeController.add(normalized);
  }

  Future<void> _handleUri(Uri uri) async {
    final code = parseInviteCode(uri);
    if (code == null) {
      return;
    }
    if (_isDuplicateRecentCode(code)) {
      return;
    }
    _lastHandledCode = code;
    _lastHandledAt = DateTime.now();
    await rememberPendingInviteCode(code);
  }

  bool _isDuplicateRecentCode(String code) {
    final handledAt = _lastHandledAt;
    if (_lastHandledCode != code || handledAt == null) {
      return false;
    }
    return DateTime.now().difference(handledAt) < const Duration(seconds: 2);
  }

  static String? parseInviteCode(Uri uri) {
    final rawCode = uri.queryParameters['code'];
    if (_isHostedInviteUri(uri) || _isCustomInviteUri(uri)) {
      return normalizeInviteCode(rawCode);
    }
    return null;
  }

  static bool _isHostedInviteUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'https' || scheme == 'http') &&
        uri.host.toLowerCase() == inviteHost &&
        _normalizedPath(uri) == invitePath;
  }

  static bool _isCustomInviteUri(Uri uri) {
    if (uri.scheme.toLowerCase() != customScheme) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return host == customInviteHost || _normalizedPath(uri) == invitePath;
  }

  static String _normalizedPath(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
  }

  static String? normalizeInviteCode(String? rawCode) {
    final normalized = rawCode?.trim().toUpperCase();
    if (normalized == null || !_inviteCodePattern.hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  static Uri inviteUriForCode(String code) {
    final normalized = normalizeInviteCode(code);
    if (normalized == null) {
      throw ArgumentError.value(code, 'code', 'Invalid invite code');
    }
    return Uri.https(inviteHost, invitePath, {'code': normalized});
  }

  static Uri customInviteUriForCode(String code) {
    final normalized = normalizeInviteCode(code);
    if (normalized == null) {
      throw ArgumentError.value(code, 'code', 'Invalid invite code');
    }
    return Uri(
      scheme: customScheme,
      host: customInviteHost,
      queryParameters: {'code': normalized},
    );
  }

  static String shareText({required String caption, required String code}) {
    return '${caption.trim()}\n${inviteUriForCode(code)}';
  }
}
