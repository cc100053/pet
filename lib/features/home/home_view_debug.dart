part of 'home_view.dart';

/// Debug/diagnostics tooling for [_HomeViewState]: debug balance/hunger/EXP
/// mutations, memory snapshots, admin gating, feed test, and socket debug.
/// Extracted from home_view.dart verbatim (behavior-preserving).
extension _HomeDebugTools on _HomeViewState {
  Future<void> _debugUpdateProfileBalances({
    int coinDelta = 0,
    int diamondDelta = 0,
  }) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    if (coinDelta == 0 && diamondDelta == 0) {
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('coins,diamonds')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile == null) {
        return;
      }
      final currentCoins = (profile['coins'] as int?) ?? _coins;
      final currentDiamonds = (profile['diamonds'] as int?) ?? _diamonds;
      final updates = <String, dynamic>{};
      if (coinDelta != 0) {
        updates['coins'] = max(0, currentCoins + coinDelta);
      }
      if (diamondDelta != 0) {
        updates['diamonds'] = max(0, currentDiamonds + diamondDelta);
      }
      if (updates.isEmpty) {
        return;
      }
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('user_id', userId);
      unawaited(_loadCoins(expectedReward: coinDelta > 0 ? coinDelta : null));
    } catch (_) {
      // Best-effort debug tool.
    }
  }

  Future<void> _debugAdjustPetHunger(int delta) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _setStateForDebug(() {
      _petBusy = true;
      _petError = null;
    });
    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        _setStateForDebug(
          () => _petError = AppLocalizations.of(context)!.petNotFound,
        );
        return;
      }
      final row = await Supabase.instance.client
          .from('pet_state')
          .select('hunger')
          .eq('pet_id', petId)
          .maybeSingle();
      final current = (row?['hunger'] as int?) ?? 0;
      final next = (current + delta).clamp(0, 100);
      await Supabase.instance.client
          .from('pet_state')
          .update({'hunger': next})
          .eq('pet_id', petId);
      await _dispatchNewHungerAlerts(petId: petId, roomId: roomId);
      final updatedState = await _fetchPetState(petId);
      _applyPetStateUpdate(roomId, petId, updatedState);
    } catch (error) {
      _setStateForDebug(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) _setStateForDebug(() => _petBusy = false);
    }
  }

  Future<void> _debugSetRoomHungerFreeze(bool enabled) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _setStateForDebug(() {
      _petBusy = true;
      _petError = null;
    });
    try {
      final pausedUntil = enabled
          ? DateTime.now()
                .toUtc()
                .add(const Duration(days: 365))
                .toIso8601String()
          : null;
      await Supabase.instance.client.rpc(
        'set_room_hunger_decay_paused',
        params: {
          'p_room_id': roomId,
          'p_paused_until': pausedUntil,
          'p_reason': enabled ? 'debug_drawer_hunger_freeze' : null,
        },
      );

      final petId = _petId ?? await _loadPetId(roomId);
      if (petId != null) {
        final updatedState = await _fetchPetState(petId);
        _applyPetStateUpdate(roomId, petId, updatedState);
      }
      if (mounted) {
        showJuiceSnackbar(
          context: context,
          message: enabled
              ? 'Hunger frozen for this room'
              : 'Hunger decay restored for this room',
        );
      }
    } catch (error) {
      _setStateForDebug(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) _setStateForDebug(() => _petBusy = false);
    }
  }

  Future<void> _debugAddPetExp(int delta) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _setStateForDebug(() {
      _petBusy = true;
      _petError = null;
    });
    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        _setStateForDebug(
          () => _petError = AppLocalizations.of(context)!.petNotFound,
        );
        return;
      }
      final row = await Supabase.instance.client
          .from('pets')
          .select('level, exp')
          .eq('id', petId)
          .maybeSingle();
      final currentLevel = (row?['level'] as int?) ?? (_petLevel ?? 1);
      final currentExp = (row?['exp'] as int?) ?? (_petExp ?? 0);
      final updated = _applyExpDelta(
        level: currentLevel,
        exp: currentExp,
        delta: delta,
      );
      await Supabase.instance.client
          .from('pets')
          .update({'level': updated.level, 'exp': updated.exp})
          .eq('id', petId);
      await _loadPetInfo(petId, roomId: roomId);
    } catch (error) {
      _setStateForDebug(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) _setStateForDebug(() => _petBusy = false);
    }
  }

  Future<void> _debugSpawnPetPoop() async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (!await _ensureOnlineForWrite()) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    _setStateForDebug(() {
      _petBusy = true;
      _petError = null;
    });
    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        _setStateForDebug(
          () => _petError = AppLocalizations.of(context)!.petNotFound,
        );
        return;
      }
      final row = await Supabase.instance.client
          .from('pet_state')
          .select('poop_positions, poop_at')
          .eq('pet_id', petId)
          .maybeSingle();
      final positions = _normalizePoopPositions(row?['poop_positions']);
      if (positions.length < 3) {
        final next = _nextPoopPosition();
        positions.add({'x': next.dx, 'y': next.dy});
      }
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final updates = <String, dynamic>{
        'poop_positions': positions,
        'poop_count': positions.length,
        'last_poop_spawn_at': nowIso,
      };
      if (row?['poop_at'] == null && positions.isNotEmpty) {
        updates['poop_at'] = nowIso;
      }
      await Supabase.instance.client
          .from('pet_state')
          .update(updates)
          .eq('pet_id', petId);
      final updatedState = await _fetchPetState(petId);
      _applyPetStateUpdate(roomId, petId, updatedState);
    } catch (error) {
      _setStateForDebug(
        () => _petError = AppLocalizations.of(
          context,
        )!.petActionFailed(userFacingError(context, error)),
      );
    } finally {
      if (mounted) _setStateForDebug(() => _petBusy = false);
    }
  }

  void _debugShowOverfedBubble() {
    if (!_isDebugAdmin) {
      return;
    }
    _overfedBubbleTimer?.cancel();
    _setStateForDebug(() {
      _lastOverfedAt = DateTime.now().toUtc();
      _showOverfedBubble = true;
    });
    _overfedBubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      _setStateForDebug(() => _showOverfedBubble = false);
    });
  }

  Future<void> _captureDebugMemorySnapshot() async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(context);
    await _captureHomeMemorySnapshot(
      source: 'home_debug_manual_capture',
      note: 'debug_drawer',
    );
    if (!mounted) {
      return;
    }
    showJuiceSnackbar(
      context: context,
      message: l10n.drawerDebugMemorySnapshotCaptured,
      tone: AppDialogTone.success,
    );
  }

  Future<void> _clearImageCacheAndCaptureDebugSnapshot() async {
    final l10n = AppLocalizations.of(context)!;
    Navigator.pop(context);
    await MemoryDiagnosticsService.instance.clearImageCacheAndCapture(
      source: 'home_debug_clear_image_cache',
      route: 'home_view',
      roomId: _roomId,
      note: 'debug_drawer',
    );
    if (!mounted) {
      return;
    }
    showJuiceSnackbar(
      context: context,
      message: l10n.drawerDebugImageCacheCleared,
      tone: AppDialogTone.success,
    );
  }

  Future<void> _openMemoryDiagnosticsSheet() async {
    Navigator.pop(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => MemoryDiagnosticsSheet(
        snapshotsListenable:
            MemoryDiagnosticsService.instance.snapshotsListenable,
      ),
    );
  }

  Future<void> _setDebugProPlan(bool value) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (_debugProPlan == value) {
      return;
    }
    _setStateForDebug(() {
      _debugProPlan = value;
      _myRooms = _applyLegacyRoomLocking(_myRooms);
    });
    _syncRoomProviders();
    try {
      await AppSettingsRepository.instance.setDebugProPlanEnabled(value);
    } catch (error) {
      debugPrint('[settings] failed to save debug pro plan: $error');
    }
  }

  Future<void> _setDebugAlwaysShowOnboarding(bool value) async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    if (_debugAlwaysShowOnboarding == value) {
      return;
    }
    _setStateForDebug(() {
      _debugAlwaysShowOnboarding = value;
      _debugForceOnboardingHidden = false;
    });
    if (value) {
      _applyDebugOnboardingOverrideIfNeeded();
    } else {
      unawaited(_loadBasicOnboardingState());
    }
    try {
      await AppSettingsRepository.instance.setDebugAlwaysShowOnboarding(value);
    } catch (error) {
      debugPrint('[settings] failed to save debug onboarding toggle: $error');
    }
  }

  void _debugShowProfileSetupOnboarding() {
    if (!_isDebugAdmin) {
      return;
    }
    final defaultNickname = _defaultProfileNickname;
    _onboardingProfileNicknameController
      ..text = defaultNickname
      ..selection = TextSelection.collapsed(offset: defaultNickname.length);

    _setStateForDebug(() {
      _debugAlwaysShowOnboarding = true;
      _debugForceOnboardingHidden = false;
      _basicOnboardingReady = true;
      _basicOnboardingDismissed = false;
      _basicOnboardingCompleted = false;
      _basicOnboardingStep = _BasicOnboardingStep.profileSetup;
      _showRoomSelection = true;
      _onboardingProfileSaving = false;
      _onboardingProfileError = null;
      _onboardingProfileAvatarUrl = '';
    });
  }

  Future<bool> _ensureDebugAdminAccess() async {
    if (_isDebugAdmin) {
      return true;
    }
    await _refreshDebugAdminAccess();
    return _isDebugAdmin;
  }

  Future<void> _refreshDebugAdminAccess() async {
    final auth = Supabase.instance.client.auth;
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) {
        _isDebugAdmin = false;
      } else if (_isDebugAdmin) {
        _setStateForDebug(() => _isDebugAdmin = false);
      }
      return;
    }

    final debugSession = await ensureValidAccessTokenWithDebug();
    final isAdmin =
        _isAdminClaim(user.appMetadata) || _isAdminClaim(debugSession.claims);
    if (!mounted) {
      _isDebugAdmin = isAdmin;
      if (_isDebugAdmin) {
        _applyDebugOnboardingOverrideIfNeeded();
      }
      return;
    }
    if (_isDebugAdmin == isAdmin) {
      if (_isDebugAdmin) {
        _applyDebugOnboardingOverrideIfNeeded();
      }
      return;
    }
    _setStateForDebug(() {
      _isDebugAdmin = isAdmin;
      _myRooms = _applyLegacyRoomLocking(_myRooms);
    });
    _applyDebugOnboardingOverrideIfNeeded();
    _syncRoomProviders();
  }

  Future<void> _runFeedTest() async {
    if (!await _ensureDebugAdminAccess()) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) return;

    _setStateForDebug(() {
      _testingFeed = true;
      _feedResult = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      final debugResult = await ensureValidAccessTokenWithDebug();
      final accessToken = debugResult.token;
      final userId = auth.currentUser?.id;
      String tokenPreview;
      if (accessToken == null) {
        tokenPreview = 'null';
      } else if (accessToken.length <= 16) {
        tokenPreview = accessToken;
      } else {
        tokenPreview =
            '${accessToken.substring(0, 10)}...${accessToken.substring(accessToken.length - 6)}';
      }
      final expiryText = debugResult.expiresAt?.toIso8601String() ?? 'unknown';
      final remainingText =
          debugResult.remaining?.inSeconds.toString() ?? 'unknown';
      final claims = debugResult.claims ?? const {};
      final ref = claims['ref'] ?? 'unknown';
      final aud = claims['aud'] ?? 'unknown';
      final issuer = claims['iss'] ?? 'unknown';
      final sub = claims['sub'] ?? 'unknown';
      final role = claims['role'] ?? 'unknown';

      _setStateForDebug(() {
        _feedResult =
            'auth: user=$userId | token=$tokenPreview | '
            'ref=$ref | aud=$aud | iss=$issuer | sub=$sub | role=$role | '
            'expires=$expiryText | remaining=${remainingText}s | '
            '${debugResult.message}';
      });
      debugPrint('[feed_test] ${_feedResult ?? ''}');

      if (accessToken == null) {
        return;
      }

      final labelObservations = [
        const LabelObservation(text: 'Coffee', confidence: 0.92),
        const LabelObservation(text: 'Cup', confidence: 0.71),
      ];

      final mappingRepository = LabelMappingRepository(
        Supabase.instance.client,
      );
      final mappingEntries = await mappingRepository.fetch();
      final mappingService = LabelMappingService(mappingEntries);

      final mappedLabels = mappingService.matchLabels(labelObservations);
      final matchByLabel = <String, LabelMatch>{};
      for (final match in mappedLabels) {
        matchByLabel[LabelMappingService.normalizeLabel(match.text)] = match;
      }

      final labelPayload = labelObservations.map((label) {
        final normalized = LabelMappingService.normalizeLabel(label.text);
        final match = matchByLabel[normalized];
        return {
          'text': label.text,
          'confidence': label.confidence,
          if (match != null) 'canonical_tag': match.canonicalTag,
        };
      }).toList();

      Future<FunctionResponse> invokeWithToken(String token) {
        return Supabase.instance.client.functions.invoke(
          'feed_validate',
          headers: {'Authorization': 'Bearer $token'},
          body: {
            'room_id': roomId,
            'labels': labelPayload,
            'canonical_tags': mappingService.matchCanonicalTags(
              labelObservations,
            ),
            'caption': 'Test feed',
            'image_url': 'https://example.com/test.jpg',
          },
        );
      }

      FunctionResponse response;
      try {
        response = await invokeWithToken(accessToken);
      } on FunctionException catch (error) {
        if (error.status == 401) {
          final refreshed = await ensureValidAccessTokenWithDebug(
            forceRefresh: true,
          );
          final refreshedToken = refreshed.token;
          if (refreshedToken == null) {
            rethrow;
          }
          response = await invokeWithToken(refreshedToken);
        } else {
          rethrow;
        }
      }

      final data = response.data;
      String details = 'status ${response.status}';
      if (data is Map) {
        final payload = Map<String, dynamic>.from(data);
        final webhookSkipped = payload['webhook_skipped'];
        final webhookStatus = payload['webhook_status'];
        final webhookError = payload['webhook_error'];
        details =
            'status ${response.status} | webhook_skipped=$webhookSkipped | '
            'webhook_status=$webhookStatus | webhook_error=$webhookError';
      }

      _setStateForDebug(() {
        _feedResult = 'Success: $details';
      });
    } on FunctionException catch (error) {
      final detailsText = error.details == null ? '' : ' | ${error.details}';
      _setStateForDebug(
        () => _feedResult =
            'Error: status ${error.status} ${error.reasonPhrase}$detailsText',
      );
    } catch (error) {
      _setStateForDebug(() => _feedResult = 'Error: $error');
    } finally {
      if (mounted) _setStateForDebug(() => _testingFeed = false);
    }
  }

  void _setShowSocketDebug(bool value) {
    _setStateForDebug(() => _showSocketDebug = value);
  }

  // --- UI Builders ---
}
