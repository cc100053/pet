import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/app_dialog.dart';
import '../../../shared/ui/juice_wrappers.dart';
import 'home_currency_pill.dart';
import 'room_frame_card.dart';
import 'room_frame_skins.dart';

/// Everything the 換相框 sheet needs to draw the live preview of a room card.
class RoomFramePreviewData {
  const RoomFramePreviewData({
    required this.imageUrl,
    required this.petName,
    required this.caption,
    required this.petLevel,
    required this.hungerValue,
    required this.petId,
    required this.petAssetPath,
    this.equippedSkusBySlot = const <String, String>{},
    this.captionKind = RoomFrameCaptionKind.message,
    this.captionIcon,
  });

  final String imageUrl;
  final String petName;

  /// Already resolved by the caller, so the sheet previews the exact caption
  /// the grid card shows — including a status fallback.
  final String caption;
  final RoomFrameCaptionKind captionKind;
  final IconData? captionIcon;
  final int? petLevel;
  final double hungerValue;
  final String petId;
  final String petAssetPath;
  final Map<String, String> equippedSkusBySlot;
}

/// 換相框 — pick the casing a room card wears.
///
/// Built on the app's existing equip/inventory treatments: the green outline
/// plus check badge that marks the worn casing matches
/// `home_room_inventory_panel.dart`. The label under each swatch names the
/// casing instead of repeating its ownership — see `_buildLabel`.
///
/// Casings unlock by room level, so [roomLevel] decides what is pickable.
Future<void> showRoomFramePickerSheet({
  required BuildContext context,
  required RoomFramePreviewData preview,
  required RoomFrameStyle equippedStyle,
  required int? roomLevel,
  required int coins,
  required int diamonds,
  required VoidCallback onStoreTap,
  required Future<void> Function(RoomFrameStyle style) onEquip,
  VoidCallback? onLeaveRoom,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    // Scrim rgba(47,42,35,.55) — the ink token at 55%.
    barrierColor: AppTheme.textPrimary.withValues(alpha: 0.55),
    builder: (context) {
      return _RoomFramePickerSheet(
        preview: preview,
        equippedStyle: equippedStyle,
        roomLevel: roomLevel,
        coins: coins,
        diamonds: diamonds,
        onStoreTap: onStoreTap,
        onEquip: onEquip,
        onLeaveRoom: onLeaveRoom,
      );
    },
  );
}

class _RoomFramePickerSheet extends StatefulWidget {
  const _RoomFramePickerSheet({
    required this.preview,
    required this.equippedStyle,
    required this.roomLevel,
    required this.coins,
    required this.diamonds,
    required this.onStoreTap,
    required this.onEquip,
    required this.onLeaveRoom,
  });

  final RoomFramePreviewData preview;
  final RoomFrameStyle equippedStyle;
  final int? roomLevel;
  final int coins;
  final int diamonds;
  final VoidCallback onStoreTap;
  final Future<void> Function(RoomFrameStyle style) onEquip;
  final VoidCallback? onLeaveRoom;

  @override
  State<_RoomFramePickerSheet> createState() => _RoomFramePickerSheetState();
}

class _RoomFramePickerSheetState extends State<_RoomFramePickerSheet> {
  /// The swatch the preview is wearing. Starts at what the room already wears;
  /// 完成 commits it.
  late RoomFrameStyle _highlighted = widget.equippedStyle;
  bool _submitting = false;

  static const double _previewWidth = 190;

  /// The casing the room already wears is always pickable, whatever the ladder
  /// says today. Levels only ever rise, but an unlock level that is lowered and
  /// raised again — or a room whose pet summary has not loaded — must never
  /// leave the room unable to re-select the card it is currently showing.
  bool _isUnlocked(RoomFrameStyle style) =>
      style == widget.equippedStyle ||
      RoomFrameSkins.isUnlocked(style, widget.roomLevel);

  void _handleSwatchTap(RoomFrameStyle style) {
    final l10n = AppLocalizations.of(context)!;
    if (!_isUnlocked(style)) {
      final skin = RoomFrameSkins.resolve(style);
      showJuiceSnackbar(
        context: context,
        message: l10n.roomFrameLockedLevelHint(
          skin.localizedName(l10n),
          skin.unlockLevel,
        ),
        tone: AppDialogTone.warning,
      );
      return;
    }
    if (style == _highlighted) {
      return;
    }
    setState(() => _highlighted = style);
  }

