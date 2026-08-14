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
    final matHeight =
        (skin.matPadding.vertical +
            _hungerRingSize +
            _matRowGap +
            _captionLineHeight +
            _matSlack) *
        scale;

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

  static const double _hungerRingSize = 26;
  static const double _matRowGap = 6;
  static const double _captionLineHeight = 14;
  static const double _matSlack = 4;
  static const double _topOverhang = 14;
  static const double _bottomOverhang = 7;

  static double _radians(double degrees) => degrees * math.pi / 180;
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
    this.equippedSkusBySlot = const <String, String>{},
    this.unreadCount = 0,
    this.scale = 1,
    this.dimmed = false,
    this.unreadBadgeKey,
  });

  final RoomFrameSkin skin;
  final String imageUrl;
  final String petName;
  final String caption;
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
    final spriteSize = 62.0 * scale;
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
      padding: skin.matPadding * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  petName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5 * scale,
                    fontWeight: FontWeight.w900,
                    color: skin.nameColor,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: 6 * scale),
              Text(
                petLevel == null ? 'Lv --' : 'Lv $petLevel',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.w900,
                  color: skin.levelColor,
                  height: 1,
                ),
              ),
              const Spacer(),
              _HungerRing(skin: skin, value: hungerValue, scale: scale),
            ],
          ),
          SizedBox(height: RoomFrameGeometry._matRowGap * scale),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5 * scale,
              fontWeight: FontWeight.w500,
              color: skin.captionColor,
              height: 1.2,
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
              strokeWidth: 2.5 * scale,
              ringColor: skin.hungerRingColor,
              trackColor: skin.hungerTrackColor,
              fillColor: skin.hungerFillColor,
            ),
          ),
          Text(
            '${(clamped * 100).round()}',
            style: TextStyle(
              fontSize: 10 * scale,
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
