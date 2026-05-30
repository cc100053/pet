import 'dart:ui';

/// Fixed virtual room canvas for shared furniture placement.
///
/// Plan A (see `tasks/todo.md`): placed furniture must appear in the same
/// relative position AND relative size for every room member regardless of
/// device/monitor size. We achieve this by mapping furniture into a fixed-aspect
/// "canvas" rect that is letterboxed (`BoxFit.contain`) inside the live pet
/// field, then storing each piece as a CENTER fraction (0..1) of that canvas and
/// sizing it as a fraction of the canvas width. Because the canvas aspect is a
/// constant, the same stored values produce an identical composition on every
/// client.
///
/// Scope: furniture only. Pets/food/poop keep using the full field.
class RoomCanvas {
  const RoomCanvas._();

  /// Canvas shape (width / height). Locked to the typical play-card shape so
  /// letterbox bands stay small on real devices while furniture placement stays
  /// identical across clients. Tune from real device metrics if needed.
  static const double aspectRatio = 1.2;

  /// Reference design width; only [aspectRatio] and [furnitureBaseWidthFraction]
  /// matter at runtime. The legacy fixed furniture footprint was 42px on a
  /// ~360-wide field, so the base fraction preserves the original look.
  static const double designWidth = 360;
  static const double furnitureBaseWidthFraction = 42 / designWidth;

  /// Largest [aspectRatio] rect that fits inside [field], centered
  /// (`BoxFit.contain`). Returned in field-local pixels.
  static Rect contentRect(Size field) {
    if (field.width <= 0 || field.height <= 0) {
      return Rect.zero;
    }
    final fieldAspect = field.width / field.height;
    double w;
    double h;
    if (fieldAspect > aspectRatio) {
      // Field is wider than the canvas -> height-bound.
      h = field.height;
      w = h * aspectRatio;
    } else {
      w = field.width;
      h = w / aspectRatio;
    }
    final left = (field.width - w) / 2;
    final top = (field.height - h) / 2;
    return Rect.fromLTWH(left, top, w, h);
  }

  /// Square furniture render size for a given user [scale], based on the canvas
  /// content width so it scales with the room.
  static Size furnitureSize(Rect content, double scale) {
    final side = content.width * furnitureBaseWidthFraction * scale;
    return Size(side, side);
  }

  /// Center fraction (0..1, canvas space) -> top-left pixel in field-local
  /// coords for an item of [itemSize].
  static Offset topLeftFromCenterFraction({
    required Offset centerFraction,
    required Rect content,
    required Size itemSize,
  }) {
    final cx = content.left + centerFraction.dx * content.width;
    final cy = content.top + centerFraction.dy * content.height;
    return Offset(cx - itemSize.width / 2, cy - itemSize.height / 2);
  }

  /// Field-local item center pixel -> center fraction (0..1) in canvas space.
  static Offset centerFractionFromCenter({
    required Offset center,
    required Rect content,
  }) {
    if (content.width <= 0 || content.height <= 0) {
      return const Offset(0.5, 0.5);
    }
    final fx = (center.dx - content.left) / content.width;
    final fy = (center.dy - content.top) / content.height;
    return Offset(fx, fy);
  }

  /// Clamp a center fraction so the whole item stays inside the content rect.
  static Offset clampCenterFraction({
    required Offset centerFraction,
    required Rect content,
    required Size itemSize,
  }) {
    if (content.width <= 0 || content.height <= 0) {
      return centerFraction;
    }
    final halfFx = (itemSize.width / 2) / content.width;
    final halfFy = (itemSize.height / 2) / content.height;
    final fx = halfFx >= 0.5
        ? 0.5
        : centerFraction.dx.clamp(halfFx, 1 - halfFx);
    final fy = halfFy >= 0.5
        ? 0.5
        : centerFraction.dy.clamp(halfFy, 1 - halfFy);
    return Offset(fx, fy);
  }

  /// Best-effort legacy top-left fraction stored in `position_x/y` so OLD app
  /// versions (fixed 42px item, full-field mapping) still place the piece near
  /// the right spot. For small items the center fraction is a good approximation
  /// of the legacy top-left fraction.
  static Offset legacyPositionFromCenterFraction(Offset centerFraction) {
    return Offset(
      centerFraction.dx.clamp(0.0, 1.0),
      centerFraction.dy.clamp(0.0, 1.0),
    );
  }
}
