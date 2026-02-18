part of '../home_view.dart';

extension _HomePetMovementController on _HomeViewState {
  void _startWanderTimer() {
    _wanderTimer?.cancel();
    _wanderTimer = Timer.periodic(
      _HomeViewState._wanderCheckInterval,
      (_) => _maybeTriggerWander(),
    );
  }

  void _maybeTriggerWander() {
    if (!mounted ||
        _isDraggingPet ||
        _petDeparted ||
        _petEating ||
        _petIsMoving ||
        _photoFoodImageSource != null) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastInteractionAt) < _HomeViewState._idleThreshold) {
      return;
    }
    if (now.difference(_lastWanderAt) < _HomeViewState._wanderCooldown) {
      return;
    }
    final fieldSize = _petFieldSize();
    if (fieldSize == null || fieldSize.isEmpty) {
      return;
    }
    final target = Offset(
      0.02 + _random.nextDouble() * 0.96,
      0.08 + _random.nextDouble() * 0.84,
    );
    _lastWanderAt = now;
    _animatePetTo(target, fieldSize, userInitiated: false);
  }

  void _markUserInteraction() {
    _lastInteractionAt = DateTime.now();
  }

  Size? _petFieldSize() {
    final context = _petFieldKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    return box?.size;
  }

  Offset _currentPetNormalized() {
    if (_petMoveController.isAnimating && _petMoveAnimation != null) {
      return _petMoveAnimation!.value;
    }
    return _petNormalizedPosition;
  }

  Offset _positionFromNormalized(Offset normalized, Size fieldSize) {
    final maxX = max(
      0.0,
      fieldSize.width - _HomeViewState._petAvatarSize.width,
    );
    final maxY = max(
      0.0,
      fieldSize.height - _HomeViewState._petAvatarSize.height,
    );
    return Offset(normalized.dx * maxX, normalized.dy * maxY);
  }

  Offset _normalizedFromTopLeft(Offset topLeft, Size fieldSize) {
    final maxX = max(
      0.0,
      fieldSize.width - _HomeViewState._petAvatarSize.width,
    );
    final maxY = max(
      0.0,
      fieldSize.height - _HomeViewState._petAvatarSize.height,
    );
    final normalizedX = maxX == 0 ? 0.0 : topLeft.dx / maxX;
    final normalizedY = maxY == 0 ? 0.0 : topLeft.dy / maxY;
    return Offset(normalizedX, normalizedY);
  }

  Offset _clampTopLeft(Offset topLeft, Size fieldSize) {
    final maxX = max(
      0.0,
      fieldSize.width - _HomeViewState._petAvatarSize.width,
    );
    final maxY = max(
      0.0,
      fieldSize.height - _HomeViewState._petAvatarSize.height,
    );
    final clampedX = topLeft.dx.clamp(0.0, maxX);
    final clampedY = topLeft.dy.clamp(0.0, maxY);
    return Offset(clampedX, clampedY);
  }

  Offset _clampNormalized(Offset normalized) {
    final clampedX = normalized.dx.clamp(0.0, 1.0);
    final clampedY = normalized.dy.clamp(0.0, 1.0);
    return Offset(clampedX, clampedY);
  }

  Duration _durationForDistance(double distance) {
    final rawMs = (distance / _HomeViewState._petMoveSpeed * 1000).round();
    return Duration(milliseconds: max(_HomeViewState._minMoveMs, rawMs));
  }

  Duration _durationForFoodApproach({
    required double distance,
    required double hunger,
  }) {
    final hungerClamped = hunger.clamp(0.0, 100.0);
    final hungerRatio = hungerClamped / 100.0;
    final speedPxPerSec =
        lerpDouble(20, 95, hungerRatio) ?? _HomeViewState._petMoveSpeed;
    final rawMs = (distance / speedPxPerSec * 1000).round();
    return Duration(milliseconds: max(_HomeViewState._minMoveMs, rawMs));
  }

  void _updateFacing(Offset from, Offset to) {
    final dx = to.dx - from.dx;
    if (dx.abs() < 0.001) {
      return;
    }
    _petFacingRight = dx < 0;
  }

  TickerFuture _startPetMove(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
    Duration? duration,
  }) {
    final clampedTarget = _clampNormalized(targetNormalized);
    final current = _currentPetNormalized();
    final currentPx = _positionFromNormalized(current, fieldSize);
    final targetPx = _positionFromNormalized(clampedTarget, fieldSize);
    _updateFacing(current, clampedTarget);
    _petMoveController.stop();
    _petMoveController.duration =
        duration ?? _durationForDistance((targetPx - currentPx).distance);
    _petMoveAnimation = Tween<Offset>(begin: current, end: clampedTarget)
        .animate(
          CurvedAnimation(
            parent: _petMoveController,
            curve: Curves.easeOutCubic,
          ),
        );
    _petNormalizedTarget = clampedTarget;
    if (userInitiated) {
      _markUserInteraction();
    }
    _petIsMoving = true;
    final ticker = _petMoveController.forward(from: 0);
    _refreshPetMovementFrame();
    return ticker;
  }

  void _animatePetTo(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
  }) {
    _startPetMove(targetNormalized, fieldSize, userInitiated: userInitiated);
  }

  Future<void> _animatePetToAndWait(
    Offset targetNormalized,
    Size fieldSize, {
    bool userInitiated = true,
    Duration? duration,
  }) async {
    final ticker = _startPetMove(
      targetNormalized,
      fieldSize,
      userInitiated: userInitiated,
      duration: duration,
    );
    try {
      await ticker.orCancel;
    } catch (_) {
      // Movement interrupted by another interaction.
    }
  }

  void _handlePetFieldTap(Offset localPosition, Size fieldSize) {
    if (_petDeparted || _petEating || _photoFoodImageSource != null) {
      return;
    }
    final desiredTopLeft =
        localPosition -
        Offset(
          _HomeViewState._petAvatarSize.width / 2,
          _HomeViewState._petAvatarSize.height / 2,
        );
    final clampedTopLeft = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalizedTarget = _normalizedFromTopLeft(clampedTopLeft, fieldSize);
    _animatePetTo(normalizedTarget, fieldSize);
  }

  Offset? _globalToPetField(Offset globalPosition) {
    final context = _petFieldKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject() as RenderBox?;
    return box?.globalToLocal(globalPosition);
  }

  void _handlePetDragStart(DragStartDetails details, Size fieldSize) {
    if (_petDeparted || _petEating || _photoFoodImageSource != null) {
      return;
    }
    final localPosition = _globalToPetField(details.globalPosition);
    if (localPosition == null) {
      return;
    }
    _markUserInteraction();
    final current = _currentPetNormalized();
    _petMoveController.stop();
    _petNormalizedPosition = current;
    final currentTopLeft = _positionFromNormalized(
      _petNormalizedPosition,
      fieldSize,
    );
    _dragOffset = localPosition - currentTopLeft;
    _setStateForPetMovement(() {
      _isDraggingPet = true;
      _petIsMoving = true;
    });
  }

  void _handlePetDragUpdate(DragUpdateDetails details, Size fieldSize) {
    if (_petDeparted || _photoFoodImageSource != null) {
      return;
    }
    final localPosition = _globalToPetField(details.globalPosition);
    if (localPosition == null) {
      return;
    }
    _markUserInteraction();
    final desiredTopLeft = localPosition - _dragOffset;
    final clampedTopLeft = _clampTopLeft(desiredTopLeft, fieldSize);
    final normalized = _normalizedFromTopLeft(clampedTopLeft, fieldSize);
    _updateFacing(_petNormalizedPosition, normalized);
    _setStateForPetMovement(() {
      _petNormalizedPosition = normalized;
    });
  }

  void _handlePetDragEnd() {
    if (!_isDraggingPet || _photoFoodImageSource != null) {
      return;
    }
    _setStateForPetMovement(() {
      _isDraggingPet = false;
      _petIsMoving = false;
      _selectNextPetStationaryState();
    });
  }

  void _handlePetDragCancel() {
    if (!_isDraggingPet || _photoFoodImageSource != null) {
      return;
    }
    _setStateForPetMovement(() {
      _isDraggingPet = false;
      _petIsMoving = false;
      _selectNextPetStationaryState();
    });
  }

  void _selectNextPetStationaryState() {
    // Cat-like polyphasic sleep: sleep a lot, but not only at night.
    // We approximate "12-16 hours/day" by using higher sleep probability
    // during late night + midday, with crepuscular awake windows.
    final sleepProbability = _sleepProbabilityForLocalHour(DateTime.now().hour);
    _petStationaryState = _random.nextDouble() < sleepProbability
        ? _PetStationaryState.sleeping
        : _PetStationaryState.staying;
  }

  double _sleepProbabilityForLocalHour(int hour) {
    // hour: 0-23
    // Targets ~13-14h/day of sleep when mostly stationary.
    // Crepuscular: more awake at dawn/dusk.
    if (hour >= 22 || hour <= 4) {
      return 0.75;
    }
    if (hour >= 11 && hour <= 16) {
      return 0.65;
    }
    if ((hour >= 5 && hour <= 7) || (hour >= 18 && hour <= 20)) {
      return 0.30;
    }
    return 0.50;
  }
}
