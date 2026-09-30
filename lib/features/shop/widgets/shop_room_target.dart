part of '../shop_view.dart';

/// Which room room-bound purchases (furniture, equipment, themes) go to:
/// the delivery tag, the in-shop room switcher, and the pre-purchase
/// "send to this room?" confirmation.
extension _ShopRoomTargeting on _ShopViewState {
  ShopRoomTarget? get _activeRoomTarget {
    for (final room in widget.rooms) {
      if (room.roomId == _roomId) {
        return room;
      }
    }
    return null;
  }

  bool get _canSwitchShopRoom => widget.rooms.length > 1;

  Future<void> _showShopRoomSwitcher() async {
    if (_purchasing) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ShopRoomPickerSheet(
        title: l10n.shopSwitchRoomTitle,
        rooms: widget.rooms,
        selectedRoomId: _roomId,
      ),
    );
    if (picked == null || picked == _roomId || !mounted) {
      return;
    }
    AnalyticsService.instance.logEvent('store_switch_room');
    _setStoreState(() {
      _roomId = picked;
      // Departed-pet letters belong to the room the shop was opened from.
      _departedPets = picked == widget.roomId
          ? List.of(widget.departedPets)
          : <DepartedPetInfo>[];
      _loading = true;
    });
    await _loadStore();
  }

  /// Multi-room users confirm the destination room before a room-bound
  /// purchase; single-room users have nothing to mix up and skip it.
  Future<bool> _confirmRoomDelivery(ShopItem item) async {
    final isRoomBound =
        item.isFurniture || item.isEquipment || item.isBackground;
    final target = _activeRoomTarget;
    if (!isRoomBound || !_canSwitchShopRoom || target == null) {
      return true;
    }
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showJuiceToast<bool>(
      context: context,
      message: l10n.shopDeliverConfirmTitle(target.petName),
      position: JuicePosition.center,
      leading: ShopRoomPetAvatar(assetPath: target.petAssetPath, size: 56),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BalancedText(
            l10n.shopDeliverConfirmMessage(
              item.localizedName(l10n),
              target.petName,
            ),
            style: GoogleFonts.mPlusRounded1c(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(16),
          ShopRoomActionButton(
            label: l10n.shopDeliverConfirmAction(target.petName),
            filled: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const Gap(8),
          ShopRoomActionButton(
            label: l10n.commonCancel,
            filled: false,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

class ShopRoomPetAvatar extends StatelessWidget {
  const ShopRoomPetAvatar({
    super.key,
    required this.assetPath,
    required this.size,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.pets_rounded, color: AppTheme.ink),
        ),
      ),
    );
  }
}

/// Luggage-tag strip under the shop header: "Delivering to `pet`'s room".
class ShopDeliveryTag extends StatelessWidget {
  const ShopDeliveryTag({
    super.key,
    required this.target,
    this.onSwitch,
    this.compact = false,
  });

  final ShopRoomTarget target;
  final VoidCallback? onSwitch;

  /// Narrow hosts (dialogs): no outer margin, no eyelet, icon-only switch.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppTheme.kinako,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(14),
            right: Radius.circular(22),
          ),
          border: Border.all(color: AppTheme.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(color: AppTheme.wood, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            if (!compact) ...[
              // Tag eyelet.
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.ink, width: 2),
                ),
              ),
              const Gap(10),
            ],
            ShopRoomPetAvatar(
              assetPath: target.petAssetPath,
              size: compact ? 36 : 44,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.shopDeliveringTo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mPlusRounded1c(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l10n.shopRoomOfPet(target.petName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.mPlusRounded1c(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (onSwitch != null) ...[
              const Gap(8),
              if (compact)
                Semantics(
                  button: true,
                  label: l10n.shopSwitchRoom,
                  child: JuicyScaleButton(
                    onTap: onSwitch,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.ink, width: 2),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        size: 20,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                )
              else
                JuicyScaleButton(
                  onTap: onSwitch,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.paper,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.ink, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: AppTheme.ink,
                        ),
                        const Gap(4),
                        Text(
                          l10n.shopSwitchRoom,
                          style: GoogleFonts.mPlusRounded1c(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing the user's rooms; pops the picked room id.
class ShopRoomPickerSheet extends StatelessWidget {
  const ShopRoomPickerSheet({
    super.key,
    required this.title,
    required this.rooms,
    required this.selectedRoomId,
  });

  final String title;
  final List<ShopRoomTarget> rooms;
  final String? selectedRoomId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppTheme.ink, width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.softLine,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const Gap(14),
              BalancedText(
                title,
                style: GoogleFonts.mPlusRounded1c(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Gap(12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  separatorBuilder: (_, _) => const Gap(10),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final selected = room.roomId == selectedRoomId;
                    return JuicyScaleButton(
                      onTap: () => Navigator.of(context).pop(room.roomId),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? AppTheme.leafStrong
                                : AppTheme.softLine,
                            width: selected ? 2.5 : 2,
                          ),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: AppTheme.leafDeep,
                                    offset: Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            ShopRoomPetAvatar(
                              assetPath: room.petAssetPath,
                              size: 44,
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                l10n.shopRoomOfPet(room.petName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.mPlusRounded1c(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selected
                                  ? AppTheme.leafStrong
                                  : AppTheme.softLine,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopRoomActionButton extends StatelessWidget {
  const ShopRoomActionButton({
    super.key,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JuicyScaleButton(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppTheme.leafStrong : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.ink, width: 2.5),
          boxShadow: filled
              ? const [
                  BoxShadow(color: AppTheme.leafDeep, offset: Offset(0, 4)),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.mPlusRounded1c(
            color: filled ? Colors.white : AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
