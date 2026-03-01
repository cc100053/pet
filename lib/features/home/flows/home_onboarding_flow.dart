part of '../home_view.dart';

extension _HomeOnboardingFlow on _HomeViewState {
  static const String _stepCreatePet = 'create_pet';
  static const String _stepOpenRoom = 'open_room';
  static const String _stepInviteFriend = 'invite_friend';
  static const String _stepFeedOnce = 'feed_once';
  static const String _stepCompleted = 'completed';

  bool get _isDebugForceOnboardingActive {
    return _isDebugAdmin && _debugAlwaysShowOnboarding;
  }

  bool get _isBasicOnboardingActive {
    return _basicOnboardingReady &&
        ((_isDebugForceOnboardingActive && !_debugForceOnboardingHidden) ||
            (!_basicOnboardingDismissed && !_basicOnboardingCompleted));
  }

  bool get _isCreatePetOnboardingStepActive {
    return _isBasicOnboardingActive &&
        _basicOnboardingStep == _BasicOnboardingStep.createPet &&
        _showRoomSelection;
  }

  bool get _isOpenRoomOnboardingStepActive {
    return _isBasicOnboardingActive &&
        _basicOnboardingStep == _BasicOnboardingStep.openRoom &&
        _showRoomSelection &&
        _openRoomOnboardingTargetRoomId != null;
  }

  String? get _openRoomOnboardingTargetRoomId {
    for (final room in _myRooms) {
      final roomId = room['id'] as String?;
      if (roomId == null || roomId.isEmpty) {
        continue;
      }
      if (room['is_locked'] == true) {
        continue;
      }
      return roomId;
    }
    return _myRooms.isNotEmpty ? _myRooms.first['id'] as String? : null;
  }

  bool get _shouldShowCreatePetOnboardingCoachCard {
    return (_isCreatePetOnboardingStepActive ||
            _isOpenRoomOnboardingStepActive) &&
        !_loadingRoom;
  }

  Future<void> _loadBasicOnboardingState() async {
    final settings = AppSettingsRepository.instance;
    final dismissed = settings.onboardingBasicDismissed;
    final completed = settings.onboardingBasicCompleted;
    var step = _parseBasicOnboardingStep(settings.onboardingBasicCurrentStep);
    if (completed) {
      step = _BasicOnboardingStep.completed;
    }

    if (!dismissed && !completed && settings.onboardingBasicStartedAt == null) {
      await settings.setOnboardingBasicStartedAt(DateTime.now().toUtc());
    }

    if (!mounted) {
      _basicOnboardingDismissed = dismissed;
      _basicOnboardingCompleted = completed;
      _basicOnboardingStep = step;
      _basicOnboardingReady = true;
      return;
    }

    _setStateForOnboarding(() {
      _basicOnboardingDismissed = dismissed;
      _basicOnboardingCompleted = completed;
      _basicOnboardingStep = step;
      _basicOnboardingReady = true;
    });
    _applyDebugOnboardingOverrideIfNeeded();
    _evaluateBasicOnboardingAgainstCurrentData();
  }

