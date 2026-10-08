part of '../home_view.dart';

/// "First day" checklist: replaces the old step-locked coach cards. Task
/// state is the server's: claimed = an `onboarding` row in the caller's own
/// `coin_ledger`; `claim_onboarding_reward` checks eligibility and pays once.
extension _HomeFirstDayFlow on _HomeViewState {
  /// New accounts only (the server pays nobody older). A reinstall of a new
  /// account starts onboarding again and shows the tasks it has left.
  bool get _isFirstDayChecklistActive {
    final eligible = isFirstDayEligibleAccount(
      Supabase.instance.client.auth.currentUser?.createdAt,
    );
    if (!_basicOnboardingReady ||
        !(eligible || _isDebugForceOnboardingActive)) {
      return false;
    }
    return _isBasicOnboardingActive &&
        (_basicOnboardingStep == _BasicOnboardingStep.inviteFriend ||
            _basicOnboardingStep == _BasicOnboardingStep.feedOnce);
  }

  bool get _isCurrentRoomOwner {
    final roomId = _roomId;
    if (roomId == null) {
      return false;
    }
    final room = _myRooms.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == roomId,
      orElse: () => null,
    );
    return room?['role'] == 'owner';
  }

  List<FirstDayTask> get _firstDayTasks =>
      FirstDayTask.forKeeper(isOwner: _isCurrentRoomOwner);

  bool get _shouldShowFirstDayChecklist {
    final claimed = _firstDayClaimed;
    return _isFirstDayChecklistActive &&
        claimed != null &&
        _roomId != null &&
        !_isCurrentRoomLocked &&
        _firstDayTasks.any((task) => !claimed.contains(task.key));
  }

  Future<Set<String>> _fetchClaimedFirstDayTasks() async {
    final rows = await Supabase.instance.client
        .from('coin_ledger')
        .select('metadata')
        .eq('source', 'onboarding');
    return {
      for (final row in rows)
        if ((row['metadata'] as Map?)?['task'] case final String task) task,
    };
  }

  /// Claims every open task the server now agrees is done, then refreshes the
  /// card. Passive triggers (room refresh, build) are throttled; direct ones
  /// (feed done, chat or decor closed) pass [force].
  /// Returns the tasks this call newly claimed (empty when skipped).
  Future<Set<FirstDayTask>> _syncFirstDayChecklist({bool force = false}) async {
    final newlyClaimed = <FirstDayTask>{};
    final roomId = _roomId;
    if (!_isFirstDayChecklistActive || roomId == null || _firstDaySyncing) {
      return newlyClaimed;
    }
    final now = DateTime.now();
    final last = _firstDayLastSyncAt;
    // ponytail: 10s throttle, up to 3 small RPCs per sync; move to a
    // realtime/trigger push if this ever shows up in request volume.
    if (!force && last != null && now.difference(last).inSeconds < 10) {
      return newlyClaimed;
    }
    _firstDaySyncing = true;
    _firstDayLastSyncAt = now;
    try {
      var claimed = _firstDayClaimed ?? await _fetchClaimedFirstDayTasks();
      var granted = 0;
      for (final task in _firstDayTasks) {
        if (claimed.contains(task.key)) {
          continue;
        }
        final coins = await Supabase.instance.client.rpc(
          'claim_onboarding_reward',
          params: {'p_room_id': roomId, 'p_task': task.key},
        );
        if (coins is num && coins > 0) {
          newlyClaimed.add(task);
          claimed = {...claimed, task.key};
          granted += coins.toInt();
          AnalyticsService.instance.logEvent(
            'onboarding_task_done',
            parameters: {'task': task.key},
          );
        }
      }
      if (!mounted) {
        return newlyClaimed;
      }
      _setStateForOnboarding(() => _firstDayClaimed = claimed);
      if (granted > 0) {
        _applyCoinRewardFeedback(granted);
      }
      final allDone = _firstDayTasks.every((t) => claimed.contains(t.key));
      if (allDone) {
        await _advanceBasicOnboardingTo(_BasicOnboardingStep.completed);
      }
    } catch (error, stackTrace) {
      reportSwallowedError(error, stackTrace, source: 'first_day_sync');
    } finally {
      _firstDaySyncing = false;
    }
    return newlyClaimed;
  }

  /// After a feed: the first-meal reward card (when this feed earned
  /// `first_feed`) and/or the soft ask for push, for new accounts only.
  Future<void> _afterFeedCompleted() async {
    final newly = await _syncFirstDayChecklist(force: true);
    final firstMeal = newly.contains(FirstDayTask.firstFeed);
    final user = Supabase.instance.client.auth.currentUser;
    if (!mounted || !isFirstDayEligibleAccount(user?.createdAt)) {
      return;
    }
    final settings = AppSettingsRepository.instance;
    final fcm = ref.read(fcmServiceProvider);
    final ask =
        shouldSoftAskForPush(
          askedCount: settings.pushSoftAskCount,
          snoozedUntil: settings.pushSoftAskSnoozedUntil,
          now: DateTime.now(),
        ) &&
        await fcm.isPermissionUndecided();
    if (!firstMeal && !ask) {
      return;
    }
    // Let the feed animation and any double-reward prompt go first.
    await Future<void>.delayed(const Duration(seconds: 2));
    final uncovered = await waitUntilUncovered(
      isCovered: () => mounted && !(ModalRoute.of(context)?.isCurrent ?? true),
      isStillWanted: () => mounted,
    );
    if (!uncovered || !mounted) {
      return;
    }
    await _showFirstMealCard(
      firstMealCoins: firstMeal ? FirstDayTask.firstFeed.coins : null,
      ask: ask,
    );
  }

  Future<void> _showFirstMealCard({
    required int? firstMealCoins,
    required bool ask,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = AppSettingsRepository.instance;
    var answeredYes = false;
    await showJuiceToast<void>(
      context: context,
      tone: AppDialogTone.success,
      position: JuicePosition.center,
      message: firstMealCoins != null
          ? l10n.firstMealTitle(firstMealCoins)
          : l10n.pushSoftAskTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (firstMealCoins != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppTheme.ink, width: 2),
              ),
              child: Text(
                l10n.firstMealBadge,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          PetAnimatedImage(
            sourceAsset: PetCatalog.byId(_petType).stayAsset,
            width: 110,
            height: 110,
            fit: BoxFit.contain,
          ),
          if (ask)
            BalancedText(
              l10n.pushSoftAskBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
        ],
      ),
      actionLabel: ask ? l10n.pushSoftAskYes : l10n.commonClose,
      onActionPressed: ask
          ? () {
              answeredYes = true;
              unawaited(
                ref.read(fcmServiceProvider).initialize(askIfUndecided: true),
              );
            }
          : null,
      secondaryActionLabel: ask ? l10n.pushSoftAskLater : null,
    );
    if (!ask) {
      return;
    }
    // "Not now", the barrier or back all count as not now.
    await settings.recordPushSoftAsk(
      snoozedUntil: answeredYes ? null : DateTime.now().add(kPushSoftAskSnooze),
    );
    AnalyticsService.instance.logEvent(
      'push_soft_ask',
      parameters: {'answer': answeredYes ? 'yes' : 'not_now'},
    );
  }

  void _onFirstDayTaskTap(FirstDayTask task) {
    switch (task) {
      case FirstDayTask.firstFeed:
        unawaited(_openFeedCamera());
      case FirstDayTask.coKeeperJoined:
        unawaited(_generateInviteCode());
      case FirstDayTask.firstFurniture:
        _openFurnitureInventory();
      case FirstDayTask.firstChat:
        _openChatRoom();
    }
  }

  Widget _buildFirstDayChecklist() {
    final l10n = AppLocalizations.of(context)!;
    final name = _petName?.trim() ?? '';
    return FirstDayChecklistCard(
      petName: name.isEmpty ? l10n.petNameUnknown : name,
      tasks: _firstDayTasks,
      claimed: _firstDayClaimed ?? const {},
      collapsed: _firstDayCollapsed,
      onToggleCollapsed: () => _setStateForOnboarding(
        () => _firstDayCollapsed = !_firstDayCollapsed,
      ),
      onTapTask: _onFirstDayTaskTap,
      onDismiss: () => unawaited(_dismissBasicOnboarding()),
    );
  }
}
