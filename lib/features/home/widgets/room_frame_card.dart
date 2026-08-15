import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/cached_network_image_view.dart';
import '../../pet/pet_animated_image.dart';
import 'pet_equipment_overlay.dart';
import 'room_frame_skins.dart';

/// Resolved layout of a [RoomFrameCard] at a given width and UI scale.
///
/// The card's build and [RoomFrameCard.estimateHeight] both read their numbers
/// from here, so the grid cell a card is measured into can never drift from the
/// card it actually renders.
class RoomFrameGeometry {
  const RoomFrameGeometry({
    required this.cardWidth,
    required this.cardHeight,
    required this.photoWidth,
    required this.photoHeight,
    required this.matHeight,
    required this.topOverhang,
    required this.bottomOverhang,
    required this.horizontalSlack,
  });

  factory RoomFrameGeometry.resolve({
    required double availableWidth,
    required RoomFrameSkin skin,
    required double scale,
  }) {
    final tilted = skin.rotationDegrees.abs() > 0.01;
    // A tilted casing sweeps a little past its own box; give the rotation room
    // inside the cell instead of letting the viewport clip a corner off.
    final horizontalSlack = tilted ? 5.0 * scale : 0.0;
    final cardWidth = math.max(0.0, availableWidth - (horizontalSlack * 2));

    final chrome = skin.horizontalChrome * scale;
    final photoWidth = math.max(0.0, cardWidth - chrome);
    final photoHeight = photoWidth / RoomFrameSkins.photoAspectRatio;

    // The mat sizes itself; this is the cell reservation, so it is deliberately
    // a slight over-estimate rather than an exact fit.
    //
    // The mat is a two-row text block beside a ring, so its content is whichever
    // of the two is taller. Both are constants — the caption row is a fixed
    // height regardless of what it says — so every card in the grid measures the
    // same whether its caption carries a real message or a fallback status line.
    final matContentHeight = math.max(
      _nameLineHeight + _matRowGap + _captionLineHeight,
      _hungerRingSize,
    );
    final matHeight =
        (skin.matPadding.vertical + matContentHeight + _matSlack) * scale;

    final aboveMat =
        (skin.mountPadding.vertical +
            (skin.mountBorderWidth * 2) +
            (skin.innerCardBorderWidth * 2) +
            skin.photoInset.top) *
        scale;

    final cardHeight = aboveMat + photoHeight + matHeight;

    return RoomFrameGeometry(
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      photoWidth: photoWidth,
      photoHeight: photoHeight,
      matHeight: matHeight,
      // Room for the unread badge (-12) and the washi tape / pushpin (-9..-11).
      topOverhang: _topOverhang * scale,
      // The `0 5px 0` hard shadow, plus the tilt sweep.
      bottomOverhang:
          (_bottomOverhang * scale) +
          (tilted
              ? cardWidth * math.sin(_radians(skin.rotationDegrees)).abs()
              : 0.0),
      horizontalSlack: horizontalSlack,
    );
  }

  final double cardWidth;
  final double cardHeight;
  final double photoWidth;
  final double photoHeight;
  final double matHeight;
  final double topOverhang;
  final double bottomOverhang;
  final double horizontalSlack;

  double get totalHeight => topOverhang + cardHeight + bottomOverhang;

  /// Deliberately kept just under the text block's height (16 + 5 + 13 = 34):
  /// the ring should read as the mat's co-equal right-hand element, but never be
  /// the thing that decides how tall the mat is.
  static const double _hungerRingSize = 30;
  static const double _matRowGap = 5;
  static const double _nameLineHeight = 16;
  static const double _captionLineHeight = 13;
  static const double _matSlack = 3;
  static const double _topOverhang = 14;
  static const double _bottomOverhang = 7;

  static double _radians(double degrees) => degrees * math.pi / 180;
}

