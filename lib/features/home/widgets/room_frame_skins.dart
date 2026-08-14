import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

/// Equippable casing for a room card on 房間選擇.
///
/// The card payload (photo message zone, pet sprite, name / `Lv` / hunger ring,
/// caption) is identical in every style; only the casing changes. See
/// `design_handoff_room_frames/README.md` for the three invariants each skin
/// must obey:
///
/// 1. The photo message zone is untouchable — no rarity plate, sheen, badge or
///    gradient may paint over it.
/// 2. The pet overlaps the photo's bottom-right corner only.
/// 3. No frame name or rarity text on the card; names live in the 換相框 sheet.
enum RoomFrameStyle {
  polaroidClassic,
  corkboard,
  goldLeaf,
  nightGlow;

  /// Stable id used for persistence. Never rename these: they are written to
  /// durable storage and (later) to the server.
  String get storageKey {
    switch (this) {
      case RoomFrameStyle.polaroidClassic:
        return 'polaroid_classic';
      case RoomFrameStyle.corkboard:
        return 'corkboard';
      case RoomFrameStyle.goldLeaf:
        return 'gold_leaf';
      case RoomFrameStyle.nightGlow:
        return 'night_glow';
    }
  }

  static RoomFrameStyle? fromStorageKey(String? key) {
    if (key == null || key.isEmpty) {
      return null;
    }
    for (final style in RoomFrameStyle.values) {
      if (style.storageKey == key) {
        return style;
      }
    }
    return null;
  }
}

/// The decoration that sits above the card, straddling its top edge.
enum RoomFrameTopAccent { none, washiTape, pushpin }

/// A photo well drawn as a light bevel between the mat and the black outline
/// (`4b` sinks the photo into a white bevel on the kraft mat).
class RoomFramePhotoBevel {
  const RoomFramePhotoBevel({required this.width, required this.color});

  final double width;
  final Color color;
}

/// Every visual value one room-frame casing needs. One `const` instance per
/// [RoomFrameStyle] lives in [RoomFrameSkins].
class RoomFrameSkin {
  const RoomFrameSkin({
    required this.style,
    required this.rotationDegrees,
    required this.mountPadding,
    required this.mountRadius,
    required this.mountBorderWidth,
    required this.mountShadows,
    this.mountColor,
    this.mountGradient,
    this.sheenGradient,
    this.cornerOrnamentColor,
    required this.innerCardColor,
    required this.innerCardBorderWidth,
    required this.innerCardRadius,
    required this.photoInset,
    required this.photoBorderWidth,
    required this.photoRadius,
    this.photoBevel,
    required this.matPadding,
    required this.nameColor,
    required this.captionColor,
    required this.levelColor,
    required this.hungerRingColor,
    required this.hungerTrackColor,
    required this.hungerValueColor,
    required this.hungerFillColor,
    required this.topAccent,
    required this.petShadow,
    this.isDark = false,
  });

  final RoomFrameStyle style;

  /// Signed tilt of the whole casing, in degrees.
  final double rotationDegrees;

  // ── Outer rim / mount ──────────────────────────────────────────────────────
  /// Padding between the mount's inner edge and the inner card. Zero for the
  /// 拍立得 skins, which have no separate mount.
  final EdgeInsets mountPadding;
  final double mountRadius;
  final double mountBorderWidth;
  final List<BoxShadow> mountShadows;
  final Color? mountColor;
  final Gradient? mountGradient;

  /// Diagonal highlight filling the mount, painted UNDER the inner card so it
  /// only ever lights the rim (invariant 1).
  final Gradient? sheenGradient;

  /// When set, four L-shaped ornaments are stroked into the mount's corners.
  final Color? cornerOrnamentColor;

  // ── Inner card ─────────────────────────────────────────────────────────────
  final Color innerCardColor;
  final double innerCardBorderWidth;
  final double innerCardRadius;

  /// Padding around the photo zone inside the inner card. Bottom is always 0 —
  /// the mat owns the space below the photo.
  final EdgeInsets photoInset;

  // ── Photo zone ─────────────────────────────────────────────────────────────
  final double photoBorderWidth;
  final double photoRadius;
  final RoomFramePhotoBevel? photoBevel;

  // ── Mat ────────────────────────────────────────────────────────────────────
  final EdgeInsets matPadding;
  final Color nameColor;
  final Color captionColor;
  final Color levelColor;
  final Color hungerRingColor;
  final Color hungerTrackColor;
  final Color hungerValueColor;
  final Color hungerFillColor;

  final RoomFrameTopAccent topAccent;
  final BoxShadow petShadow;

  /// Dark casings need light-on-dark text and a heavier sprite shadow.
  final bool isDark;

  /// Total horizontal chrome (mount padding + both borders + photo inset)
  /// consumed before the photo itself, at scale 1.
  double get horizontalChrome =>
      mountPadding.horizontal +
      (mountBorderWidth * 2) +
      (innerCardBorderWidth * 2) +
      photoInset.horizontal;

