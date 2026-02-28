import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth/session_utils.dart';
import '../../services/env.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../services/profile/device_timezone_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/localization/app_locale_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/user_avatar.dart';
import '../../shared/upload_limits.dart';
import '../../shared/utils/avatar_display_position.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  static const int _avatarMaxDimension = 512;
  static const int _avatarWebpQuality = 70;
  static const int _nicknameMaxLength = 20;
  static const Duration _networkTimeout = Duration(seconds: 12);

  final _picker = ImagePicker();
  final _nicknameController = TextEditingController();
  Future<Map<String, dynamic>?>? _profileFuture;
  Future<PackageInfo>? _packageInfoFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    }
  }

  Future<T> _withNetworkTimeout<T>(
    Future<T> future, {
    required String operation,
  }) async {
    try {
      return await future.timeout(_networkTimeout);
    } on TimeoutException {
      throw Exception('network_timeout:$operation');
    }
  }

  bool _isLikelyNetworkError(Object error) {
    final summary = error.toString().toLowerCase();
    return summary.contains('network') ||
        summary.contains('socketexception') ||
        summary.contains('timeout') ||
        summary.contains('timed out') ||
        summary.contains('failed host lookup') ||
        summary.contains('network_timeout');
  }

  bool _isNetworkUnavailableError(Object error) {
    return error.toString().toLowerCase().contains('network_unavailable');
  }

  Future<void> _retryLoadProfile() async {
    if (_busy) {
      return;
    }
    setState(() {
      _profileFuture = _loadProfile(
        defaultNickname: AppLocalizations.of(context)!.profileDefaultNickname,
      );
    });
  }

  String _feedbackBaseUrlForLanguageTag(String languageTag) {
    final normalized = languageTag.toLowerCase();
    if (normalized.startsWith('ko')) {
      return Env.feedbackUrlKo;
    }
    if (normalized.startsWith('ja')) {
      return Env.feedbackUrlJa;
    }
    if (normalized.startsWith('zh-hant') ||
        normalized.startsWith('zh-tw') ||
        normalized.startsWith('zh-hk') ||
        normalized.startsWith('zh-mo')) {
      return Env.feedbackUrlZhTw;
    }
    return Env.feedbackUrlEn;
  }

  String _resolvedLanguageTag(BuildContext context) {
    final selectedLocale = ref.read(appLocaleProvider).locale;
    final activeLocale = selectedLocale ?? Localizations.localeOf(context);
    return activeLocale.toLanguageTag();
  }

  String _feedbackUrl(BuildContext context) {
    return _feedbackBaseUrlForLanguageTag(_resolvedLanguageTag(context));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileFuture ??= _loadProfile(
      defaultNickname: AppLocalizations.of(context)!.profileDefaultNickname,
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadProfile({
    required String defaultNickname,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return null;
      }
      final localTimezone = await DeviceTimezoneService.instance.getTimezone();

      final profile = await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .select('user_id,nickname,avatar_url,coins,locale,timezone')
            .eq('user_id', user.id)
            .maybeSingle(),
        operation: 'load_profile',
      );

      if (profile != null) {
        if (localTimezone != null) {
          final profileTimezone = (profile['timezone'] as String?)?.trim();
          if (profileTimezone == null || profileTimezone != localTimezone) {
            await _withNetworkTimeout(
              Supabase.instance.client
                  .from('profiles')
                  .update({'timezone': localTimezone})
                  .eq('user_id', user.id),
              operation: 'sync_timezone',
            );
          }
        }
        return profile;
      }

      final insertPayload = <String, dynamic>{
        'user_id': user.id,
        'nickname': defaultNickname,
      };
      if (localTimezone != null) {
        insertPayload['timezone'] = localTimezone;
      }
      await _withNetworkTimeout(
        Supabase.instance.client.from('profiles').insert(insertPayload),
        operation: 'create_profile',
      );

      return _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .select('user_id,nickname,avatar_url,coins,locale,timezone')
            .eq('user_id', user.id)
            .maybeSingle(),
        operation: 'reload_profile',
      );
    } catch (error) {
      if (_isLikelyNetworkError(error)) {
        await Future<void>.delayed(const Duration(seconds: 3));
        throw Exception('network_unavailable');
      }
      rethrow;
    }
  }

  Future<void> _saveProfile() async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || nickname.characters.length > _nicknameMaxLength) {
      return;
    }

    setState(() => _busy = true);
    try {
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .update({'nickname': nickname})
            .eq('user_id', user.id),
        operation: 'save_profile',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)),
    );

    setState(() {
      _profileFuture = _loadProfile(
        defaultNickname: AppLocalizations.of(context)!.profileDefaultNickname,
      );
    });
  }

  Future<void> _showNicknamePrompt(String currentNickname) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _nicknameController
      ..text = currentNickname
      ..selection = TextSelection.collapsed(offset: currentNickname.length);

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.profileNicknameLabel),
          content: TextField(
            controller: _nicknameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(_nicknameMaxLength),
            ],
            decoration: InputDecoration(labelText: l10n.profileNicknameLabel),
            onSubmitted: (_) => Navigator.of(context).pop(true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      await _saveProfile();
    }
  }

  Future<_CompressedImage> _compressAvatar(XFile image) async {
    final originalBytes = await image.readAsBytes();
    if (kIsWeb) {
      return _CompressedImage(bytes: originalBytes, contentType: 'image/jpeg');
    }

    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: _avatarWebpQuality,
        minWidth: _avatarMaxDimension,
        minHeight: _avatarMaxDimension,
        format: CompressFormat.webp,
      );
      if (compressedBytes != null && compressedBytes.isNotEmpty) {
        return _CompressedImage(
          bytes: compressedBytes,
          contentType: 'image/webp',
        );
      }
    } catch (_) {
      // Best effort.
    }

    return _CompressedImage(bytes: originalBytes, contentType: 'image/jpeg');
  }

  Future<XFile?> _pickAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }
    return image;
  }

  bool _isRemoteAvatarUrl(String? avatarUrl) {
    final value = (avatarUrl ?? '').trim();
    if (value.isEmpty) {
      return false;
    }
    final parsed = parseAvatarUrlWithAlignment(value);
    return parsed.imageUrl.startsWith('http://') ||
        parsed.imageUrl.startsWith('https://');
  }

  int? _activePresetId(String? avatarUrl) {
    final value = (avatarUrl ?? '').trim();
    if (!value.startsWith(UserAvatar.presetPrefix)) {
      return null;
    }
    return int.tryParse(value.substring(UserAvatar.presetPrefix.length));
  }

  Future<void> _saveAvatarFraming({
    required String currentAvatarUrl,
    required Alignment alignment,
    required double scale,
  }) async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final updatedAvatarUrl = buildAvatarUrlWithFraming(
        currentAvatarUrl,
        alignment: alignment,
        scale: scale,
      );
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': updatedAvatarUrl})
            .eq('user_id', user.id),
        operation: 'set_avatar_framing',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _profileFuture = _loadProfile(
            defaultNickname: AppLocalizations.of(
              context,
            )!.profileDefaultNickname,
          );
        });
      }
    }
  }

  Future<void> _adjustCurrentAvatar(String? currentAvatarUrl) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    if (!_isRemoteAvatarUrl(currentAvatarUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileAvatarAdjustUnavailable)),
      );
      return;
    }
    final parsed = parseAvatarUrlWithAlignment(currentAvatarUrl!.trim());
    final confirmedFraming = await Navigator.of(context)
        .push<_AvatarFramingData>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (routeContext) => _AvatarPositionEditorPage(
              imageProvider: NetworkImage(parsed.imageUrl),
              initialFraming: _AvatarFramingData(
                alignment: parsed.alignment,
                scale: parsed.scale,
                scaleMode: parsed.scaleMode,
              ),
              title: l10n.profileAvatarAdjustCurrent,
              applyLabel: l10n.commonSave,
              cancelLabel: l10n.commonCancel,
            ),
          ),
        );
    if (!mounted || confirmedFraming == null) {
      return;
    }

    await _saveAvatarFraming(
      currentAvatarUrl: currentAvatarUrl,
      alignment: confirmedFraming.alignment,
      scale: confirmedFraming.scale,
    );
  }

  Future<void> _setAvatarPreset(int presetId) async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': '${UserAvatar.presetPrefix}$presetId'})
            .eq('user_id', user.id),
        operation: 'set_avatar_preset',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _profileFuture = _loadProfile(
            defaultNickname: AppLocalizations.of(
              context,
            )!.profileDefaultNickname,
          );
        });
      }
    }
  }

  Future<void> _removeAvatar() async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': null})
            .eq('user_id', user.id),
        operation: 'remove_avatar',
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _profileFuture = _loadProfile(
            defaultNickname: AppLocalizations.of(
              context,
            )!.profileDefaultNickname,
          );
        });
      }
    }
  }

  Future<void> _uploadAvatarFile(
    XFile image, {
    _AvatarFramingData initialFraming = const _AvatarFramingData(
      alignment: Alignment.center,
      scale: 1,
      scaleMode: AvatarScaleMode.relativeZoom,
    ),
  }) async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final compressed = await _compressAvatar(image);
      if (!kAllowedUploadImageContentTypes.contains(compressed.contentType)) {
        throw Exception('invalid_image_content_type');
      }
      if (compressed.bytes.length > kMaxUploadImageBytes) {
        throw Exception('image_too_large');
      }
      final dataUri =
          'data:${compressed.contentType};base64,${base64Encode(compressed.bytes)}';

      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'avatar_upload',
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'image_base64': dataUri,
            'image_content_type': compressed.contentType,
          },
        );
      }

      String responseErrorSummary(FunctionResponse response) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final error = data['error']?.toString();
          final detail = data['detail']?.toString();
          if (error != null && error.isNotEmpty) {
            if (detail != null && detail.isNotEmpty) {
              return '$error:$detail';
            }
            return error;
          }
        }
        return 'status_${response.status}';
      }

      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        throw Exception('missing_session');
      }

      Future<String> invokeAndGetUploadedUrl(
        String token,
        String operation,
      ) async {
        final response = await _withNetworkTimeout(
          invokeWithToken(token),
          operation: operation,
        );
        if (response.status < 200 || response.status >= 300) {
          throw Exception(
            'avatar_upload_failed:${responseErrorSummary(response)}',
          );
        }
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final avatarUrl = data['avatar_url']?.toString();
          if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
            return avatarUrl.trim();
          }
        }
        throw Exception('avatar_upload_missing_avatar_url');
      }

      try {
        final uploadedAvatarUrl = await invokeAndGetUploadedUrl(
          accessToken,
          'avatar_upload',
        );
        final framedAvatarUrl = buildAvatarUrlWithFraming(
          uploadedAvatarUrl,
          alignment: initialFraming.alignment,
          scale: initialFraming.scale,
        );
        if (framedAvatarUrl != uploadedAvatarUrl) {
          await _withNetworkTimeout(
            Supabase.instance.client
                .from('profiles')
                .update({'avatar_url': framedAvatarUrl})
                .eq('user_id', user.id),
            operation: 'set_initial_avatar_framing',
          );
        }
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          final uploadedAvatarUrl = await invokeAndGetUploadedUrl(
            refreshedToken,
            'avatar_upload_retry',
          );
          final framedAvatarUrl = buildAvatarUrlWithFraming(
            uploadedAvatarUrl,
            alignment: initialFraming.alignment,
            scale: initialFraming.scale,
          );
          if (framedAvatarUrl != uploadedAvatarUrl) {
            await _withNetworkTimeout(
              Supabase.instance.client
                  .from('profiles')
                  .update({'avatar_url': framedAvatarUrl})
                  .eq('user_id', user.id),
              operation: 'set_initial_avatar_framing_retry',
            );
          }
        } else {
          rethrow;
        }
      }
    } catch (error, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(
                context,
                error,
                stackTrace: stackTrace,
                source: 'profile_avatar_upload',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _profileFuture = _loadProfile(
            defaultNickname: AppLocalizations.of(
              context,
            )!.profileDefaultNickname,
          );
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    final image = await _pickAvatar();
    if (image == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }
    if (bytes.length > kMaxUploadImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errorImageTooLarge),
        ),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final initialFraming = await navigator.push<_AvatarFramingData>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (routeContext) => _AvatarPositionEditorPage(
          imageProvider: MemoryImage(bytes),
          initialFraming: const _AvatarFramingData(
            alignment: Alignment.center,
            scale: 1,
            scaleMode: AvatarScaleMode.relativeZoom,
          ),
          title: l10n.profileAvatarEdit,
          applyLabel: l10n.commonSave,
          cancelLabel: l10n.commonCancel,
        ),
      ),
    );
    if (!mounted || initialFraming == null) {
      return;
    }
    await _uploadAvatarFile(image, initialFraming: initialFraming);
  }

  Future<void> _confirmDeleteAccount() async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.danger,
        title: l10n.profileDeleteAccountTitle,
        message: l10n.profileDeleteAccountConfirmBody,
        actions: [
          AppDialogAction.secondary(
            label: l10n.commonCancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction.destructive(
            label: l10n.profileDeleteAccountConfirmAction,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _returnToAuthRootIfSignedOut() async {
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    for (var attempt = 0; attempt < 6; attempt++) {
      if (Supabase.instance.client.auth.currentSession == null) {
        navigator.popUntil((route) => route.isFirst);
        return;
      }
      if (attempt < 5) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'delete_account',
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        throw Exception('missing_session');
      }

      late final FunctionResponse deleteResponse;
      try {
        deleteResponse = await _withNetworkTimeout(
          invokeWithToken(accessToken),
          operation: 'delete_account',
        );
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          deleteResponse = await _withNetworkTimeout(
            invokeWithToken(refreshedToken),
            operation: 'delete_account_retry',
          );
        } else {
          rethrow;
        }
      }
      final payload = deleteResponse.data;
      if (deleteResponse.status != 200 ||
          payload is! Map ||
          payload['deleted'] != true) {
        throw Exception('delete_account_failed_unexpected_response');
      }

      try {
        await RevenueCatService().logOut();
      } catch (error) {
        debugPrint('delete_account cleanup: revenuecat logOut failed: $error');
      }

      try {
        await Supabase.instance.client.auth.signOut();
      } catch (error) {
        debugPrint('delete_account cleanup: global signOut failed: $error');
        await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
      }

      await _returnToAuthRootIfSignedOut();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.profileDeleteFailed(userFacingError(context, error)),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _showAvatarActions(String? currentAvatarUrl) async {
    final l10n = AppLocalizations.of(context)!;
    final activePresetId = _activePresetId(currentAvatarUrl);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3E5E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  UserAvatar(
                    avatar: currentAvatarUrl,
                    fallbackText: null,
                    size: 78,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.profileAvatarTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List<Widget>.generate(UserAvatar.presetCount, (
                      index,
                    ) {
                      final selected = activePresetId == index;
                      return InkWell(
                        onTap: _busy
                            ? null
                            : () {
                                Navigator.pop(context);
                                _setAvatarPreset(index);
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppTheme.primaryColor.withValues(alpha: 0.10)
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFFE2E5EA),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: UserAvatar(
                            avatar: '${UserAvatar.presetPrefix}$index',
                            fallbackText: null,
                            size: 46,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              Navigator.pop(context);
                              _uploadAvatar();
                            },
                      icon: const Icon(Icons.upload_rounded),
                      label: Text(l10n.profileAvatarUpload),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy || !_isRemoteAvatarUrl(currentAvatarUrl)
                          ? null
                          : () {
                              Navigator.pop(context);
                              _adjustCurrentAvatar(currentAvatarUrl);
                            },
                      icon: const Icon(Icons.crop_rounded),
                      label: Text(l10n.profileAvatarAdjustCurrent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              Navigator.pop(context);
                              _removeAvatar();
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.profileAvatarRemove),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (_isNetworkUnavailableError(snapshot.error!)) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 40,
                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.errorNetwork,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _busy ? null : _retryLoadProfile,
                        child: Text(l10n.commonReload),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                l10n.profileLoadFailed(
                  userFacingError(context, snapshot.error!),
                ),
              ),
            );
          }
          final profile = snapshot.data;
          if (profile == null) {
            return Center(child: Text(l10n.profileEmpty));
          }

          final nickname = profile['nickname'] as String? ?? '';
          if (_nicknameController.text.isEmpty) {
            _nicknameController.text = nickname;
          }
          final avatar = profile['avatar_url'] as String?;
          final userId = profile['user_id']?.toString();
          final avatarFallback = nickname.trim().isNotEmpty ? nickname : userId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // Banner Card
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.15),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          UserAvatar(
                            avatar: avatar,
                            fallbackText: avatarFallback,
                            size: 80,
                          ),
                          Material(
                            elevation: 2,
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _busy
                                  ? null
                                  : () => _showAvatarActions(avatar),
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    nickname.isEmpty
                                        ? l10n.profileDefaultNickname
                                        : nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _busy
                                      ? null
                                      : () => _showNicknamePrompt(nickname),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userId != null
                                  ? l10n.profileUserId(userId.substring(0, 8))
                                  : '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Settings List
              Text(
                l10n.profileSectionAbout,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(l10n.storePrivacyPolicy),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onTap: () => _openExternalUrl(Env.privacyPolicyUrl),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(
                        Icons.description_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(l10n.storeTermsOfUse),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onTap: () => _openExternalUrl(Env.termsOfUseUrl),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(
                        Icons.feedback_outlined,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(l10n.profileFeedback),
                      trailing: const Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onTap: () => _openExternalUrl(_feedbackUrl(context)),
                    ),
                  ],
                ),
              ),

              Text(
                l10n.profileSectionDangerZone,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.only(bottom: 32),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.errorColor,
                  ),
                  title: Text(
                    l10n.profileDeleteAccountSectionTitle,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _busy ? null : _confirmDeleteAccount,
                ),
              ),

              // App Info
              FutureBuilder<PackageInfo>(
                future: _packageInfoFuture,
                builder: (context, packageSnapshot) {
                  if (!packageSnapshot.hasData) return const SizedBox.shrink();
                  final info = packageSnapshot.data!;
                  return Center(
                    child: Text(
                      'v${info.version} (${info.buildNumber})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarPositionEditorPage extends StatefulWidget {
  const _AvatarPositionEditorPage({
    required this.imageProvider,
    required this.initialFraming,
    required this.title,
    required this.applyLabel,
    required this.cancelLabel,
  });

  final ImageProvider imageProvider;
  final _AvatarFramingData initialFraming;
  final String title;
  final String applyLabel;
  final String cancelLabel;

  @override
  State<_AvatarPositionEditorPage> createState() =>
      _AvatarPositionEditorPageState();
}

class _AvatarPositionEditorPageState extends State<_AvatarPositionEditorPage> {
  static const double _fallbackMinScale = 0.5;
  static const double _maxScale = 4;

  late Alignment _initialAlignment;
  late double _scale;
  late Offset _offset;
  bool _initializedTransform = false;
  double _imageAspectRatio = 1.0;
  double? _gestureStartScale;
  Offset? _gestureStartOffset;
  Offset? _gestureStartFocalPoint;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialFraming.scale;
    _offset = Offset.zero;
    _initialAlignment = widget.initialFraming.alignment;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageStream == null) {
      _resolveImageAspectRatio();
    }
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    super.dispose();
  }

  void _resolveImageAspectRatio() {
    _imageStream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    _imageStreamListener = ImageStreamListener((imageInfo, _) {
      final width = imageInfo.image.width.toDouble();
      final height = imageInfo.image.height.toDouble();
      if (!mounted || height <= 0 || width <= 0) {
        return;
      }
      final nextRatio = width / height;
      if ((_imageAspectRatio - nextRatio).abs() < 0.0001) {
        return;
      }
      setState(() {
        _imageAspectRatio = nextRatio;
      });
    });
    _imageStream!.addListener(_imageStreamListener!);
  }

  Size _baseImageSizeForContain(Size viewport) {
    final viewportAspect = viewport.width / viewport.height;
    if (_imageAspectRatio > viewportAspect) {
      final width = viewport.width;
      final height = width / _imageAspectRatio;
      return Size(width, height);
    }
    final height = viewport.height;
    final width = height * _imageAspectRatio;
    return Size(width, height);
  }

  double _minScaleForCircle(Size viewport, double circleRadius) {
    final base = _baseImageSizeForContain(viewport);
    final neededWidthScale = (circleRadius * 2) / base.width;
    final neededHeightScale = (circleRadius * 2) / base.height;
    return [
      neededWidthScale,
      neededHeightScale,
      _fallbackMinScale,
    ].reduce((a, b) => a > b ? a : b);
  }

  Offset _maxPanForCircle(Size viewport, double circleRadius, double scale) {
    final base = _baseImageSizeForContain(viewport);
    final width = base.width * scale;
    final height = base.height * scale;
    final maxX = ((width - (circleRadius * 2)) / 2).clamp(0.0, double.infinity);
    final maxY = ((height - (circleRadius * 2)) / 2).clamp(
      0.0,
      double.infinity,
    );
    return Offset(maxX, maxY);
  }

  Offset _clampOffsetToCoverage(
    Offset offset, {
    required Size viewport,
    required double circleRadius,
    required double scale,
  }) {
    final maxPan = _maxPanForCircle(viewport, circleRadius, scale);
    return Offset(
      offset.dx.clamp(-maxPan.dx, maxPan.dx),
      offset.dy.clamp(-maxPan.dy, maxPan.dy),
    );
  }

  Alignment _alignmentFromOffset(
    Offset offset, {
    required Size viewport,
    required double circleRadius,
    required double scale,
  }) {
    final maxPan = _maxPanForCircle(viewport, circleRadius, scale);
    final ax = maxPan.dx <= 0 ? 0.0 : (offset.dx / maxPan.dx).clamp(-1.0, 1.0);
    final ay = maxPan.dy <= 0 ? 0.0 : (offset.dy / maxPan.dy).clamp(-1.0, 1.0);
    return Alignment(ax, ay);
  }

  Offset _offsetFromAlignment(
    Alignment alignment, {
    required Size viewport,
    required double circleRadius,
    required double scale,
  }) {
    final maxPan = _maxPanForCircle(viewport, circleRadius, scale);
    return Offset(alignment.x * maxPan.dx, alignment.y * maxPan.dy);
  }

  _ResolvedEditorState _resolveForViewport(Size viewport, double circleRadius) {
    final minScale = _minScaleForCircle(viewport, circleRadius);
    final sourceScale = _initializedTransform
        ? _scale
        : widget.initialFraming.scaleMode == AvatarScaleMode.relativeZoom
        ? widget.initialFraming.scale * minScale
        : widget.initialFraming.scale;
    final resolvedScale = sourceScale.clamp(minScale, _maxScale);

    final sourceOffset = _initializedTransform
        ? _offset
        : _offsetFromAlignment(
            _initialAlignment,
            viewport: viewport,
            circleRadius: circleRadius,
            scale: resolvedScale,
          );
    final resolvedOffset = _clampOffsetToCoverage(
      sourceOffset,
      viewport: viewport,
      circleRadius: circleRadius,
      scale: resolvedScale,
    );
    return _ResolvedEditorState(
      scale: resolvedScale,
      offset: resolvedOffset,
      minScale: minScale,
    );
  }

  void _handleScaleStart(
    ScaleStartDetails details,
    Size viewport,
    double circleRadius,
  ) {
    final resolved = _resolveForViewport(viewport, circleRadius);
    if (!_initializedTransform) {
      _initializedTransform = true;
      _scale = resolved.scale;
      _offset = resolved.offset;
    }
    _gestureStartScale = _scale;
    _gestureStartOffset = _offset;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  void _handleScaleUpdate(
    ScaleUpdateDetails details,
    Size viewport,
    double circleRadius,
  ) {
    final startScale = _gestureStartScale;
    final startOffset = _gestureStartOffset;
    final startFocalPoint = _gestureStartFocalPoint;
    if (startScale == null || startOffset == null || startFocalPoint == null) {
      return;
    }
    final resolved = _resolveForViewport(viewport, circleRadius);
    final nextScale = (startScale * details.scale).clamp(
      resolved.minScale,
      _maxScale,
    );
    final panDelta = details.localFocalPoint - startFocalPoint;
    final nextOffset = _clampOffsetToCoverage(
      startOffset + panDelta,
      viewport: viewport,
      circleRadius: circleRadius,
      scale: nextScale,
    );
    setState(() {
      _initializedTransform = true;
      _scale = nextScale;
      _offset = nextOffset;
    });
  }

  Widget _buildTransformedImage({
    required Size viewport,
    required double scale,
    required Offset offset,
    Color? tintColor,
    BlendMode? tintBlendMode,
  }) {
    final base = _baseImageSizeForContain(viewport);
    return Center(
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            width: base.width,
            height: base.height,
            child: Image(
              image: widget.imageProvider,
              fit: BoxFit.fill,
              color: tintColor,
              colorBlendMode: tintBlendMode,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = Size(constraints.maxWidth, constraints.maxHeight);
            final circleDiameter = viewport.shortestSide * 0.92;
            final circleRadius = circleDiameter / 2;
            final circleCenter = Offset(
              viewport.width / 2,
              viewport.height / 2,
            );
            final resolved = _resolveForViewport(viewport, circleRadius);
            final effectiveScale = resolved.scale;
            final effectiveOffset = resolved.offset;

            return Stack(
              fit: StackFit.expand,
              children: [
                _buildTransformedImage(
                  viewport: viewport,
                  scale: effectiveScale,
                  offset: effectiveOffset,
                ),
                CustomPaint(
                  painter: _AvatarCropMaskPainter(
                    center: circleCenter,
                    radius: circleRadius,
                  ),
                  child: const SizedBox.expand(),
                ),
                GestureDetector(
                  onScaleStart: (details) =>
                      _handleScaleStart(details, viewport, circleRadius),
                  onScaleUpdate: (details) =>
                      _handleScaleUpdate(details, viewport, circleRadius),
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 8,
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          widget.cancelLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final alignment = _alignmentFromOffset(
                            effectiveOffset,
                            viewport: viewport,
                            circleRadius: circleRadius,
                            scale: effectiveScale,
                          );
                          final relativeScale =
                              (effectiveScale / resolved.minScale).clamp(
                                1.0,
                                _maxScale,
                              );
                          Navigator.of(context).pop(
                            _AvatarFramingData(
                              alignment: alignment,
                              scale: relativeScale,
                              scaleMode: AvatarScaleMode.relativeZoom,
                            ),
                          );
                        },
                        child: Text(
                          widget.applyLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResolvedEditorState {
  const _ResolvedEditorState({
    required this.scale,
    required this.offset,
    required this.minScale,
  });

  final double scale;
  final Offset offset;
  final double minScale;
}

class _AvatarFramingData {
  const _AvatarFramingData({
    required this.alignment,
    required this.scale,
    this.scaleMode = AvatarScaleMode.relativeZoom,
  });

  final Alignment alignment;
  final double scale;
  final AvatarScaleMode scaleMode;
}

class _AvatarCropMaskPainter extends CustomPainter {
  const _AvatarCropMaskPainter({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final dimPath = Path()..addRect(fullRect);
    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final overlay = Path.combine(PathOperation.difference, dimPath, holePath);
    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.70),
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarCropMaskPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
  }
}

class _CompressedImage {
  _CompressedImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}