/// Who is speaking in the card's caption line.
///
/// The line is never blank — an empty slot under the name reads as a hole, and
/// hiding the line would make cards in the same grid different heights. Instead
/// the caller always supplies text, and this says whether it came from a person
/// or from the app, so the two can be told apart at a glance.
enum RoomFrameCaptionKind {
  /// A caption a human wrote on a photo. Ink-weight, no icon.
  message,

  /// App-derived state (hungry, no photo yet…). Lighter, and marked with an
  /// icon so it never passes for something a person typed.
  status,
}

/// One room card on 房間選擇, wearing an equippable [RoomFrameSkin].
///
/// The payload is identical in every skin: photo message zone → pet sprite at
/// the photo's bottom-right → mat with name / `Lv` / hunger ring → caption. The
/// unread badge hangs off the outer rim, never inside the photo.
class RoomFrameCard extends StatelessWidget {
  const RoomFrameCard({
    super.key,
    required this.skin,
    required this.imageUrl,
    required this.petName,
    required this.caption,
    required this.petLevel,
    required this.hungerValue,
    required this.petId,
    required this.petAssetPath,
    this.captionKind = RoomFrameCaptionKind.message,
    this.captionIcon,
    this.equippedSkusBySlot = const <String, String>{},
    this.unreadCount = 0,
    this.scale = 1,
    this.dimmed = false,
    this.unreadBadgeKey,
  });

  final RoomFrameSkin skin;
  final String imageUrl;
  final String petName;

  /// Always non-empty in practice: the caller falls back to a status line
  /// rather than leaving the slot blank. See [RoomFrameCaptionKind].
  final String caption;

  /// Whether [caption] is a person's words or an app-derived status line.
  final RoomFrameCaptionKind captionKind;

  /// Leading glyph for a [RoomFrameCaptionKind.status] caption. Ignored for
  /// messages, which are never iconified.
  final IconData? captionIcon;
  final int? petLevel;

  /// Satiety as 0..1.
  final double hungerValue;
  final String petId;
  final String petAssetPath;
  final Map<String, String> equippedSkusBySlot;
  final int unreadCount;
  final double scale;

  /// Locked rooms wash out without changing the casing's geometry.
  final bool dimmed;
  final Key? unreadBadgeKey;

