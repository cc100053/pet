import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future<void> _uploadAvatar() async {
    if (_busy) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
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

  Future<void> _showAvatarActions() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileAvatarTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: UserAvatar.presetCount,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: _busy
                          ? null
                          : () {
                              Navigator.pop(context);
                              _setAvatarPreset(index);
                            },
                      borderRadius: BorderRadius.circular(999),
                      child: Center(
                        child: UserAvatar(
                          avatar: '${UserAvatar.presetPrefix}$index',
                          fallbackText: null,
                          size: 44,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.pop(context);
                                _uploadAvatar();
                              },
                        icon: const Icon(Icons.upload),
                        label: Text(l10n.profileAvatarUpload),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.pop(context);
                                _removeAvatar();
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                        child: Text(l10n.profileAvatarRemove),
                      ),
                    ),
                  ],
                ),
              ],
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
          final coins = profile['coins'] as int?;
          final userId = profile['user_id']?.toString();
          final avatarFallback = nickname.trim().isNotEmpty ? nickname : userId;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    UserAvatar(
                      avatar: avatar,
                      fallbackText: avatarFallback,
                      size: 104,
                    ),
                    Material(
                      elevation: 2,
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _busy ? null : _showAvatarActions,
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: l10n.profileAvatarEdit,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileNicknameLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          labelText: l10n.profileNicknameLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _busy ? null : _saveProfile,
                              child: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(l10n.commonSave),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coins != null)
                        Text(
                          l10n.profileCoinsLabel(coins),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      if (userId != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.profileUserId(userId),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.profileDeleteAccountSectionTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppTheme.errorColor),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileDeleteAccountSectionBody,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                onPressed: _busy ? null : _confirmDeleteAccount,
                child: Text(l10n.profileDeleteAccountAction),
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