  String localizedName(AppLocalizations l10n) {
    switch (style) {
      case RoomFrameStyle.polaroidClassic:
        return l10n.roomFrameStylePolaroidClassic;
      case RoomFrameStyle.corkboard:
        return l10n.roomFrameStyleCorkboard;
      case RoomFrameStyle.goldLeaf:
        return l10n.roomFrameStyleGoldLeaf;
      case RoomFrameStyle.nightGlow:
        return l10n.roomFrameStyleNightGlow;
    }
  }
}

/// The four shipped casings. Values are taken verbatim from
/// `design_handoff_room_frames/README.md` "The four skins (turn 4)".
class RoomFrameSkins {
  const RoomFrameSkins._();

  /// Aspect ratio of the photo message zone. Shared by every skin and by
  /// `HomePolaroidMemoryFrame`; changing it breaks invariant 1.
  static const double photoAspectRatio = 1.72;

  static const Color _ink = AppTheme.textPrimary;
  static const Color _muted = AppTheme.textSecondary;
  static const Color _hardShadowColor = Colors.black87;

  static const BoxShadow _hardShadow = BoxShadow(
    color: _hardShadowColor,
    offset: Offset(0, 5),
  );

  /// `0 3px 4px rgba(0,0,0,.22)` — the sprite reads as standing in the room.
  static const BoxShadow _petShadow = BoxShadow(
    color: Color(0x38000000),
    blurRadius: 4,
    offset: Offset(0, 3),
  );

  /// `0 3px 6px rgba(0,0,0,.5)` — deepened for the dark 夜光 mount.
  static const BoxShadow _petShadowDark = BoxShadow(
    color: Color(0x80000000),
    blurRadius: 6,
    offset: Offset(0, 3),
  );

  /// CSS `150deg` in Flutter alignment space: direction (sin θ, −cos θ).
  static const Alignment _deg150Begin = Alignment(-0.5, -0.87);
  static const Alignment _deg150End = Alignment(0.5, 0.87);

  /// CSS `112deg`.
  static const Alignment _deg112Begin = Alignment(-0.93, -0.37);
  static const Alignment _deg112End = Alignment(0.93, 0.37);

