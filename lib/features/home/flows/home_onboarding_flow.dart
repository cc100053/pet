part of '../home_view.dart';

extension _HomeOnboardingFlow on _HomeViewState {
  static const String _stepProfileSetup = 'profile_setup';
  static const String _stepCreatePet = 'create_pet';
  static const String _stepInviteFriend = 'invite_friend';
  static const String _stepFeedOnce = 'feed_once';
  static const String _stepCompleted = 'completed';

  bool get _isDebugForceOnboardingActive {
    return _isDebugAdmin && _debugAlwaysShowOnboarding;
  }

  bool get _isBasicOnboardingActive {
    if (!_basicOnboardingReady) {
      return false;
    }
    if (_isDebugForceOnboardingActive) {
      return !_debugForceOnboardingHidden;
    }
    return !_basicOnboardingDismissed && !_basicOnboardingCompleted;
  }

  bool get _isProfileSetupOnboardingStepActive {
    return _isBasicOnboardingActive &&
        _basicOnboardingStep == _BasicOnboardingStep.profileSetup &&
        _showRoomSelection;
  }

  bool get _isCreatePetOnboardingStepActive {
    return _isBasicOnboardingActive &&
        _basicOnboardingStep == _BasicOnboardingStep.createPet &&
        _showRoomSelection;
  }

  bool get _shouldShowCreatePetOnboardingCoachCard {
    return _isCreatePetOnboardingStepActive && !_loadingRoom;
  }

  String get _defaultProfileNickname {
    return AppLocalizations.of(context)!.profileDefaultNickname.trim();
  }

  bool get _isProfileSetupComplete {
    final nickname = (_myNickname ?? '').trim();
    return nickname.isNotEmpty && nickname != _defaultProfileNickname;
  }

  Future<void> _loadBasicOnboardingState() async {
    final settings = AppSettingsRepository.instance;
    final dismissed = settings.onboardingBasicDismissed;
    final completed = settings.onboardingBasicCompleted;
    final storedStep = settings.onboardingBasicCurrentStep;
    final startedAt = settings.onboardingBasicStartedAt;
    final isFreshOnboarding =
        !dismissed &&
        !completed &&
        startedAt == null &&
        (storedStep == null || storedStep.isEmpty);

    var step = isFreshOnboarding
        ? _BasicOnboardingStep.profileSetup
        : _parseBasicOnboardingStep(storedStep);
    if (completed) {
      step = _BasicOnboardingStep.completed;
    }

    if (!dismissed && !completed && startedAt == null) {
      await settings.setOnboardingBasicStartedAt(DateTime.now().toUtc());
    }

    if (!mounted) {
      _basicOnboardingDismissed = dismissed;
      _basicOnboardingCompleted = completed;
      _basicOnboardingStep = step;
      _basicOnboardingReady = true;
      _syncOnboardingProfileDraftFromCurrentData();
      return;
    }

    _setStateForOnboarding(() {
      _basicOnboardingDismissed = dismissed;
      _basicOnboardingCompleted = completed;
      _basicOnboardingStep = step;
      _basicOnboardingReady = true;
    });
    _syncOnboardingProfileDraftFromCurrentData();
    _applyDebugOnboardingOverrideIfNeeded();
    _evaluateBasicOnboardingAgainstCurrentData();
  }

  Future<void> _dismissBasicOnboarding() async {
    if (!_basicOnboardingReady) {
      return;
    }
    if (_isDebugForceOnboardingActive) {
      if (mounted) {
        _setStateForOnboarding(() {
          _debugForceOnboardingHidden = true;
        });
      } else {
        _debugForceOnboardingHidden = true;
      }
      return;
    }
    if (_basicOnboardingDismissed) {
      return;
    }
    if (mounted) {
      _setStateForOnboarding(() {
        _basicOnboardingDismissed = true;
      });
    } else {
      _basicOnboardingDismissed = true;
    }
    final settings = AppSettingsRepository.instance;
    await settings.setOnboardingBasicDismissed(true);
  }

