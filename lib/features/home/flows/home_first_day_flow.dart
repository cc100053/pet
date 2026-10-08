part of '../home_view.dart';

/// "First day" checklist: replaces the old step-locked coach cards. Task
/// state is the server's: claimed = an `onboarding` row in the caller's own
/// `coin_ledger`; `claim_onboarding_reward` checks eligibility and pays once.
extension _HomeFirstDayFlow on _HomeViewState {
  /// Only accounts whose onboarding started in a build with this checklist;
  /// installs from before it sit in the old, never-finished invite step.
  bool get _isFirstDayChecklistActive {
    if (!_basicOnboardingReady ||
        !(_firstDayEligible || _isDebugForceOnboardingActive)) {
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
  Future<void> _syncFirstDayChecklist({bool force = false}) async {
    final roomId = _roomId;
    if (!_isFirstDayChecklistActive || roomId == null || _firstDaySyncing) {
      return;
    }
    final now = DateTime.now();
    final last = _firstDayLastSyncAt;
    // ponytail: 10s throttle, up to 3 small RPCs per sync; move to a
    // realtime/trigger push if this ever shows up in request volume.
    if (!force && last != null && now.difference(last).inSeconds < 10) {
      return;
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
          claimed = {...claimed, task.key};
          granted += coins.toInt();
          AnalyticsService.instance.logEvent(
            'onboarding_task_done',
            parameters: {'task': task.key},
          );
        }
      }
      if (!mounted) {
        return;
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