  /// `4a` 拍立得 · 經典 — true polaroid proportions, washi tape, deep bottom mat.
  static const RoomFrameSkin polaroidClassic = RoomFrameSkin(
    style: RoomFrameStyle.polaroidClassic,
    rotationDegrees: -1,
    mountPadding: EdgeInsets.zero,
    mountRadius: 14,
    mountBorderWidth: 3,
    mountColor: Colors.white,
    mountShadows: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 8)),
      _hardShadow,
    ],
    innerCardColor: Colors.white,
    innerCardBorderWidth: 0,
    innerCardRadius: 11,
    photoInset: EdgeInsets.fromLTRB(8, 8, 8, 0),
    photoBorderWidth: 2,
    photoRadius: 6,
    matPadding: EdgeInsets.fromLTRB(4, 12, 4, 16),
    nameColor: _ink,
    captionColor: _muted,
    levelColor: AppTheme.secondaryColor,
    hungerRingColor: Color(0xFFED8787),
    hungerTrackColor: Color(0x1F000000),
    hungerValueColor: _ink,
    hungerFillColor: Colors.white,
    topAccent: RoomFrameTopAccent.washiTape,
    petShadow: _petShadow,
  );

  /// `4b` 拍立得 · 軟木板 — kraft mat pinned to the board, photo sunk in a
  /// white bevel.
  static const RoomFrameSkin corkboard = RoomFrameSkin(
    style: RoomFrameStyle.corkboard,
    rotationDegrees: 1.2,
    mountPadding: EdgeInsets.zero,
    mountRadius: 10,
    mountBorderWidth: 3,
    mountColor: Color(0xFFF1E4CC),
    mountShadows: [
      BoxShadow(
        color: Color(0x2E000000),
        blurRadius: 16,
        offset: Offset(0, 10),
      ),
      _hardShadow,
    ],
    innerCardColor: Color(0xFFF1E4CC),
    innerCardBorderWidth: 0,
    innerCardRadius: 7,
    photoInset: EdgeInsets.fromLTRB(10, 10, 10, 0),
    photoBorderWidth: 2,
    photoRadius: 4,
    photoBevel: RoomFramePhotoBevel(width: 5, color: Colors.white),
    matPadding: EdgeInsets.fromLTRB(4, 12, 4, 16),
    nameColor: _ink,
    captionColor: _muted,
    levelColor: Color(0xFFC9803A),
    hungerRingColor: Color(0xFFE08A8A),
    hungerTrackColor: Color(0x1F000000),
    hungerValueColor: _ink,
    hungerFillColor: Color(0xFFFFF7EA),
    topAccent: RoomFrameTopAccent.pushpin,
    petShadow: _petShadow,
  );

  /// `4c` 收藏卡 · 金葉 — brushed-gold mount, mitred corner ornaments, a single
  /// diagonal sheen that lights the rim only.
  static const RoomFrameSkin goldLeaf = RoomFrameSkin(
    style: RoomFrameStyle.goldLeaf,
    rotationDegrees: 0,
    mountPadding: EdgeInsets.all(6),
    mountRadius: 18,
    mountBorderWidth: 3,
    mountGradient: LinearGradient(
      begin: _deg150Begin,
      end: _deg150End,
      colors: [
        Color(0xFFFFF0C9),
        Color(0xFFF0B75E),
        Color(0xFFC98A32),
        Color(0xFFFFE9B8),
      ],
      stops: [0, 0.38, 0.62, 1],
    ),
    mountShadows: [
      BoxShadow(color: Color(0x24000000), blurRadius: 14, offset: Offset(0, 8)),
      _hardShadow,
    ],
    sheenGradient: LinearGradient(
      begin: _deg112Begin,
      end: _deg112End,
      colors: [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)],
      stops: [0.36, 0.47, 0.58],
    ),
    cornerOrnamentColor: Color(0x80000000),
    innerCardColor: Color(0xFFFFFBF3),
    innerCardBorderWidth: 2.5,
    innerCardRadius: 12,
    photoInset: EdgeInsets.fromLTRB(8, 8, 8, 0),
    photoBorderWidth: 2,
    photoRadius: 6,
    matPadding: EdgeInsets.fromLTRB(4, 10, 4, 10),
    nameColor: _ink,
    captionColor: _muted,
    levelColor: Color(0xFFC08A2E),
    hungerRingColor: Color(0xFFED8787),
    hungerTrackColor: Color(0x1F000000),
    hungerValueColor: _ink,
    hungerFillColor: Color(0xFFFFFBF3),
    topAccent: RoomFrameTopAccent.none,
    petShadow: _petShadow,
  );

  /// `4d` 收藏卡 · 夜光 — ink card in a mint-to-violet glowing mount.
  static const RoomFrameSkin nightGlow = RoomFrameSkin(
    style: RoomFrameStyle.nightGlow,
    rotationDegrees: 0,
    mountPadding: EdgeInsets.all(6),
    mountRadius: 18,
    mountBorderWidth: 3,
    mountGradient: LinearGradient(
      begin: _deg150Begin,
      end: _deg150End,
      colors: [
        Color(0xFF8FE3C8),
        Color(0xFF5FBF9E),
        Color(0xFF6E63C8),
        Color(0xFFB9AEF2),
      ],
      stops: [0, 0.32, 0.78, 1],
    ),
    mountShadows: [
      BoxShadow(color: Color(0x737ED6B7), blurRadius: 18),
      _hardShadow,
    ],
    innerCardColor: Color(0xFF231F1B),
    innerCardBorderWidth: 2.5,
    innerCardRadius: 12,
    photoInset: EdgeInsets.fromLTRB(8, 8, 8, 0),
    photoBorderWidth: 2,
    photoRadius: 6,
    matPadding: EdgeInsets.fromLTRB(4, 10, 4, 10),
    nameColor: Color(0xFFFFF7EA),
    captionColor: Color(0xFFB9AF9E),
    levelColor: AppTheme.secondaryColor,
    hungerRingColor: Color(0xFFFF9A9E),
    hungerTrackColor: Color(0x33FFFFFF),
    hungerValueColor: Color(0xFFFFF7EA),
    hungerFillColor: Color(0xFF231F1B),
    topAccent: RoomFrameTopAccent.none,
    petShadow: _petShadowDark,
    isDark: true,
  );

  static const Map<RoomFrameStyle, RoomFrameSkin> byStyle =
      <RoomFrameStyle, RoomFrameSkin>{
        RoomFrameStyle.polaroidClassic: polaroidClassic,
        RoomFrameStyle.corkboard: corkboard,
        RoomFrameStyle.goldLeaf: goldLeaf,
        RoomFrameStyle.nightGlow: nightGlow,
      };

  static const RoomFrameStyle defaultStyle = RoomFrameStyle.polaroidClassic;

  static RoomFrameSkin resolve(RoomFrameStyle? style) {
    return byStyle[style ?? defaultStyle] ?? polaroidClassic;
  }

  /// Ordered for the 換相框 swatch grid: 拍立得 first, then 收藏卡.
  static const List<RoomFrameStyle> displayOrder = <RoomFrameStyle>[
    RoomFrameStyle.polaroidClassic,
    RoomFrameStyle.corkboard,
    RoomFrameStyle.goldLeaf,
    RoomFrameStyle.nightGlow,
  ];

  /// Candy price of a locked casing. The 拍立得 pair ships free; the 收藏卡
  /// pair is priced. Prices stay here until the shop-backed `items` rows land.
  static int? candyPrice(RoomFrameStyle style) {
    switch (style) {
      case RoomFrameStyle.polaroidClassic:
      case RoomFrameStyle.corkboard:
      case RoomFrameStyle.goldLeaf:
        return null;
      case RoomFrameStyle.nightGlow:
        return 300;
    }
  }
}