  /// Height a cell must reserve to hold this card at [availableWidth].
  static double estimateHeight({
    required double availableWidth,
    required RoomFrameSkin skin,
    required double scale,
  }) {
    return RoomFrameGeometry.resolve(
      availableWidth: availableWidth,
      skin: skin,
      scale: scale,
    ).totalHeight;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = RoomFrameGeometry.resolve(
          availableWidth: constraints.maxWidth,
          skin: skin,
          scale: scale,
        );
        final card = _buildCasing(geometry);
        return Padding(
          padding: EdgeInsets.only(
            top: geometry.topOverhang,
            left: geometry.horizontalSlack,
            right: geometry.horizontalSlack,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: geometry.cardWidth,
              child: skin.rotationDegrees == 0
                  ? card
                  : Transform.rotate(
                      angle: RoomFrameGeometry._radians(skin.rotationDegrees),
                      child: card,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCasing(RoomFrameGeometry geometry) {
    final opacity = dimmed ? 0.72 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildMount(geometry),
          if (skin.topAccent != RoomFrameTopAccent.none)
            Positioned(
              top: skin.topAccent == RoomFrameTopAccent.washiTape
                  ? -9 * scale
                  : -11 * scale,
              left: 0,
              right: 0,
              child: Center(child: _buildTopAccent()),
            ),
          if (unreadCount > 0)
            Positioned(
              top: -12 * scale,
              right: -10 * scale,
              child: _UnreadBadge(
                key: unreadBadgeKey,
                count: unreadCount,
                scale: scale,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMount(RoomFrameGeometry geometry) {
    final borderWidth = skin.mountBorderWidth * scale;
    final mountRadius = BorderRadius.circular(skin.mountRadius * scale);
    return Stack(
      // The mount's hard `0 5px 0` shadow paints outside its box.
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: skin.mountColor,
              gradient: skin.mountGradient,
              borderRadius: mountRadius,
              border: Border.all(color: Colors.black87, width: borderWidth),
              boxShadow: _scaledShadows(skin.mountShadows),
            ),
          ),
        ),
        // Invariant 1: the sheen fills the mount but is painted UNDER the inner
        // card, so it only ever lights the rim — never the photo.
        if (skin.sheenGradient != null)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(borderWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: skin.sheenGradient,
                  borderRadius: BorderRadius.circular(
                    math.max(0, (skin.mountRadius * scale) - borderWidth),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.all(borderWidth) + (skin.mountPadding * scale),
          child: _buildInnerCard(geometry),
        ),
        // Mitred ornaments sit on the rim, above the mount and the inner card's
        // corners, and well clear of the photo zone.
        if (skin.cornerOrnamentColor != null)
          Positioned.fill(
            child: _CornerOrnaments(
              color: skin.cornerOrnamentColor!,
              scale: scale,
            ),
          ),
      ],
    );
  }

  Widget _buildInnerCard(RoomFrameGeometry geometry) {
    return Container(
      decoration: BoxDecoration(
        color: skin.innerCardColor,
        borderRadius: BorderRadius.circular(skin.innerCardRadius * scale),
        border: skin.innerCardBorderWidth > 0
            ? Border.all(
                color: Colors.black87,
                width: skin.innerCardBorderWidth * scale,
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: skin.photoInset * scale,
            child: _buildPhotoZoneWithPet(geometry),
          ),
          _buildMat(),
        ],
      ),
    );
  }

  Widget _buildPhotoZoneWithPet(RoomFrameGeometry geometry) {
    // Kept near the handoff's 66px: on the taller photo zone this reads as a pet
    // standing in a room, where the old 62 on a shorter zone filled half the
    // frame and left no photo to look at.
    final spriteSize = 66.0 * scale;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: geometry.photoWidth,
          height: geometry.photoHeight,
          child: _buildPhotoZone(),
        ),
        // Invariant 2: the sprite overlaps the photo's bottom-right corner only,
        // hanging past both edges so it reads as standing in the room.
        Positioned(
          right: -9 * scale,
          bottom: -9 * scale,
          width: spriteSize,
          height: spriteSize,
          child: _PetSprite(
            petId: petId,
            assetPath: petAssetPath,
            equippedSkusBySlot: equippedSkusBySlot,
            size: spriteSize,
            shadow: skin.petShadow,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoZone() {
    final bevel = skin.photoBevel;
    // `Container` (not `DecoratedBox`) so the black outline insets the image
    // instead of being painted over by it.
    final photo = Container(
      decoration: BoxDecoration(
        color: skin.isDark ? const Color(0xFF4A4239) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(skin.photoRadius * scale),
        border: Border.all(
          color: Colors.black87,
          width: skin.photoBorderWidth * scale,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          math.max(0, (skin.photoRadius - 2) * scale),
        ),
        child: imageUrl.isEmpty
            ? _RoomFramePhotoPlaceholder(isDark: skin.isDark)
            : CachedNetworkImageView(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                portraitFriendlyCrop: true,
              ),
      ),
    );
    if (bevel == null) {
      return photo;
    }
    return Container(
      decoration: BoxDecoration(
        color: bevel.color,
        borderRadius: BorderRadius.circular(
          (skin.photoRadius + bevel.width) * scale,
        ),
      ),
      padding: EdgeInsets.all(bevel.width * scale),
      child: photo,
    );
  }

  Widget _buildMat() {
    return Padding(
      // The mat's text starts on the photo's left edge, not on the casing's
      // inner wall. The skins set `matPadding` horizontally tighter than
      // `photoInset`, which left the name hanging off the frame's left rail;
      // deriving the horizontal inset from `photoInset` puts the two edges on
      // one vertical line in every skin by construction, instead of relying on
      // five hand-tuned pairs of numbers staying in sync. Only the vertical
      // padding — the mat's own breathing room — still comes from the skin.
      padding:
          EdgeInsets.fromLTRB(
            skin.photoInset.left,
            skin.matPadding.top,
            skin.photoInset.right,
            skin.matPadding.bottom,
          ) *
          scale,
      // The ring is the mat's trailing element, centred against BOTH text rows
      // rather than living inside the caption row. Sitting at the end of the
      // last row pushed it into the card's bottom-right corner; centring it
      // here reads as one balanced unit — text block on the left, dial on the
      // right — and lets the ring grow without dragging the caption's baseline
      // down with it.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1 belongs to the pet: the name is the loudest thing on
                // the mat, with the level riding beside it as a chip rather
                // than as a second competing headline.
                SizedBox(
                  height: RoomFrameGeometry._nameLineHeight * scale,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _PetNameText(
                          name: petName,
                          skin: skin,
                          scale: scale,
                        ),
                      ),
                      SizedBox(width: 5 * scale),
                      _LevelChip(skin: skin, level: petLevel, scale: scale),
                    ],
                  ),
                ),
                SizedBox(height: RoomFrameGeometry._matRowGap * scale),
                // Row 2 belongs to the room's current state. Fixed height, so
                // the mat measures the same whether the caption carries a real
                // message or a fallback status line.
                SizedBox(
                  height: RoomFrameGeometry._captionLineHeight * scale,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildCaption(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          _HungerRing(skin: skin, value: hungerValue, scale: scale),
        ],
      ),
    );
  }

  /// The caption line, styled by who is speaking.
  ///
  /// A person's words get ink weight and no ornament — they should read like
  /// something someone wrote. A status line is deliberately quieter (lighter
  /// colour, lighter weight) and carries a leading glyph, so the user can tell
  /// at a glance that nobody said this; the app did.
  Widget _buildCaption() {
    final isStatus = captionKind == RoomFrameCaptionKind.status;
    final text = Text(
      caption,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: (isStatus ? 10.0 : 10.5) * scale,
        fontWeight: isStatus ? FontWeight.w500 : FontWeight.w600,
        color: isStatus
            ? skin.captionColor.withValues(alpha: 0.72)
            : skin.captionColor,
        height: 1,
      ),
    );
    if (!isStatus || captionIcon == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          captionIcon,
          size: 10 * scale,
          color: skin.captionColor.withValues(alpha: 0.6),
        ),
        SizedBox(width: 3 * scale),
        Flexible(child: text),
      ],
    );
  }

  Widget _buildTopAccent() {
    switch (skin.topAccent) {
      case RoomFrameTopAccent.none:
        return const SizedBox.shrink();
      case RoomFrameTopAccent.washiTape:
        return Transform.rotate(
          angle: RoomFrameGeometry._radians(-3),
          child: Container(
            width: 60 * scale,
            height: 18 * scale,
            decoration: BoxDecoration(
              color: const Color(0x805FBF9E),
              borderRadius: BorderRadius.circular(3 * scale),
              border: Border.all(
                color: const Color(0x73000000),
                width: 2 * scale,
              ),
            ),
          ),
        );
      case RoomFrameTopAccent.pushpin:
        return Container(
          width: 18 * scale,
          height: 18 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.32, -0.4),
              radius: 0.9,
              colors: [Color(0xFFFFF0F0), Color(0xFFE24B4B), Color(0xFFA32A2A)],
              stops: [0, 0.6, 1],
            ),
            border: Border.all(color: Colors.black87, width: 2.5 * scale),
            boxShadow: [
              BoxShadow(
                color: const Color(0x4D000000),
                blurRadius: 4 * scale,
                offset: Offset(0, 3 * scale),
              ),
            ],
          ),
        );
    }
  }

  List<BoxShadow> _scaledShadows(List<BoxShadow> shadows) {
    if (scale == 1) {
      return shadows;
    }
    return shadows
        .map(
          (shadow) => BoxShadow(
            color: shadow.color,
            blurRadius: shadow.blurRadius * scale,
            spreadRadius: shadow.spreadRadius * scale,
            offset: shadow.offset * scale,
          ),
        )
        .toList(growable: false);
  }
}