  Future<void> _dismissBasicOnboarding() async {
    if (!_basicOnboardingReady || _basicOnboardingDismissed) {
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

    await _advanceBasicOnboardingTo(_BasicOnboardingStep.openRoom);
  }

  Future<void> _markOpenRoomOnboardingStepCompleted() async {
    if (!_basicOnboardingReady ||
        _basicOnboardingDismissed ||
        _basicOnboardingCompleted ||
        _basicOnboardingStep != _BasicOnboardingStep.openRoom) {
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

    final hasAnyRoom = _myRooms.isNotEmpty;
    if (_basicOnboardingStep == _BasicOnboardingStep.createPet && hasAnyRoom) {
      unawaited(_advanceBasicOnboardingTo(_BasicOnboardingStep.openRoom));
      return;
    }
    if (_basicOnboardingStep == _BasicOnboardingStep.openRoom &&
        !_showRoomSelection &&
        _roomId != null) {
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
        _basicOnboardingStep != _BasicOnboardingStep.createPet ||
        _basicOnboardingDismissed ||
        _basicOnboardingCompleted;
    if (!needsReset) {
      return;
    }
    if (mounted) {
      _setStateForOnboarding(() {
        _basicOnboardingStep = _BasicOnboardingStep.createPet;
        _basicOnboardingDismissed = false;
        _basicOnboardingCompleted = false;
      });
      return;
    }
    _basicOnboardingStep = _BasicOnboardingStep.createPet;
    _basicOnboardingDismissed = false;
    _basicOnboardingCompleted = false;
  }

  String _basicOnboardingStepStorageValue(_BasicOnboardingStep step) {
    return switch (step) {
      _BasicOnboardingStep.createPet => _stepCreatePet,
      _BasicOnboardingStep.openRoom => _stepOpenRoom,
      _BasicOnboardingStep.inviteFriend => _stepInviteFriend,
      _BasicOnboardingStep.feedOnce => _stepFeedOnce,
      _BasicOnboardingStep.completed => _stepCompleted,
    };
  }

  _BasicOnboardingStep _parseBasicOnboardingStep(String? raw) {
    return switch (raw) {
      _stepOpenRoom => _BasicOnboardingStep.openRoom,
      _stepInviteFriend => _BasicOnboardingStep.inviteFriend,
      _stepFeedOnce => _BasicOnboardingStep.feedOnce,
      _stepCompleted => _BasicOnboardingStep.completed,
      _ => _BasicOnboardingStep.createPet,
    };
  }

  Widget _buildBasicOnboardingCoachCard() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomOffset = (92 * scale) + bottomInset;
    final isOpenRoom = _isOpenRoomOnboardingStepActive;
    final title = isOpenRoom
        ? l10n.onboardingOpenRoomTitle
        : l10n.roomSelectionCreatePet;
    final description = isOpenRoom
        ? l10n.onboardingOpenRoomDescription
        : l10n.roomSelectionSubtitle;
    final icon = isOpenRoom ? Icons.meeting_room_rounded : Icons.pets_rounded;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomOffset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFFFF8E8), Color(0xFFFFF2D5)],
          ),
          border: Border.all(
            color: AppTheme.secondaryColor.withValues(alpha: 0.9),
            width: 1.6,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _dismissBasicOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Text(l10n.commonClose),
              ),
            ],
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
            final targetRect = _resolveOnboardingFocusRect(overlayContext);
            if (targetRect == null) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: _OnboardingFocusPainter(
                targetRect: targetRect.inflate(6),
                cornerRadius: _isOpenRoomOnboardingStepActive ? 20 : 28,
              ),
            );
          },
        ),
      ),
    );
  }

  Rect? _resolveOnboardingFocusRect(BuildContext overlayContext) {
    if (_isOpenRoomOnboardingStepActive) {
      return _openRoomCardRectInOverlay(overlayContext);
    }
    if (_isCreatePetOnboardingStepActive) {
      return _createPetCtaRectInOverlay(overlayContext);
    }
    return null;
  }

  Rect? _createPetCtaRectInOverlay(BuildContext overlayContext) {
    final targetContext = _onboardingCreateRoomCtaKey.currentContext;
    if (targetContext == null) {
      return null;
    }
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        overlayBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return null;
    }
    final topLeftGlobal = targetBox.localToGlobal(Offset.zero);
    final topLeftLocal = overlayBox.globalToLocal(topLeftGlobal);
    return topLeftLocal & targetBox.size;
  }

  Rect? _openRoomCardRectInOverlay(BuildContext overlayContext) {
    final targetContext = _onboardingOpenRoomCardKey.currentContext;
    if (targetContext == null) {
      return null;
    }
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    final overlayBox = overlayContext.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        overlayBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return null;
    }
    final topLeftGlobal = targetBox.localToGlobal(Offset.zero);
    final topLeftLocal = overlayBox.globalToLocal(topLeftGlobal);
    return topLeftLocal & targetBox.size;
  }
}

class _OnboardingFocusPainter extends CustomPainter {
  const _OnboardingFocusPainter({
    required this.targetRect,
    required this.cornerRadius,
  });

  final Rect targetRect;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final focusRRect = RRect.fromRectAndRadius(
      targetRect,
      Radius.circular(cornerRadius),
    );

    canvas.saveLayer(fullRect, Paint());
    canvas.drawRect(
      fullRect,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawRRect(focusRRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.drawRRect(
      focusRRect.inflate(2),
      Paint()
        ..color = AppTheme.secondaryColor.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingFocusPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
