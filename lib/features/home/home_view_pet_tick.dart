part of 'home_view.dart';

/// Pet hunger/EXP tick domain for [_HomeViewState]: periodic tick timers,
/// tick RPCs, and hunger-alert dispatch/push.
/// Extracted from home_view.dart verbatim (behavior-preserving).
extension _HomePetTick on _HomeViewState {
  void _startPetTickTimer() {
    _petTickTimer?.cancel();
    _petTickTimer = Timer.periodic(_HomeViewState._petTickInterval, (_) {
      unawaited(_tickPetState());
    });
  }

  void _startRoomSelectionRefreshTimer() {
    _roomSelectionRefreshTimer?.cancel();
    _roomSelectionRefreshTimer = Timer.periodic(
      _HomeViewState._roomSelectionRefreshInterval,
      (_) {
        if (!mounted || !_showRoomSelection) {
          return;
        }
        unawaited(_refreshRoomSelectionHealthBars());
      },
    );
  }

  Future<void> _tickPetState() async {
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    try {
      final petId = _petId ?? await _loadPetId(roomId);
      if (petId == null) {
        return;
      }
      await _tickPetStateAndDispatchAlerts(petId: petId, roomId: roomId);
    } catch (_) {
      // Best-effort. This periodic tick should not disrupt the UI.
    }
  }

  Future<void> _tickPetStateAndDispatchAlerts({
    required String petId,
    required String roomId,
  }) async {
    await _tickPetStateRpc(petId);
    await _dispatchNewHungerAlerts(petId: petId, roomId: roomId);
  }

  Future<void> _tickPetStateRpc(String petId) async {
    await Supabase.instance.client.rpc(
      'tick_pet_state',
      params: {
        'p_pet_id': petId,
        'p_now': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _dispatchNewHungerAlerts({
    required String petId,
    required String roomId,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    try {
      final state = await Supabase.instance.client
          .from('pet_state')
          .select(
            'hunger_alert_50_message_id,'
            'hunger_alert_50_triggered_by,'
            'hunger_alert_30_message_id,'
            'hunger_alert_30_triggered_by,'
            'hunger_alert_10_message_id,'
            'hunger_alert_10_triggered_by',
          )
          .eq('pet_id', petId)
          .maybeSingle();
      if (state == null) {
        return;
      }
      final alertCandidates =
          <({String? messageId, String? triggeredBy, int level})>[
            (
              messageId: state['hunger_alert_50_message_id'] as String?,
              triggeredBy: state['hunger_alert_50_triggered_by'] as String?,
              level: 50,
            ),
            (
              messageId: state['hunger_alert_30_message_id'] as String?,
              triggeredBy: state['hunger_alert_30_triggered_by'] as String?,
              level: 30,
            ),
            (
              messageId: state['hunger_alert_10_message_id'] as String?,
              triggeredBy: state['hunger_alert_10_triggered_by'] as String?,
              level: 10,
            ),
          ];
      for (final alert in alertCandidates) {
        final messageId = alert.messageId;
        if (messageId == null || messageId.isEmpty) {
          continue;
        }
        if (alert.triggeredBy != null && alert.triggeredBy != userId) {
          continue;
        }
        if (_notifiedHungerAlertMessageIds.contains(messageId)) {
          continue;
        }
        final sent = await _sendHungerAlertPush(
          roomId: roomId,
          messageId: messageId,
          level: alert.level,
        );
        if (sent) {
          _notifiedHungerAlertMessageIds.add(messageId);
        }
      }
    } catch (_) {
      // Best-effort. Notification dispatch should not block pet updates.
    }
  }

  Future<bool> _sendHungerAlertPush({
    required String roomId,
    required String messageId,
    required int level,
  }) async {
    try {
      final accessToken = await ensureValidAccessToken();
      if (accessToken == null) {
        return false;
      }
      final response = await Supabase.instance.client.functions.invoke(
        'notify_friend',
        headers: {'Authorization': 'Bearer $accessToken'},
        body: {
          'type': 'hunger_alert',
          'room_id': roomId,
          'message_id': messageId,
          'alert_level': level,
        },
      );
      return response.status >= 200 && response.status < 300;
    } catch (_) {
      return false;
    }
  }

  DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