  Future<void> _markCreatePetOnboardingStepCompleted() async {
    if (!_basicOnboardingReady ||
        _basicOnboardingDismissed ||
        _basicOnboardingCompleted ||
        _basicOnboardingStep != _BasicOnboardingStep.createPet) {
      return;
    }

    await _advanceBasicOnboardingTo(_BasicOnboardingStep.inviteFriend);
  }

  void _evaluateBasicOnboardingAgainstCurrentData() {
    if (!_basicOnboardingReady ||
        _basicOnboardingDismissed ||
        _basicOnboardingCompleted) {
      return;
    }
    if (_isDebugForceOnboardingActive) {
      return;
    }

    if (_basicOnboardingStep == _BasicOnboardingStep.profileSetup &&
        _isProfileSetupComplete) {
      unawaited(_advanceBasicOnboardingTo(_BasicOnboardingStep.createPet));
      return;
    }

    final hasAnyRoom = _myRooms.isNotEmpty;
    if (_basicOnboardingStep == _BasicOnboardingStep.createPet && hasAnyRoom) {
      unawaited(_advanceBasicOnboardingTo(_BasicOnboardingStep.inviteFriend));
    }
  }

  Future<void> _advanceBasicOnboardingTo(_BasicOnboardingStep nextStep) async {
    if (_basicOnboardingStep == nextStep &&
        (nextStep != _BasicOnboardingStep.completed ||
            _basicOnboardingCompleted)) {
      return;
    }

    final completed = nextStep == _BasicOnboardingStep.completed;
    if (mounted) {
      _setStateForOnboarding(() {
        _basicOnboardingStep = nextStep;
        _basicOnboardingCompleted = completed;
      });
    } else {
      _basicOnboardingStep = nextStep;
      _basicOnboardingCompleted = completed;
    }

    final settings = AppSettingsRepository.instance;
    await settings.setOnboardingBasicCurrentStep(
      _basicOnboardingStepStorageValue(nextStep),
    );
    await settings.setOnboardingBasicCompleted(completed);
    if (completed) {
      await settings.setOnboardingBasicCompletedAt(DateTime.now().toUtc());
    }
  }

  void _applyDebugOnboardingOverrideIfNeeded() {
    if (!_basicOnboardingReady || !_isDebugForceOnboardingActive) {
      return;
    }
    final needsReset =
        _basicOnboardingStep != _BasicOnboardingStep.profileSetup ||
        _basicOnboardingDismissed ||
        _basicOnboardingCompleted;
    if (!needsReset) {
      return;
    }
    if (mounted) {
      _setStateForOnboarding(() {
        _basicOnboardingStep = _BasicOnboardingStep.profileSetup;
        _basicOnboardingDismissed = false;
        _basicOnboardingCompleted = false;
      });
      _syncOnboardingProfileDraftFromCurrentData(overwriteExistingText: true);
      return;
    }
    _basicOnboardingStep = _BasicOnboardingStep.profileSetup;
    _basicOnboardingDismissed = false;
    _basicOnboardingCompleted = false;
    _syncOnboardingProfileDraftFromCurrentData(overwriteExistingText: true);
  }

  String _basicOnboardingStepStorageValue(_BasicOnboardingStep step) {
    return switch (step) {
      _BasicOnboardingStep.profileSetup => _stepProfileSetup,
      _BasicOnboardingStep.createPet => _stepCreatePet,
      _BasicOnboardingStep.inviteFriend => _stepInviteFriend,
      _BasicOnboardingStep.feedOnce => _stepFeedOnce,
      _BasicOnboardingStep.completed => _stepCompleted,
    };
  }

  _BasicOnboardingStep _parseBasicOnboardingStep(String? raw) {
    return switch (raw) {
      _stepProfileSetup => _BasicOnboardingStep.profileSetup,
      'open_room' => _BasicOnboardingStep.inviteFriend,
      _stepInviteFriend => _BasicOnboardingStep.inviteFriend,
      _stepFeedOnce => _BasicOnboardingStep.feedOnce,
      _stepCompleted => _BasicOnboardingStep.completed,
      _ => _BasicOnboardingStep.createPet,
    };
  }