/// The pet's name, sized to the lane it actually has.
///
/// A single character budget cannot serve both scripts this app carries: in
/// production the CJK names run 3 characters on average (95th percentile 5)
/// while the Latin ones run 5 (95th percentile 11) — the same cap is either too
/// tight for one or useless for the other. Both percentiles overrun the ~4 CJK /
/// ~8 Latin the mat's name lane fits at full size.
///
/// So the type adapts instead of the input: short names keep the full 15pt
/// punch, longer ones step down to a [_minFontSize] floor — chosen so the name
/// stays clearly the loudest thing on the mat — and only past that does it
/// ellipsize. This also means the lane can be re-tuned (frame insets, the level
/// chip, the ring) without anyone re-deriving a character limit.
class _PetNameText extends StatelessWidget {
  const _PetNameText({
    required this.name,
    required this.skin,
    required this.scale,
  });

  final String name;
  final RoomFrameSkin skin;
  final double scale;

  static const double _maxFontSize = 15;
  static const double _minFontSize = 11;
  static const double _step = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        var fontSize = _minFontSize;
        if (constraints.maxWidth.isFinite) {
          for (
            var candidate = _maxFontSize;
            candidate >= _minFontSize;
            candidate -= _step
          ) {
            if (_fits(candidate, constraints.maxWidth, textScaler)) {
              fontSize = candidate;
              break;
            }
          }
        } else {
          fontSize = _maxFontSize;
        }
        return Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _styleFor(fontSize),
        );
      },
    );
  }

  bool _fits(double fontSize, double maxWidth, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: name, style: _styleFor(fontSize)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width <= maxWidth;
  }

  TextStyle _styleFor(double fontSize) => TextStyle(
    fontSize: fontSize * scale,
    fontWeight: FontWeight.w900,
    color: skin.nameColor,
    height: 1,
  );
}

