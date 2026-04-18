import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth/session_utils.dart';
import '../../services/env.dart';
import '../../services/profile/profile_bootstrap_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/localization/app_locale_controller.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/upload_limits.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/avatar_position_editor_page.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/keyboard_dismiss_utils.dart';
import '../../shared/ui/status_bar_style.dart';
import '../../shared/ui/user_avatar.dart';
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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
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
    setState(_reloadProfileFuture);
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
    _profileFuture ??= _createProfileFuture();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _createProfileFuture() {
    return _loadProfile(
      defaultNickname: AppLocalizations.of(context)!.profileDefaultNickname,
    );
  }

  void _reloadProfileFuture() {
    _profileFuture = _createProfileFuture();
  }

  Future<Map<String, dynamic>?> _loadProfile({
    required String defaultNickname,
  }) async {
    try {
      return await _withNetworkTimeout(
        ProfileBootstrapService.instance.ensureProfile(
          defaultNickname: defaultNickname,
          selectClause: 'user_id,nickname,avatar_url,coins,locale,timezone',
        ),
        operation: 'load_profile',
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

    showJuiceSnackbar(
      context: context,
      message: AppLocalizations.of(context)!.profileUpdated,
      tone: AppDialogTone.success,
    );

    setState(_reloadProfileFuture);
  }

  Future<void> _showNicknamePrompt(String currentNickname) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _nicknameController
      ..text = currentNickname
      ..selection = TextSelection.collapsed(offset: currentNickname.length);

    final shouldSave = await showJuiceToast<bool>(
      context: context,
      message: l10n.profileNicknameLabel,
      position: JuicePosition.center,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nicknameController,
            onTapOutside: dismissKeyboardOnTapOutside,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: GoogleFonts.mPlusRounded1c(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(_nicknameMaxLength),
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
              ),
            ),
            onSubmitted: (_) => Navigator.of(context).pop(true),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonCancel,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD600),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonSave,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
    } catch (error, stackTrace) {
      if (mounted) {
        showJuiceToast(
          context: context,
          message: userFacingError(
            context,
            error,
            stackTrace: stackTrace,
            source: 'profile_avatar_framing',
          ),
          tone: AppDialogTone.danger,
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }

    if (!mounted) {
      return;
    }

    showJuiceSnackbar(
      context: context,
      message: AppLocalizations.of(context)!.profileUpdated,
      tone: AppDialogTone.success,
    );

    setState(_reloadProfileFuture);
  }

  Future<void> _adjustCurrentAvatar(String? currentAvatarUrl) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    if (!_isRemoteAvatarUrl(currentAvatarUrl)) {
      showJuiceSnackbar(
        context: context,
        message: l10n.profileAvatarAdjustUnavailable,
        tone: AppDialogTone.warning,
      );
      return;
    }

    final parsed = parseAvatarUrlWithAlignment(currentAvatarUrl!.trim());
    final confirmedFraming = await Navigator.of(context)
        .push<AvatarFramingData>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (routeContext) => AvatarPositionEditorPage(
              imageProvider: NetworkImage(parsed.imageUrl),
              initialFraming: AvatarFramingData(
                alignment: parsed.alignment,
                scale: parsed.scale,
              ),
              title: l10n.profileAvatarAdjustCurrent,
              applyLabel: l10n.commonSave,
              cancelLabel: l10n.commonCancel,
              hintLabel: l10n.profileAvatarEditorHint,
              zoomLabel: l10n.profileAvatarEditorZoom,
              resetLabel: l10n.profileAvatarEditorCenter,
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

  Future<AvatarFramingData?> _confirmPickedAvatarFraming(XFile image) async {
    final l10n = AppLocalizations.of(context)!;
    final bytes = await image.readAsBytes();
    if (!mounted) {
      return null;
    }
    return Navigator.of(context).push<AvatarFramingData>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (routeContext) => AvatarPositionEditorPage(
          imageProvider: MemoryImage(bytes),
          initialFraming: const AvatarFramingData(
            alignment: Alignment.center,
            scale: 1,
          ),
          title: l10n.profileAvatarEdit,
          applyLabel: l10n.commonSave,
          cancelLabel: l10n.commonCancel,
          hintLabel: l10n.profileAvatarEditorHint,
          zoomLabel: l10n.profileAvatarEditorZoom,
          resetLabel: l10n.profileAvatarEditorCenter,
        ),
      ),
    );
  }

  Future<void> _saveAvatar(XFile image) async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    late final AvatarFramingData? confirmedFraming;
    try {
      confirmedFraming = await _confirmPickedAvatarFraming(image);
    } catch (error, stackTrace) {
      if (mounted) {
        showJuiceToast(
          context: context,
          message: userFacingError(
            context,
            error,
            stackTrace: stackTrace,
            source: 'profile_avatar_framing_preview',
          ),
          tone: AppDialogTone.danger,
        );
      }
      return;
    }
    if (!mounted || confirmedFraming == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final compressed = await _compressAvatar(image);
      final uploadedAvatarUrl = await _uploadAvatarViaEdgeFunction(compressed);
      final framedAvatarUrl = buildAvatarUrlWithFraming(
        uploadedAvatarUrl,
        alignment: confirmedFraming.alignment,
        scale: confirmedFraming.scale,
      );
      if (framedAvatarUrl != uploadedAvatarUrl) {
        await _withNetworkTimeout(
          Supabase.instance.client
              .from('profiles')
              .update({'avatar_url': framedAvatarUrl})
              .eq('user_id', user.id),
          operation: 'save_avatar_framing',
        );
      }
    } catch (error, stackTrace) {
      if (mounted) {
        showJuiceToast(
          context: context,
          message: userFacingError(
            context,
            error,
            stackTrace: stackTrace,
            source: 'profile_avatar_upload',
          ),
          tone: AppDialogTone.danger,
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }

    if (!mounted) {
      return;
    }

    showJuiceSnackbar(
      context: context,
      message: AppLocalizations.of(context)!.profileUpdated,
      tone: AppDialogTone.success,
    );

    setState(_reloadProfileFuture);
  }

  Future<String> _uploadAvatarViaEdgeFunction(
    _CompressedImage compressed,
  ) async {
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

    Future<String> invokeAndValidate(String token, String operation) async {
      final response = await _withNetworkTimeout(
        invokeWithToken(token),
        operation: operation,
      );
      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          'avatar_upload_failed:$operation:${responseErrorSummary(response)}',
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

    final accessToken = await ensureValidAccessToken();
    if (accessToken == null) {
      throw Exception('missing_session');
    }

    try {
      return await invokeAndValidate(accessToken, 'avatar_upload');
    } on FunctionException catch (error) {
      if (error.status != 401) {
        rethrow;
      }
      final refreshed = await ensureValidAccessTokenWithDebug(
        forceRefresh: true,
      );
      final refreshedToken = refreshed.token;
      if (refreshedToken == null) {
        rethrow;
      }
      return await invokeAndValidate(refreshedToken, 'avatar_upload_retry');
    }
  }

  Future<void> _savePresetAvatar(int presetId) async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final avatarUrl = '${UserAvatar.presetPrefix}$presetId';
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .update({'avatar_url': avatarUrl})
            .eq('user_id', user.id),
        operation: 'save_profile_preset',
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }

    if (!mounted) {
      return;
    }

    showJuiceSnackbar(
      context: context,
      message: AppLocalizations.of(context)!.profileUpdated,
      tone: AppDialogTone.success,
    );

    setState(_reloadProfileFuture);
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
        setState(() => _busy = false);
      }
    }

    if (!mounted) {
      return;
    }

    showJuiceSnackbar(
      context: context,
      message: AppLocalizations.of(context)!.profileUpdated,
      tone: AppDialogTone.success,
    );

    setState(_reloadProfileFuture);
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showJuiceToast<bool>(
      context: context,
      message: l10n.profileDeleteAccountTitle,
      position: JuicePosition.center,
      tone: AppDialogTone.danger,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.profileDeleteAccountConfirmBody,
            textAlign: TextAlign.center,
            style: GoogleFonts.mPlusRounded1c(
              color: const Color(0xFF5A4A42),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(24),
          Row(
            children: [
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.commonCancel,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: JuicyScaleButton(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        l10n.profileDeleteAccountConfirmAction,
                        style: GoogleFonts.mPlusRounded1c(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc('delete_user_account');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      unawaited(Supabase.instance.client.auth.signOut());
    } catch (error) {
      if (mounted) {
        showJuiceToast(
          context: context,
          message: AppLocalizations.of(
            context,
          )!.profileDeleteFailed(userFacingError(context, error)),
          tone: AppDialogTone.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.light,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.profileTitle,
            style: GoogleFonts.mPlusRounded1c(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isNetworkUnavailableError(snapshot.error!)
                            ? l10n.errorNetwork
                            : l10n.errorUnexpected,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Gap(16),
                      JuicyScaleButton(
                        onTap: _retryLoadProfile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.commonTryAgain,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return Center(child: Text(l10n.profileEmpty));
            }

            return _buildProfileContent(context, data, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    Map<String, dynamic> data,
    AppLocalizations l10n,
  ) {
    final avatarUrl = data['avatar_url'] as String?;
    final nickname = data['nickname'] as String? ?? '';
    final coins = data['coins'] as int? ?? 0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const Gap(32),
          _buildAvatarSection(context, avatarUrl, nickname),
          const Gap(24),
          _buildNicknameSection(context, nickname, l10n),
          const Gap(32),
          _buildInfoSection(context, coins, l10n),
          const Gap(32),
          _buildActionSection(context, l10n),
          const Gap(48),
          _buildDangerSection(context, l10n),
          const Gap(60),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(
    BuildContext context,
    String? avatarUrl,
    String nickname,
  ) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: UserAvatar(
              avatar: avatarUrl,
              fallbackText: nickname,
              size: 120,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: JuicyScaleButton(
              onTap: () => _showAvatarOptions(avatarUrl, nickname),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions(String? currentAvatarUrl, String nickname) {
    final l10n = AppLocalizations.of(context)!;
    final isRemote = _isRemoteAvatarUrl(currentAvatarUrl);
    final activePreset = _activePresetId(currentAvatarUrl);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.profileAvatarUpload),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _pickAvatar();
                  if (image != null) {
                    await _saveAvatar(image);
                  }
                },
              ),
              if (isRemote)
                ListTile(
                  leading: const Icon(Icons.aspect_ratio_rounded),
                  title: Text(l10n.profileAvatarAdjustCurrent),
                  onTap: () {
                    Navigator.pop(context);
                    _adjustCurrentAvatar(currentAvatarUrl);
                  },
                ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.profileAvatarTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: 8,
                  separatorBuilder: (_, _) => const Gap(12),
                  itemBuilder: (context, index) {
                    final presetId = index + 1;
                    final isActive = activePreset == presetId;
                    return JuicyScaleButton(
                      onTap: () {
                        Navigator.pop(context);
                        _savePresetAvatar(presetId);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: UserAvatar(
                          avatar: '${UserAvatar.presetPrefix}$presetId',
                          fallbackText: nickname,
                          size: 64,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Gap(16),
              if (currentAvatarUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                  title: Text(
                    l10n.profileAvatarRemove,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNicknameSection(
    BuildContext context,
    String nickname,
    AppLocalizations l10n,
  ) {
    return Center(
      child: JuicyScaleButton(
        onTap: () => _showNicknamePrompt(nickname),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nickname,
                style: GoogleFonts.mPlusRounded1c(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    int coins,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/shop/icon/candy.png',
                width: 24,
                height: 24,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileCoinsLabel(coins),
                    style: GoogleFonts.mPlusRounded1c(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileSectionAbout,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
            ),
          ),
          const Gap(12),
          _buildMenuTile(
            icon: Icons.feedback_outlined,
            title: l10n.profileFeedback,
            onTap: () => _openExternalUrl(_feedbackUrl(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDangerSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileSectionDangerZone,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),
          const Gap(12),
          _buildMenuTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.profileDeleteAccountAction,
            color: Colors.red,
            onTap: _confirmDeleteAccount,
          ),
          _buildMenuTile(
            icon: Icons.logout_rounded,
            title: l10n.commonSignOut,
            onTap: () {
              // Pop first for absolute zero-latency feedback
              Navigator.of(context).popUntil((route) => route.isFirst);
              unawaited(Supabase.instance.client.auth.signOut());
            },
          ),
        ],
      ),
    );
  }
}

class _CompressedImage {
  const _CompressedImage({required this.bytes, required this.contentType});
  final Uint8List bytes;
  final String contentType;
}