  Future<void> _handleConfirm() async {
    if (_submitting) {
      return;
    }
    final navigator = Navigator.of(context);
    if (_highlighted == widget.equippedStyle) {
      navigator.pop();
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onEquip(_highlighted);
      if (!mounted) {
        return;
      }
      navigator.pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      } else {
        _submitting = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final skin = RoomFrameSkins.resolve(_highlighted);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFBF3), Color(0xFFFFF7EA)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.black87, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Gap(16),
              _buildHeader(l10n),
              const Gap(16),
              // Live preview: the room's own card wearing the highlighted skin.
              SizedBox(
                width: _previewWidth,
                child: RoomFrameCard(
                  skin: skin,
                  imageUrl: widget.preview.imageUrl,
                  petName: widget.preview.petName,
                  caption: widget.preview.caption,
                  captionKind: widget.preview.captionKind,
                  captionIcon: widget.preview.captionIcon,
                  petLevel: widget.preview.petLevel,
                  hungerValue: widget.preview.hungerValue,
                  petId: widget.preview.petId,
                  petAssetPath: widget.preview.petAssetPath,
                  equippedSkusBySlot: widget.preview.equippedSkusBySlot,
                ),
              ),
              const Gap(10),
              // The card itself never names its casing (invariant 3), so the
              // sheet is where the highlighted frame is identified.
              Text(
                skin.localizedName(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const Gap(16),
              _buildSwatchGrid(l10n),
              const Gap(20),
              _buildConfirmButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.roomFrameSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
              const Gap(2),
              Text(
                l10n.roomFrameSheetSubtitle(widget.preview.petName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const Gap(8),
        // Reused as-is from the Home status bar — never re-drawn here. The pill
        // lays out its columns with flex, so it needs a bounded width; share the
        // header rather than pinning a width that large balances would overflow.
        Expanded(
          flex: 6,
          child: HomeCurrencyPill(
            coins: widget.coins,
            diamonds: widget.diamonds,
            coinRewardEventId: 0,
            onStoreTap: widget.onStoreTap,
            expandToWidth: true,
          ),
        ),
        // Leaving is the only thing this button has ever done, so it wears the
        // leave glyph and the destructive tint rather than an overflow "…"
        // that promises a menu the sheet does not have.
        if (widget.onLeaveRoom != null) ...[
          const Gap(6),
          Semantics(
            button: true,
            label: l10n.roomOptionLeave,
            child: Tooltip(
              message: l10n.roomOptionLeave,
              child: JuicyScaleButton(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onLeaveRoom!();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.38),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSwatchGrid(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const gap = 12.0;
        final swatchWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final style in RoomFrameSkins.displayOrder)
              SizedBox(
                key: Key('room_frame_swatch_${style.storageKey}'),
                width: swatchWidth,
                child: _RoomFrameSwatch(
                  skin: RoomFrameSkins.resolve(style),
                  isHighlighted: style == _highlighted,
                  isUnlocked: _isUnlocked(style),
                  onTap: () => _handleSwatchTap(style),
                  l10n: l10n,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmButton(AppLocalizations l10n) {
    return JuicyScaleButton(
      onTap: _submitting ? null : _handleConfirm,
      child: Opacity(
        opacity: _submitting ? 0.7 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black87, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black87, offset: Offset(0, 5)),
            ],
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  l10n.roomFrameConfirm,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A 1:1 miniature of a skin's rim. Payload-free by design: invariant 3 keeps
/// frame names off the card, so the swatch is where the casing is identified.
class _RoomFrameSwatch extends StatelessWidget {
  const _RoomFrameSwatch({
    required this.skin,
    required this.isHighlighted,
    required this.isUnlocked,
    required this.onTap,
    required this.l10n,
  });

  final RoomFrameSkin skin;
  final bool isHighlighted;
  final bool isUnlocked;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  /// Saturation matrix at `s`, in the standard luminance-preserving form.
  static List<double> _saturation(double s) {
    const lr = 0.213, lg = 0.715, lb = 0.072;
    return <double>[
      lr + (1 - lr) * s, lg * (1 - s), lb * (1 - s), 0, 0, //
      lr * (1 - s), lg + (1 - lg) * s, lb * (1 - s), 0, 0, //
      lr * (1 - s), lg * (1 - s), lb + (1 - lb) * s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }

  /// A locked casing has to read as locked at a glance, before the `Lv n`
  /// label is read. Opacity alone at 0.75 did not — the gold and cork casings
  /// still looked as available as the owned ones — so the miniature is drained
  /// of colour as well. Both are needed: desaturation alone leaves a crisp
  /// full-strength card, and dimming alone leaves the accent hues shouting.
  Widget _dimIfLocked(Widget child) {
    if (isUnlocked) {
      return child;
    }
    return Opacity(
      opacity: 0.55,
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_saturation(0.15)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return JuicyScaleButton(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _dimIfLocked(_buildMiniature()),
              // The gate rides on the miniature, not in the label lane — the
              // label lane now belongs to the casing's name. It stays outside
              // the dimming so `Lv n` reads at full strength on exactly the
              // swatches that need it read.
              if (!isUnlocked) _buildLockChip(),
            ],
          ),
          const Gap(8),
          _buildLabel(),
        ],
      ),
    );
  }

  Widget _buildMiniature() {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _buildRim()),
          // The tape / pushpin is what separates 經典 from 軟木板 at this
          // size, so the miniature keeps it.
          if (skin.topAccent != RoomFrameTopAccent.none)
            Positioned(
              top: -6,
              left: 0,
              right: 0,
              child: Center(child: _buildTopAccent()),
            ),
          if (isHighlighted)
            // Matches the equip panel's selected treatment: a green ring
            // offset outside the rim so it reads as a selection, not as
            // part of the frame.
            Positioned(
              left: -3,
              top: -3,
              right: -3,
              bottom: -3,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: AppTheme.primaryColor, width: 3),
                  ),
                ),
              ),
            ),
          if (isHighlighted)
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopAccent() {
    switch (skin.topAccent) {
      case RoomFrameTopAccent.none:
        return const SizedBox.shrink();
      case RoomFrameTopAccent.washiTape:
        return Transform.rotate(
          angle: -3 * math.pi / 180,
          child: Container(
            width: 34,
            height: 11,
            decoration: BoxDecoration(
              color: const Color(0x805FBF9E),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0x73000000), width: 1.6),
            ),
          ),
        );
      case RoomFrameTopAccent.pushpin:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.32, -0.4),
              radius: 0.9,
              colors: [Color(0xFFFFF0F0), Color(0xFFE24B4B), Color(0xFFA32A2A)],
              stops: [0, 0.6, 1],
            ),
            border: Border.all(color: Colors.black87, width: 1.8),
          ),
        );
    }
  }