  void _syncOnboardingProfileDraftFromCurrentData({
    bool overwriteExistingText = false,
  }) {
    final currentNickname = (_myNickname ?? '').trim();
    final resolvedNickname = currentNickname.isEmpty
        ? _defaultProfileNickname
        : currentNickname;
    final currentText = _onboardingProfileNicknameController.text.trim();
    final shouldOverwrite =
        overwriteExistingText ||
        currentText.isEmpty ||
        currentText == _defaultProfileNickname;

    if (shouldOverwrite &&
        _onboardingProfileNicknameController.text != resolvedNickname) {
      _onboardingProfileNicknameController
        ..text = resolvedNickname
        ..selection = TextSelection.collapsed(offset: resolvedNickname.length);
    }

    final resolvedAvatar = _myAvatarUrl?.trim();
    if (overwriteExistingText ||
        ((_onboardingProfileAvatarUrl ?? '').trim().isEmpty &&
            (resolvedAvatar ?? '').isNotEmpty)) {
      _onboardingProfileAvatarUrl = resolvedAvatar;
    }
  }

  Future<void> _completeProfileSetupOnboarding() async {
    if (_onboardingProfileSaving) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final nickname = _onboardingProfileNicknameController.text.trim();
    if (nickname.isEmpty) {
      _setStateForOnboarding(() {
        _onboardingProfileError = l10n.onboardingProfileSetupNameRequiredError;
      });
      return;
    }
    if (nickname == _defaultProfileNickname) {
      _setStateForOnboarding(() {
        _onboardingProfileError = l10n.onboardingProfileSetupNameChangeHint;
      });
      return;
    }

    _setStateForOnboarding(() {
      _onboardingProfileSaving = true;
      _onboardingProfileError = null;
    });

    try {
      await _withNetworkTimeout(
        Supabase.instance.client
            .from('profiles')
            .update({'nickname': nickname})
            .eq('user_id', user.id),
      );
      _myNickname = nickname;
      ProfileCacheService.instance.prime(
        ProfileSummary(
          userId: user.id,
          nickname: nickname,
          avatarUrl: _myAvatarUrl,
        ),
      );
      await _cacheHomeBootstrapSnapshot();
      await _advanceBasicOnboardingTo(_BasicOnboardingStep.createPet);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _setStateForOnboarding(() {
        _onboardingProfileError = userFacingError(
          context,
          error,
          stackTrace: stackTrace,
          source: 'home_onboarding_profile_save',
        );
      });
    } finally {
      if (mounted) {
        _setStateForOnboarding(() {
          _onboardingProfileSaving = false;
        });
      } else {
        _onboardingProfileSaving = false;
      }
    }
  }

  Future<_HomeOnboardingCompressedImage> _compressOnboardingAvatar(
    XFile image,
  ) async {
    final originalBytes = await image.readAsBytes();
    if (kIsWeb) {
      return _HomeOnboardingCompressedImage(
        bytes: originalBytes,
        contentType: 'image/jpeg',
      );
    }

    try {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        quality: _HomeViewState._onboardingAvatarWebpQuality,
        minWidth: _HomeViewState._onboardingAvatarMaxDimension,
        minHeight: _HomeViewState._onboardingAvatarMaxDimension,
        format: CompressFormat.webp,
      );
      if (compressedBytes != null && compressedBytes.isNotEmpty) {
        return _HomeOnboardingCompressedImage(
          bytes: compressedBytes,
          contentType: 'image/webp',
        );
      }
    } catch (_) {
      // Best effort.
    }