/// `Lv n` as a tinted chip.
///
/// As bare text beside a 15pt name the level either shouted (same weight, same
/// ink) or vanished. A chip in the skin's level colour gives it its own lane:
/// clearly secondary to the name, still findable.
class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.skin,
    required this.level,
    required this.scale,
  });

  final RoomFrameSkin skin;
  final int? level;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: skin.levelColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level == null ? 'Lv --' : 'Lv $level',
        maxLines: 1,
        style: TextStyle(
          fontSize: 9.5 * scale,
          fontWeight: FontWeight.w900,
          color: skin.levelInk,
          height: 1,
        ),
      ),
    );
  }
}

class _RoomFramePhotoPlaceholder extends StatelessWidget {
  const _RoomFramePhotoPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: isDark ? const Color(0xFF4A4239) : const Color(0xFFF8F4EF),
      child: Center(
        child: Icon(
          Icons.photo,
          size: 30,
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

/// The pet standing in the room: the live sequence plus its equipment overlays,
/// under a drop shadow so it lifts off the photo without covering it.
class _PetSprite extends StatelessWidget {
  const _PetSprite({
    required this.petId,
    required this.assetPath,
    required this.equippedSkusBySlot,
    required this.size,
    required this.shadow,
  });

  final String petId;
  final String assetPath;
  final Map<String, String> equippedSkusBySlot;
  final double size;
  final BoxShadow shadow;

  @override
  Widget build(BuildContext context) {
    final petSize = Size.square(size);
    return PetAnimationFrameBuilder(
      sourceAsset: assetPath,
      builder: (context, petAsset, animationProgress, _) {
        final body = Image.asset(
          petAsset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        );
        final sprite = Stack(
          clipBehavior: Clip.none,
          children: [
            PetEquipmentOverlay(
              petId: petId,
              equippedSkusBySlot: equippedSkusBySlot,
              petSize: petSize,
              layer: PetEquipmentOverlayLayer.behindPet,
              animationProgress: animationProgress,
            ),
            body,
            PetEquipmentOverlay(
              petId: petId,
              equippedSkusBySlot: equippedSkusBySlot,
              petSize: petSize,
              layer: PetEquipmentOverlayLayer.frontPet,
              animationProgress: animationProgress,
            ),
          ],
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The shadow has to follow the pet's silhouette: a box shadow here
            // would paint an opaque rectangle across the photo. Only the body
            // casts it — duplicating the equipment overlays would double their
            // widgets (and their keys) for a shadow nobody can see at 62px.
            Transform.translate(
              offset: shadow.offset,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: shadow.blurRadius / 2,
                  sigmaY: shadow.blurRadius / 2,
                ),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    shadow.color,
                    BlendMode.srcATop,
                  ),
                  child: body,
                ),
              ),
            ),
            sprite,
          ],
        );
      },
    );
  }
}

