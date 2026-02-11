import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth/session_utils.dart';
import '../../services/iap/revenuecat_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/app_dialog.dart';
import '../../shared/ui/user_avatar.dart';
import '../../shared/utils/avatar_adjust_source.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const int _avatarMaxDimension = 512;
  static const int _avatarWebpQuality = 70;

  final _picker = ImagePicker();
  final _nicknameController = TextEditingController();
  Future<Map<String, dynamic>?>? _profileFuture;
  bool _busy = false;

  bool get _isCropperSupportedPlatform {
    if (kIsWeb) {
      return true;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('user_id,nickname,avatar_url,coins,locale,timezone')
        .eq('user_id', user.id)
        .maybeSingle();

    if (profile != null) {
      return profile;
    }

    await Supabase.instance.client.from('profiles').insert({
      'user_id': user.id,
      'nickname': defaultNickname,
    });

    return Supabase.instance.client
        .from('profiles')
        .select('user_id,nickname,avatar_url,coins,locale,timezone')
        .eq('user_id', user.id)
        .maybeSingle();
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
    if (nickname.isEmpty) {
      return;
    }

    setState(() => _busy = true);
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'nickname': nickname})
          .eq('user_id', user.id);
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

  Future<XFile?> _cropAvatarSource({
    required String sourcePath,
    String? imageName,
    String? mimeType,
    bool fallbackToSourceOnFailure = false,
  }) async {
    if (!mounted) {
      return null;
    }
    if (!_isCropperSupportedPlatform) {
      if (fallbackToSourceOnFailure) {
        return XFile(sourcePath, name: imageName, mimeType: mimeType);
      }
      return null;
    }

    final l10n = AppLocalizations.of(context)!;
    CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 2048,
        maxHeight: 2048,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: l10n.profileAvatarEdit,
            cropStyle: CropStyle.circle,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: l10n.profileAvatarEdit,
            cropStyle: CropStyle.circle,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: true,
            rotateClockwiseButtonHidden: true,
          ),
          if (kIsWeb)
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.page,
              size: const CropperSize(width: 420, height: 420),
            ),
        ],
      );
    } on MissingPluginException catch (_) {
      if (fallbackToSourceOnFailure) {
        return XFile(sourcePath, name: imageName, mimeType: mimeType);
      }
      return null;
    } on PlatformException catch (_) {
      if (fallbackToSourceOnFailure) {
        return XFile(sourcePath, name: imageName, mimeType: mimeType);
      }
      return null;
    }

    if (cropped == null) {
      return null;
    }

    return XFile(cropped.path, name: imageName, mimeType: mimeType);
  }

  Future<XFile?> _pickAndAdjustAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return null;
    }

    return _cropAvatarSource(
      sourcePath: image.path,
      imageName: image.name,
      mimeType: image.mimeType,
      fallbackToSourceOnFailure: true,
    );
  }

  bool _isRemoteAvatarUrl(String? avatarUrl) {
    final value = (avatarUrl ?? '').trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  int? _activePresetId(String? avatarUrl) {
    final value = (avatarUrl ?? '').trim();
    if (!value.startsWith(UserAvatar.presetPrefix)) {
      return null;
    }
    return int.tryParse(value.substring(UserAvatar.presetPrefix.length));
  }

  Future<void> _adjustCurrentAvatar(String? currentAvatarUrl) async {
    if (_busy) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    if (!_isCropperSupportedPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileAvatarAdjustUnsupportedPlatform)),
      );
      return;
    }
    if (!_isRemoteAvatarUrl(currentAvatarUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileAvatarAdjustUnavailable)),
      );
      return;
    }

    final sourcePath = await resolveAvatarAdjustSourcePath(
      currentAvatarUrl!.trim(),
    );
    if (!mounted) {
      return;
    }
    if (sourcePath == null || sourcePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileAvatarAdjustUnavailable)),
      );
      return;
    }

    final adjusted = await _cropAvatarSource(
      sourcePath: sourcePath,
      imageName: 'avatar_adjusted.jpg',
      mimeType: 'image/jpeg',
    );
    if (adjusted == null) {
      return;
    }

    await _uploadAvatarFile(adjusted);
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
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': '${UserAvatar.presetPrefix}$presetId'})
          .eq('user_id', user.id);
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
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('user_id', user.id);
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

  Future<void> _uploadAvatarFile(XFile image) async {
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

      try {
        final response = await invokeWithToken(accessToken);
        if (response.status < 200 || response.status >= 300) {
          throw Exception(
            'avatar_upload_failed:${responseErrorSummary(response)}',
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
          final response = await invokeWithToken(refreshedToken);
          if (response.status < 200 || response.status >= 300) {
            throw Exception(
              'avatar_upload_failed:${responseErrorSummary(response)}',
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
    final image = await _pickAndAdjustAvatar();
    if (image == null) {
      return;
    }
    await _uploadAvatarFile(image);
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

      try {
        await invokeWithToken(accessToken);
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          await invokeWithToken(refreshedToken);
        } else {
          rethrow;
        }
      }

      await RevenueCatService().logOut();
      await Supabase.instance.client.auth.signOut();
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
                      onPressed:
                          _busy ||
                              !_isCropperSupportedPlatform ||
                              !_isRemoteAvatarUrl(currentAvatarUrl)
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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.18),
                      Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
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
                          size: 92,
                        ),
                        Material(
                          elevation: 1,
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _busy
                                ? null
                                : () => _showAvatarActions(avatar),
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            tooltip: l10n.profileAvatarEdit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nickname.isEmpty
                                ? l10n.profileDefaultNickname
                                : nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileNicknameLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nickname.isEmpty
                            ? l10n.profileDefaultNickname
                            : nickname,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _showNicknamePrompt(nickname),
                          icon: const Icon(Icons.edit_rounded),
                          label: Text(l10n.profileNicknameLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                margin: EdgeInsets.zero,
                color: const Color(0xFFFFF3F1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileDeleteAccountSectionTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.profileDeleteAccountSectionBody,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                          ),
                          onPressed: _busy ? null : _confirmDeleteAccount,
                          child: Text(l10n.profileDeleteAccountAction),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompressedImage {
  _CompressedImage({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}