    return _HomeOnboardingCompressedImage(
      bytes: originalBytes,
      contentType: 'image/jpeg',
    );
  }

  Future<AvatarFramingData?> _confirmOnboardingAvatarFraming(
    XFile image,
  ) async {
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

  Future<void> _uploadOnboardingProfileAvatar() async {
    if (_onboardingProfileSaving) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final XFile? image;
    try {
      // Only the pixels are needed, and skipping full metadata keeps iOS on
      // the permission-free PHPicker path.
      image = await _onboardingProfileImagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    } on PlatformException catch (error, stackTrace) {
      // A request cancelled by a competing one is not a user-visible failure;
      // the surviving request still delivers a result.
      if (error.code == 'multiple_request' || !mounted) {
        return;
      }
      _setStateForOnboarding(() {
        _onboardingProfileError = userFacingError(
          context,
          error,
          stackTrace: stackTrace,
          source: 'home_onboarding_pick_avatar',
        );
      });
      return;
    }
    if (image == null) {
      return;
    }

    late final AvatarFramingData? confirmedFraming;
    try {
      confirmedFraming = await _confirmOnboardingAvatarFraming(image);
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _setStateForOnboarding(() {
        _onboardingProfileError = userFacingError(
          context,
          error,
          stackTrace: stackTrace,
          source: 'home_onboarding_avatar_framing_preview',
        );
      });
      return;
    }
    if (!mounted || confirmedFraming == null) {
      return;
    }

    _setStateForOnboarding(() {
      _onboardingProfileSaving = true;
      _onboardingProfileError = null;
    });

    try {
      final compressed = await _compressOnboardingAvatar(image);
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

      Future<String> invokeAndGetUploadedUrl(
        String token,
        String operation,
      ) async {
        final response = await _withNetworkTimeout(invokeWithToken(token));
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

      late final String uploadedAvatarUrl;
      try {
        uploadedAvatarUrl = await invokeAndGetUploadedUrl(
          accessToken,
          'avatar_upload',
        );
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
        uploadedAvatarUrl = await invokeAndGetUploadedUrl(
          refreshedToken,
          'avatar_upload_retry',
        );
      }

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
        );
      }

      _myAvatarUrl = framedAvatarUrl;
      _onboardingProfileAvatarUrl = framedAvatarUrl;
      ProfileCacheService.instance.prime(
        ProfileSummary(
          userId: user.id,
          nickname: _myNickname,
          avatarUrl: framedAvatarUrl,
        ),
      );
      await _cacheHomeBootstrapSnapshot();
    } catch (error, stackTrace) {
      if (!mounted) {
        return;
      }
      _setStateForOnboarding(() {
        _onboardingProfileError = userFacingError(
          context,
          error,
          stackTrace: stackTrace,
          source: 'home_onboarding_avatar_upload',
        );
      });
    } finally {
      if (mounted) {
        _setStateForOnboarding(() {
          _onboardingProfileSaving = false;
        });
      } else {
        _onboardingProfileSaving = false;
      }
    }
  }

  Widget _buildProfileSetupOnboardingOverlay() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final avatar = _onboardingProfileAvatarUrl ?? _myAvatarUrl;
    final fallbackText = _onboardingProfileNicknameController.text.trim();

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.44),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: formScrollKeyboardDismissBehavior,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFFFFFCF5), Color(0xFFFFF1D7)],
                    ),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.88),
                      width: 1.4,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      22 * scale,
                      24 * scale,
                      22 * scale,
                      22 * scale,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          l10n.onboardingProfileSetupTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        Text(
                          l10n.onboardingProfileSetupSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: 22 * scale),
                        GestureDetector(
                          onTap: _onboardingProfileSaving
                              ? null
                              : _uploadOnboardingProfileAvatar,
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 88 * scale,
                                height: 88 * scale,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.26,
                                    ),
                                    width: 1.4,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                                child: UserAvatar(
                                  avatar: avatar,
                                  fallbackText: fallbackText.isEmpty
                                      ? null
                                      : fallbackText,
                                  size: 80 * scale,
                                ),
                              ),
                              SizedBox(height: 10 * scale),
                              TextButton.icon(
                                onPressed: _onboardingProfileSaving
                                    ? null
                                    : _uploadOnboardingProfileAvatar,
                                icon: const Icon(
                                  Icons.photo_camera_back_outlined,
                                ),
                                label: Text(l10n.profileAvatarUpload),
                              ),
                              Text(
                                l10n.onboardingProfileSetupAvatarOptional,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18 * scale),
                        TextField(
                          controller: _onboardingProfileNicknameController,
                          onTapOutside: dismissKeyboardOnTapOutside,
                          enabled: !_onboardingProfileSaving,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          inputFormatters: <TextInputFormatter>[
                            LengthLimitingTextInputFormatter(
                              _HomeViewState._profileNicknameMaxLength,
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.profileNicknameLabel,
                            hintText: _defaultProfileNickname,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.72),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) {
                            if (_onboardingProfileError != null && mounted) {
                              _setStateForOnboarding(() {
                                _onboardingProfileError = null;
                              });
                            }
                          },
                          onSubmitted: (_) =>
                              unawaited(_completeProfileSetupOnboarding()),
                        ),
                        if (_onboardingProfileError != null) ...<Widget>[
                          SizedBox(height: 10 * scale),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _onboardingProfileError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 18 * scale),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _onboardingProfileSaving
                                ? null
                                : _completeProfileSetupOnboarding,
                            style: FilledButton.styleFrom(
                              minimumSize: Size.fromHeight(52 * scale),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _onboardingProfileSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.onboardingProfileSetupContinue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicOnboardingCoachCard() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomOffset = (92 * scale) + bottomInset;
    final title = l10n.onboardingRoomEntryPromptTitle;
    final body = l10n.onboardingRoomEntryPromptBody;
    const icon = Icons.meeting_room_rounded;
    final cardRadius = BorderRadius.circular(24);
    final horizontalPadding = 18 * scale;
    final verticalPadding = 16 * scale;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 12),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: cardRadius,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFFFFFCF4),
                        Color(0xFFFFF4DB),
                        Color(0xFFFFE8B8),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.92),
                      width: 1.4,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFFE7B754).withValues(alpha: 0.22),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      16 * scale,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 42 * scale,
                          height: 42 * scale,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                AppTheme.primaryColor.withValues(alpha: 0.24),
                                AppTheme.secondaryColor.withValues(alpha: 0.18),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.85),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: AppTheme.primaryColor,
                            size: 22 * scale,
                          ),
                        ),
                        SizedBox(width: 12 * scale),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              Text(
                                body,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10 * scale),
                        OutlinedButton(
                          onPressed: _dismissBasicOnboarding,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.52,
                            ),
                            side: BorderSide(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.16,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14 * scale,
                              vertical: 12 * scale,
                            ),
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: Size(0, 44 * scale),
                          ),
                          child: Text(l10n.commonSkip),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -9,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.rotate(
                      angle: 0.78539816339,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDC1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.secondaryColor.withValues(
                              alpha: 0.82,
                            ),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicOnboardingFocusOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Builder(
          builder: (overlayContext) {
            final targetRects = _resolveOnboardingFocusRects(overlayContext);
            if (targetRects.isEmpty) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: _OnboardingFocusPainter(
                targetRects: targetRects
                    .map((rect) => rect.inflate(6))
                    .toList(growable: false),
                cornerRadius: 28,
              ),
            );
          },
        ),
      ),
    );
  }

  List<Rect> _resolveOnboardingFocusRects(BuildContext overlayContext) {
    if (_isCreatePetOnboardingStepActive) {
      return resolveOnboardingFocusTargetRects(
        overlayContext: overlayContext,
        targetKeys: <GlobalKey>[
          _onboardingCreateRoomCtaKey,
          _onboardingJoinRoomCtaKey,
        ],
      );
    }
    return const <Rect>[];
  }
}

class _OnboardingFocusPainter extends CustomPainter {
  const _OnboardingFocusPainter({
    required this.targetRects,
    required this.cornerRadius,
  });

  final List<Rect> targetRects;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    for (final targetRect in targetRects) {
      final focusRRect = RRect.fromRectAndRadius(
        targetRect,
        Radius.circular(cornerRadius),
      );
      canvas.drawRRect(focusRRect, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    for (final targetRect in targetRects) {
      final focusRRect = RRect.fromRectAndRadius(
        targetRect,
        Radius.circular(cornerRadius),
      );
      canvas.drawRRect(
        focusRRect.inflate(2),
        Paint()
          ..color = AppTheme.secondaryColor.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingFocusPainter oldDelegate) {
    return !listEquals(oldDelegate.targetRects, targetRects) ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

class _HomeOnboardingCompressedImage {
  const _HomeOnboardingCompressedImage({
    required this.bytes,
    required this.contentType,
  });

  final List<int> bytes;
  final String contentType;
}