/// 飢餓值 ring. The value is always ink (or the skin's light text on a dark
/// card) — never white on the tint, which would drop out at this size.
class _HungerRing extends StatelessWidget {
  const _HungerRing({
    required this.skin,
    required this.value,
    required this.scale,
  });

  final RoomFrameSkin skin;
  final double value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = RoomFrameGeometry._hungerRingSize * scale;
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _HungerRingPainter(
              progress: clamped,
              strokeWidth: 2.8 * scale,
              ringColor: skin.hungerRingColor,
              trackColor: skin.hungerTrackColor,
              fillColor: skin.hungerFillColor,
            ),
          ),
          Text(
            '${(clamped * 100).round()}',
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w900,
              color: skin.hungerValueColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HungerRingPainter extends CustomPainter {
  const _HungerRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.ringColor,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final double strokeWidth;
  final Color ringColor;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    canvas.drawCircle(center, radius, Paint()..color = fillColor);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(covariant _HungerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Four mitred L-shapes inset into the mount's corners (`4c` 金葉).
class _CornerOrnaments extends StatelessWidget {
  const _CornerOrnaments({required this.color, required this.scale});

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerOrnamentPainter(
          color: color,
          strokeWidth: 3 * scale,
          armLength: 12 * scale,
          inset: 4 * scale,
          cornerRadius: 6 * scale,
        ),
      ),
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  const _CornerOrnamentPainter({
    required this.color,
    required this.strokeWidth,
    required this.armLength,
    required this.inset,
    required this.cornerRadius,
  });

  final Color color;
  final double strokeWidth;
  final double armLength;
  final double inset;
  final double cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    void drawCorner(Offset corner, double dx, double dy) {
      final path = Path()
        ..moveTo(corner.dx + (dx * armLength), corner.dy)
        ..lineTo(corner.dx + (dx * cornerRadius), corner.dy)
        ..quadraticBezierTo(
          corner.dx,
          corner.dy,
          corner.dx,
          corner.dy + (dy * cornerRadius),
        )
        ..lineTo(corner.dx, corner.dy + (dy * armLength));
      canvas.drawPath(path, paint);
    }

    final half = strokeWidth / 2;
    final left = inset + half;
    final top = inset + half;
    final right = size.width - inset - half;
    final bottom = size.height - inset - half;

    drawCorner(Offset(left, top), 1, 1);
    drawCorner(Offset(right, top), -1, 1);
    drawCorner(Offset(left, bottom), 1, -1);
    drawCorner(Offset(right, bottom), -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CornerOrnamentPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.armLength != armLength ||
        oldDelegate.inset != inset ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}

/// Unread count, hanging off the outer rim's top-right corner. Never inside the
/// photo (invariant 1).
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({super.key, required this.count, required this.scale});

  final int count;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 26 * scale),
      height: 26 * scale,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 7 * scale),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black87, width: 2.5 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Text(
        '${count.clamp(1, 99)}',
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11 * scale,
          height: 1,
        ),
      ),
    );
  }
}
