part of 'home_view.dart';

extension _HomePetSceneBuilders on _HomeViewState {
  Widget _buildPetHomeCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldSize = constraints.biggest;
        final uiScale = homeUiScale(MediaQuery.sizeOf(context).width);
        final promptInset = 12 * uiScale;
        final furnitureHintLeft = 16 * uiScale;
        final furnitureHintBottom = 12 * uiScale;
        return GestureDetector(
          key: _petFieldKey,
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            if (_furnitureMode) {
              _closeFurnitureInventory();
              return;
            }
            _handlePetFieldTap(details.localPosition, fieldSize);
          },
          child: Stack(
            children: [
              ..._buildPlacedFurniture(fieldSize),
              if (_photoFoodImageSource != null &&
                  _photoFoodNormalizedPosition != null &&
                  _photoFoodBiteStage < 3)
                _buildPhotoFood(fieldSize),
              for (final spot in _poopSpots())
                Positioned(
                  left: _positionFromNormalizedSized(
                    spot.normalized,
                    fieldSize,
                    _HomeViewState._poopEmojiSize,
                  ).dx,
                  top: _positionFromNormalizedSized(
                    spot.normalized,
                    fieldSize,
                    _HomeViewState._poopEmojiSize,
                  ).dy,
                  child: _buildPoopEmoji(spot.index),
                ),
              ..._buildAdditionalRoomPets(fieldSize),
              AnimatedBuilder(
                animation: _petMoveController,
                builder: (context, child) {
                  final normalized = _currentPetNormalized();
                  final topLeft = _positionFromNormalized(
                    normalized,
                    fieldSize,
                  );
                  return Positioned(
                    left: topLeft.dx,
                    top: topLeft.dy,
                    child: child!,
                  );
                },
                child: _buildDraggablePet(fieldSize),
              ),
              if (_petEating) _buildEatingHearts(fieldSize),
              if (_shouldShowNewRoomInvitePrompt)
                Positioned(
                  top: promptInset,
                  right: promptInset,
                  child: _buildNewRoomInvitePrompt(),
                ),
              if (_furnitureMode)
                Positioned(
                  left: furnitureHintLeft,
                  bottom: furnitureHintBottom,
                  child: _buildFurnitureEditHint(),
                ),
              if (_isCurrentRoomLocked)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              if (_isCurrentRoomLocked)
                Positioned(
                  left: promptInset,
                  right: promptInset,
                  bottom: promptInset,
                  child: _buildLockedRoomHomePrompt(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedRoomHomePrompt() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black87, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.roomLockedMessage,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: l10n.shopTitle,
            child: SizedBox(
              width: 34,
              height: 34,
              child: FilledButton(
                onPressed: () => unawaited(_openStoreFromNav()),
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const CircleBorder(),
                ),
                child: SvgPicture.asset(
                  'assets/icon/icon-park-outline--shopping-bag.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_PoopSpot> _poopSpots() {
    final petState = _effectivePetState;
    final raw = petState?['poop_positions'];
    final spots = <_PoopSpot>[];
    if (raw is List) {
      for (var i = 0; i < raw.length; i++) {
        final entry = raw[i];
        if (entry is Map) {
          final x = (entry['x'] as num?)?.toDouble();
          final y = (entry['y'] as num?)?.toDouble();
          if (x == null || y == null) {
            continue;
          }
          spots.add(
            _PoopSpot(
              index: i,
              normalized: Offset(x.clamp(0.05, 0.95), y.clamp(0.05, 0.95)),
            ),
          );
        }
      }
    }
    if (spots.isEmpty) {
      final poopAt = _parseOptionalDate(petState?['poop_at'])?.toUtc();
      if (poopAt != null && !poopAt.isAfter(DateTime.now().toUtc())) {
        spots.add(const _PoopSpot(index: 0, normalized: Offset(0.62, 0.72)));
      }
    }
    return spots;
  }

  Widget _buildPoopEmoji(int index) {
    final isPetDeparted = _effectivePetDeparted;
    return IgnorePointer(
      ignoring: _petBusy || isPetDeparted,
      child: GestureDetector(
        onTap: (_petBusy || isPetDeparted)
            ? null
            : () => unawaited(_cleanPoopAt(index)),
        child: const Text('💩', style: TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildPhotoFood(Size fieldSize) {
    final source = _photoFoodImageSource;
    final normalized = _photoFoodNormalizedPosition;
    if (source == null || normalized == null) {
      return const SizedBox.shrink();
    }
    final target = _positionFromNormalizedSized(
      normalized,
      fieldSize,
      _HomeViewState._photoFoodSize,
    );
    final offscreenTop = -_HomeViewState._photoFoodSize.height - 12;
    return AnimatedPositioned(
      duration: _HomeViewState._foodDropDuration,
      curve: Curves.bounceOut,
      left: target.dx,
      top: _photoFoodDropping ? offscreenTop : target.dy,
      child: PhotoFood(
        imageSource: source,
        biteStage: _photoFoodBiteStage,
        size: _HomeViewState._photoFoodSize,
      ),
    );
  }

  Widget _buildEatingHearts(Size fieldSize) {
    final normalized = _currentPetNormalized();
    final petTopLeft = _positionFromNormalized(normalized, fieldSize);
    return Positioned(
      left: petTopLeft.dx + (_HomeViewState._petAvatarSize.width * 0.15),
      top: petTopLeft.dy - 24,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _petEating ? 1 : 0),
          duration: 220.ms,
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -8 * value),
                child: child,
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF6D8A)),
              SizedBox(width: 2),
              Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFFF8FA6)),
              SizedBox(width: 2),
              Icon(Icons.favorite_rounded, size: 10, color: Color(0xFFFFB1C2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverfedBubble() {
    final l10n = AppLocalizations.of(context)!;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showOverfedBubble ? 1 : 0,
        duration: 200.ms,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _showOverfedBubble ? 1 : 0.92,
          duration: 200.ms,
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black87, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  l10n.petOverfedBubble,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -2),
                child: Transform.rotate(
                  angle: pi / 4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black87, width: 1.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePet(Size fieldSize) {
    final petState = _effectivePetState;
    if (_effectivePetDeparted) {
      return _buildDepartedPetPlaceholder();
    }
    if (!_effectivePetStateReady || petState == null) {
      return _buildPetLoadingPlaceholder();
    }
    final petVisualScale = _petVisualScale(MediaQuery.sizeOf(context).width);
    final overfedBubbleOffset = _overfedBubbleOffset(petVisualScale);
    return IgnorePointer(
      ignoring: _furnitureMode,
      child: GestureDetector(
        onPanStart: (details) => _handlePetDragStart(details, fieldSize),
        onPanUpdate: (details) => _handlePetDragUpdate(details, fieldSize),
        onPanEnd: (_) => _handlePetDragEnd(),
        onPanCancel: _handlePetDragCancel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: overfedBubbleOffset.dx,
              top: overfedBubbleOffset.dy,
              child: _buildOverfedBubble(),
            ),
            JuicyScaleButton(
              onTap: _petBusy
                  ? null
                  : () {
                      _markUserInteraction();
                      final id = _petId;
                      if (id != null) {
                        _showPetNameTag(id);
                      }
                      _applyPetAction('touch');
                    },
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  _petFacingRight ? 1.0 : -1.0,
                  1.0,
                  1.0,
                ),
                child: Transform.scale(
                  scale: petVisualScale,
                  child: _buildPetAvatar(),
                ),
              ),
            ),
            if (_petId != null && _visibleNameTagPetId == _petId)
              _buildMainPetNameTag(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPetNameTag() {
    final l10n = AppLocalizations.of(context)!;
    final roomId = _roomId;
    String label = '';
    if (roomId != null) {
      final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
      final main = pets.firstWhere(
        (p) => p.petId == _petId,
        orElse: () => const _RoomPet(petId: '', petType: '', isMain: false),
      );
      label = main.name ?? '';
      if (label.isEmpty && main.petType.isNotEmpty) {
        label = PetCatalog.byId(main.petType).name(l10n);
      }
    }
    if (label.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: -8,
      top: -22,
      right: -8,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black87, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAdditionalRoomPets(Size fieldSize) {
    if (_effectivePetDeparted || !_effectivePetStateReady) {
      return const [];
    }
    final roomId = _roomId;
    if (roomId == null) {
      return const [];
    }
    final pets = _roomPetsByRoom[roomId] ?? const <_RoomPet>[];
    final extraPets = pets
        .where((pet) => !pet.isMain && pet.petId != _petId)
        .take(4)
        .toList();
    if (extraPets.isEmpty) {
      return const [];
    }

    final visualScale = _petVisualScale(MediaQuery.sizeOf(context).width);
    final size = _HomeViewState._petAvatarSize;
    return List.generate(extraPets.length, (i) {
      final pet = extraPets[i];
      final runtime = _ensureExtraPetRuntime(pet.petId, i);
      // Position at the destination so AnimatedPositioned interpolates toward
      // it. facingRight is computed against the departure point at the same
      // moment the target is set, so facing always matches travel direction.
      final pos = _positionFromNormalizedSized(
        runtime.normalizedTarget,
        fieldSize,
        size,
      );
      final isFurnitureBlocking = _furnitureMode;
      return AnimatedPositioned(
        key: ValueKey('extra_pet_${pet.petId}'),
        duration: runtime.animDuration,
        curve: Curves.easeOutCubic,
        left: pos.dx,
        top: pos.dy,
        child: IgnorePointer(
          ignoring: isFurnitureBlocking,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showPetNameTag(pet.petId),
            onLongPress: () => unawaited(_openPetNameEditor(targetPet: pet)),
            onPanStart: (details) =>
                _handleExtraPetDragStart(pet.petId, details, fieldSize),
            onPanUpdate: (details) =>
                _handleExtraPetDragUpdate(pet.petId, details, fieldSize),
            onPanEnd: (_) => _handleExtraPetDragEnd(pet.petId),
            onPanCancel: () => _handleExtraPetDragEnd(pet.petId),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Transform.scale(
                  scale: visualScale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(
                      runtime.facingRight ? 1.0 : -1.0,
                      1.0,
                      1.0,
                    ),
                    child: _buildRoomPetAvatar(pet, runtime, size: size),
                  ),
                ),
                if (_visibleNameTagPetId == pet.petId)
                  _buildPetNameTag(pet, size: size),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildPetNameTag(_RoomPet pet, {required Size size}) {
    final l10n = AppLocalizations.of(context)!;
    final label = (pet.name?.trim().isNotEmpty ?? false)
        ? pet.name!.trim()
        : PetCatalog.byId(pet.petType).name(l10n);
    return Positioned(
      left: -8,
      top: -22,
      right: -8,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black87, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  double _petVisualScale(double screenWidth) {
    final responsive = HomeResponsiveSpec.fromWidth(screenWidth);
    return responsive.pick(
      compact: _HomeViewState._petCompactVisualScale,
      regular: _HomeViewState._petRegularVisualScale,
      expanded: _HomeViewState._petExpandedVisualScale,
    );
  }

  Offset _overfedBubbleOffset(double petVisualScale) {
    final insetX =
        (_HomeViewState._petAvatarSize.width * (1 - petVisualScale)) / 2;
    final insetY =
        (_HomeViewState._petAvatarSize.height * (1 - petVisualScale)) / 2;
    final baseX = -_HomeViewState._petAvatarSize.width * 0.06;
    final baseY = -_HomeViewState._petAvatarSize.height * 0.54;
    return Offset(baseX + insetX, baseY + insetY);
  }

  Widget _buildPetLoadingPlaceholder() {
    return SizedBox(
      width: _HomeViewState._petAvatarSize.width,
      height: _HomeViewState._petAvatarSize.height,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _buildDepartedPetPlaceholder() {
    final l10n = AppLocalizations.of(context)!;
    final info = _currentDepartedPetInfo();
    final heroTag = _departureHeroTag(info?.petId ?? 'pet');
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: info == null
              ? null
              : () => unawaited(_showPetDepartureFlow(info)),
          child: Container(
            width: 95,
            height: 95,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8D8B5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icon/solar--letter-outline.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4A3B2A),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.petDepartureGuideTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A3B2A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlacedFurniture(Size fieldSize) {
    final placed = _activeFurnitureForRoom();
    if (placed.isEmpty) {
      return const [];
    }
    // Plan A: lay furniture out inside a fixed-aspect canvas so every member
    // sees the same relative position and size regardless of device size.
    final content = RoomCanvas.contentRect(fieldSize);
    return [
      for (final item in placed)
        Positioned(
          left: RoomCanvas.topLeftFromCenterFraction(
            centerFraction: _canvasCenterFraction(item),
            content: content,
            itemSize: RoomCanvas.furnitureSize(content, item.scale),
          ).dx,
          top: RoomCanvas.topLeftFromCenterFraction(
            centerFraction: _canvasCenterFraction(item),
            content: content,
            itemSize: RoomCanvas.furnitureSize(content, item.scale),
          ).dy,
          child: _buildFurniturePiece(item, content),
        ),
    ];
  }

  Widget _buildFurniturePiece(_PlacedFurniture item, Rect content) {
    final canEdit = _furnitureMode;
    final isSelected = _isPlacedFurnitureSelected(item);
    final itemSize = RoomCanvas.furnitureSize(content, item.scale);
    // Keep the icon/emoji proportional to the (now canvas-relative) footprint;
    // legacy ratio was 26pt glyph inside a 42px box.
    final iconSize = itemSize.width * (26 / 42);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _openFurnitureInventory,
      onTap: canEdit ? () => _selectPlacedFurniture(item) : null,
      onPanStart: canEdit ? (_) => _handleFurnitureDragStart(item) : null,
      onPanUpdate: canEdit
          ? (details) => _handleFurnitureDragUpdate(item, details, content)
          : null,
      onPanEnd: canEdit ? (_) => _handleFurnitureDragEnd(item) : null,
      onPanCancel: canEdit ? _handleFurnitureDragCancel : null,
      child: AnimatedBuilder(
        animation: _furnitureWiggleController,
        builder: (context, child) {
          final angle = canEdit ? _furnitureWiggleAngle(item) : 0.0;
          return Transform.rotate(angle: angle, child: child);
        },
        child: AnimatedContainer(
          duration: 150.ms,
          width: itemSize.width,
          height: itemSize.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: canEdit
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: canEdit
                ? Border.all(
                    color: isSelected
                        ? const Color(0xFFFFB74D)
                        : Colors.black12,
                    width: isSelected ? 1.8 : 1,
                  )
                : null,
            boxShadow: canEdit
                ? [
                    BoxShadow(
                      color:
                          (isSelected ? const Color(0xFFFFB74D) : Colors.black)
                              .withValues(alpha: isSelected ? 0.2 : 0.08),
                      blurRadius: isSelected ? 10 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(
                    item.flipX ? -1.0 : 1.0,
                    1.0,
                    1.0,
                  ),
                  child:
                      item.assetPath != null &&
                          item.assetPath!.trim().isNotEmpty
                      ? Image.asset(
                          item.assetPath!.trim(),
                          width: itemSize.width * 0.9,
                          height: itemSize.height * 0.9,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Text(
                            item.emoji,
                            style: TextStyle(fontSize: iconSize),
                          ),
                        )
                      : Text(item.emoji, style: TextStyle(fontSize: iconSize)),
                ),
              ),
              if (canEdit && isSelected)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Material(
                    color: Colors.redAccent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _removeFurniture(item),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFurnitureEditHint() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        l10n.furnitureEditMode,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget? _buildFurnitureScaleControlBar() {
    if (!_furnitureMode) {
      return null;
    }
    final item = _selectedPlacedFurniture();
    if (item == null) {
      return null;
    }
    final canDecrease = item.scale > roomFurnitureMinScale + 0.001;
    final canIncrease = item.scale < roomFurnitureMaxScale - 0.001;
    final l10n = AppLocalizations.of(context)!;
    return HomeFurnitureScaleControls(
      label: l10n.furnitureScaleLabel,
      scale: item.scale,
      minScale: roomFurnitureMinScale,
      maxScale: roomFurnitureMaxScale,
      step: roomFurnitureScaleStep,
      decreaseLabel: l10n.furnitureScaleDecrease,
      increaseLabel: l10n.furnitureScaleIncrease,
      flipLabel: l10n.furnitureFlipHorizontal,
      onDecrease: canDecrease ? () => _stepSelectedFurnitureScale(-1) : null,
      onIncrease: canIncrease ? () => _stepSelectedFurnitureScale(1) : null,
      onFlip: _toggleSelectedFurnitureFlip,
      onChanged: _handleFurnitureScaleChanged,
      onChangeStart: _handleFurnitureScaleChangeStart,
      onChangeEnd: _handleFurnitureScaleChangeEnd,
    );
  }

  double _furnitureWiggleAngle(_PlacedFurniture item) {
    final phase = (item.id.hashCode % 360) * (pi / 180);
    return sin((_furnitureWiggleController.value * 2 * pi) + phase) * 0.04;
  }

  Widget _buildPetAvatar() {
    final petColor = _petMoodColor();
    final petDefinition = PetCatalog.byId(_petType);

    final String asset;
    if (_petEating) {
      asset = petDefinition.stayAsset;
    } else if (_petIsMoving) {
      asset = petDefinition.walkAsset;
    } else {
      asset = switch (_petStationaryState) {
        _PetStationaryState.staying => petDefinition.stayAsset,
        _PetStationaryState.sleeping => petDefinition.sleepAsset,
      };
    }

    // Render the main pet's gear from the whole-room equipment map
    // (_loadAllPetEquipment), the same fast source the extras use, so it appears
    // together with them. Fall back to _equippedSkusBySlot (the per-pet
    // get_pet_equipment RPC) until that query lands — this avoids the 1-2s lag
    // where the main pet popped its gear on a beat after entering the room.
    final mainPetRoomSkus = _petId != null
        ? _equippedSkusByPetId[_petId]
        : null;
    final mainPetSkus = (mainPetRoomSkus != null && mainPetRoomSkus.isNotEmpty)
        ? mainPetRoomSkus
        : _equippedSkusBySlot;

    return RepaintBoundary(
      child: _buildPetVisualForAsset(
        petId: _petType,
        asset: asset,
        size: _HomeViewState._petAvatarSize,
        isWalking: _petIsMoving,
        isSleeping:
            !_petIsMoving &&
            _petStationaryState == _PetStationaryState.sleeping &&
            !_petEating,
        petFallbackColor: petColor,
        showSocketDebug: _showSocketDebug,
        equippedSkusBySlot: mainPetSkus,
      ),
    );
  }

  Widget _buildRoomPetAvatar(
    _RoomPet pet,
    _ExtraPetRuntime runtime, {
    required Size size,
  }) {
    final petDefinition = PetCatalog.byId(pet.petType);
    final isWalking = runtime.isWalking || runtime.isDragging;
    final isSleeping =
        !isWalking && runtime.stationaryState == _PetStationaryState.sleeping;
    final String asset;
    if (isWalking) {
      asset = petDefinition.walkAsset;
    } else if (isSleeping) {
      asset = petDefinition.sleepAsset;
    } else {
      asset = petDefinition.stayAsset;
    }
    return RepaintBoundary(
      child: _buildPetVisualForAsset(
        petId: pet.petType,
        asset: asset,
        size: size,
        isWalking: isWalking,
        isSleeping: isSleeping,
        petFallbackColor: petDefinition.accent,
        equippedSkusBySlot: _equippedSkusByPetId[pet.petId] ?? const {},
      ),
    );
  }

  Widget _buildStatusBarPetAvatar(PetDefinition petDefinition) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final resolvedSide = side.isFinite && side > 0 ? side : 54.0;
        final roomId = _roomId;
        final petCount = roomId == null
            ? 0
            : (_roomPetsByRoom[roomId] ?? const <_RoomPet>[]).length;
        final canSwitch = petCount >= 2;
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canSwitch ? () => _showMainPetSwitcher() : null,
            child: _buildPetVisualForAsset(
              petId: _petType,
              asset: petDefinition.stayAsset,
              size: Size.square(resolvedSide),
              petFallbackColor: petDefinition.accent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetVisualForAsset({
    required String petId,
    required String asset,
    required Size size,
    required Color petFallbackColor,
    bool isWalking = false,
    bool isSleeping = false,
    bool showSocketDebug = false,
    Map<String, String>? equippedSkusBySlot,
  }) {
    final equippedSkus = equippedSkusBySlot ?? _equippedSkusBySlot;
    Widget buildStack(String petAsset, double animationProgress) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            PetEquipmentOverlay(
              petId: petId,
              equippedSkusBySlot: equippedSkus,
              petSize: size,
              layer: PetEquipmentOverlayLayer.behindPet,
              animationProgress: animationProgress,
              isWalking: isWalking,
              isSleeping: isSleeping,
            ),
            Image.asset(
              petAsset,
              width: size.width,
              height: size.height,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPetFallback(petFallbackColor),
            ),
            PetEquipmentOverlay(
              petId: petId,
              equippedSkusBySlot: equippedSkus,
              petSize: size,
              layer: PetEquipmentOverlayLayer.frontPet,
              animationProgress: animationProgress,
              isWalking: isWalking,
              isSleeping: isSleeping,
              showSocketDebug: showSocketDebug,
            ),
          ],
        ),
      );
    }

    return PetAnimationFrameBuilder(
      sourceAsset: asset,
      builder: (context, petAsset, animationProgress, _) =>
          buildStack(petAsset, animationProgress),
    );
  }

  Color _petMoodColor() {
    Color petColor = Colors.orangeAccent;
    final petState = _effectivePetState;
    if (petState != null) {
      final mood = petState['mood'] as String? ?? 'low';
      switch (mood) {
        case 'high':
          petColor = Colors.pinkAccent;
          break;
        case 'mid':
          petColor = Colors.orangeAccent;
          break;
        case 'sad':
          petColor = Colors.blueGrey;
          break;
      }
    }
    return petColor;
  }

  Widget _buildPetFallback(Color petColor, {bool loading = false}) {
    if (loading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: petColor.withValues(alpha: 0.6),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final faceLayout = ResponsiveLayout.fromSize(
          constraints.biggest,
          designSize: _HomeViewState._petAvatarSize,
        );
        final eyeTop = faceLayout.y(20);
        final eyeInset = faceLayout.x(16);
        final eyeWidth = faceLayout.s(24);
        final eyeHeight = faceLayout.s(30);
        final highlightInset = faceLayout.s(4);
        final highlightSize = faceLayout.s(8);
        final mouthBottom = faceLayout.y(18);
        final mouthWidth = faceLayout.s(36);
        final mouthHeight = faceLayout.s(14);

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: eyeTop,
              left: eyeInset,
              child: _buildEye(
                width: eyeWidth,
                height: eyeHeight,
                highlightInset: highlightInset,
                highlightSize: highlightSize,
              ),
            ),
            Positioned(
              top: eyeTop,
              right: eyeInset,
              child: _buildEye(
                width: eyeWidth,
                height: eyeHeight,
                highlightInset: highlightInset,
                highlightSize: highlightSize,
              ),
            ),
            Positioned(
              bottom: mouthBottom,
              child: Container(
                width: mouthWidth,
                height: mouthHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(mouthHeight),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEye({
    required double width,
    required double height,
    required double highlightInset,
    required double highlightSize,
  }) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Align(
            alignment: Alignment.topRight,
            child: Container(
              margin: EdgeInsets.all(highlightInset),
              width: highlightSize,
              height: highlightSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleY(
          begin: 1.0,
          end: 0.1,
          duration: 200.ms,
          delay: 3000.ms,
          curve: Curves.easeInOut,
        ); // Blink
  }
}