  Widget _buildRim() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: skin.mountColor,
        gradient: skin.mountGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black87, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black87, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        // The 拍立得 skins have no separate mount, so give their swatch the
        // margin the card's photo inset would otherwise provide.
        padding: EdgeInsets.all(
          skin.mountPadding.left > 0 ? skin.mountPadding.left : 7,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: skin.innerCardColor,
            borderRadius: BorderRadius.circular(9),
            border: skin.innerCardBorderWidth > 0
                ? Border.all(
                    color: Colors.black87,
                    width: skin.innerCardBorderWidth,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// The gate, read at full strength over the drained miniature. Dark pill so
  /// it survives both the pale mounts and the near-black 夜光 one.
  Widget _buildLockChip() {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
            const Gap(3),
            Text(
              l10n.roomFrameLockedLevel(skin.unlockLevel),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The label lane names the casing. Ownership is not spelled out: 使用中 is
  /// the green ring plus its check badge, locked is the chip on the miniature,
  /// and 擁有 — every remaining swatch — needs no word at all.
  ///
  /// Only the variant half of the name fits this lane, so the family half
  /// ("拍立得 · ") stays on the full name under the preview. Scaled down rather
  /// than ellipsised: a chopped name identifies nothing.
  Widget _buildLabel() {
    final Color color;
    final FontWeight weight;
    if (isHighlighted) {
      color = AppTheme.primaryColor;
      weight = FontWeight.w900;
    } else if (isUnlocked) {
      color = AppTheme.textPrimary;
      weight = FontWeight.w800;
    } else {
      color = AppTheme.textSecondary;
      weight = FontWeight.w700;
    }
    return SizedBox(
      height: 14,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          skin.shortLocalizedName(l10n),
          maxLines: 1,
          style: TextStyle(
            fontSize: 11,
            fontWeight: weight,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }
}
