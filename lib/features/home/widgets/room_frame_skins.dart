import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/compatibility/shared_decor_compatibility.dart';
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
  /// The pre-redesign room card, kept as an equippable casing so no player
  /// loses the look they already had.
  original,
  polaroidClassic,
  corkboard,
  goldLeaf,
  nightGlow;

  /// Stable id used for persistence. Never rename these: they are written to
  /// durable storage and (later) to the server.
  String get storageKey {
    switch (this) {
      case RoomFrameStyle.original:
        return 'original';
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
    required this.unlockLevel,
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
    this.levelTextColor,
    required this.hungerRingColor,
    required this.hungerTrackColor,
    required this.hungerValueColor,
    required this.hungerFillColor,
    required this.topAccent,
    required this.petShadow,
    this.isDark = false,
  });

  final RoomFrameStyle style;

  /// Room level at which this casing unlocks. See [RoomFrameSkins] for how the
  /// ladder was calibrated.
  ///
  /// These may be **lowered** later but never raised: raising one retracts a
  /// casing a room already equipped. The picker grandfathers the equipped
  /// casing for exactly that reason, but the retraction would still be visible
  /// as a lock on the swatch the room is wearing.
  final int unlockLevel;

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

  /// Tints the `Lv` chip's fill (at 18% alpha), so each casing keeps its own
  /// accent.
  final Color levelColor;

  /// Ink for the `Lv` chip's text.
  ///
  /// Split from [levelColor] because the two answer different questions: the
  /// fill only has to belong to the casing, but the text has to be readable on
  /// top of that fill. Reusing one warm accent for both put every light casing
  /// between 1.59:1 and 2.48:1 — `original`'s orange on white was the worst of
  /// them. Defaults to [levelColor] for casings whose accent already carries
  /// enough contrast on its own card (only `nightGlow`, at 6.18:1).
  ///
  /// `room_frame_test.dart` holds every casing to 4.5:1 against its own chip.
  final Color? levelTextColor;

  /// The colour the `Lv` text is actually painted in.
  Color get levelInk => levelTextColor ?? levelColor;
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
      case RoomFrameStyle.original:
        return l10n.roomFrameStyleOriginal;
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

  /// The variant half of [localizedName] — "經典" out of "拍立得 · 經典".
  ///
  /// Derived rather than translated separately: the two can then never drift,
  /// and every locale writes the name as `family · variant` (or as a single
  /// word, which comes back whole). Use it where a name must fit a lane too
  /// narrow for the family prefix, such as the 換相框 swatches.
  String shortLocalizedName(AppLocalizations l10n) {
    final name = localizedName(l10n);
    final separator = name.lastIndexOf('·');
    if (separator < 0) {
      return name;
    }
    return name.substring(separator + 1).trim();
  }
}

/// The shipped casings: the original room card plus the four from the handoff,
/// whose values are taken verbatim from
/// `design_handoff_room_frames/README.md` "The four skins (turn 4)".
///
/// Casings unlock by room level via [RoomFrameSkin.unlockLevel].
///
/// ## The unlock ladder
///
/// Calibrated 2026-08-15 the way `docs/shop_pricing.md` prices coins: in days
/// of play, against the live distribution, with a reachable ceiling.
///
/// Exp comes from **rewarded feeds only** (`apply_pet_action` grants `+10` when
/// `v_reward > 0`, behind the 10-minute feed cooldown), and
/// `xpRequiredForNextLevel` is `50 * level`, so reaching level `N` costs
/// `2.5 * N * (N - 1)` rewarded feeds. Live 30-day median is ~2 rewarded feeds
/// per active day, which converts the ladder to:
///
/// | Casing | Lv | Feeds | ≈ days | Active rooms that have it today |
/// |---|---|---|---|---|
/// | 原始 / 拍立得·經典 | 1 | 0 | 0 | 100% |
/// | 軟木板 | 3 | 15 | ~7 | 41% |
/// | 金葉 | 5 | 50 | ~25 | 29% |
/// | 夜光 | 8 | 140 | ~70 | 17% |
///
/// Two casings sit at level 1 on purpose. `original` is the default, so a
/// ladder that gated everything else would make 換相框 a menu of locks on first
/// open — the same reason `docs/shop_pricing.md` requires a 100-coin rung in
/// every drop.
///
/// Distribution the rungs were cut against (`room_pet_state`, 2026-08-15):
/// 293 rooms total, 70% still level 1, max level 14; of the 58 rooms active in
/// the last 30 days, median 2, p75 ~5.75, p90 12.
///
/// Recalibrate by re-running:
///
/// ```sql
/// select level, count(*) from public.room_pet_state group by 1 order by 1;
/// select count(*) from public.coin_ledger
///  where source = 'feed' and amount > 0 and created_at > now() - interval '30 days';
/// ```
class RoomFrameSkins {
  const RoomFrameSkins._();

  /// Aspect ratio of the photo message zone, shared by every skin.
  ///
  /// The photo is the reason the card exists, so it gets the card's height
  /// budget: at 4:3-ish the zone reads as a photo rather than the letterbox
  /// strip a wider ratio collapses into at two-column widths. The mat below is
  /// sized from its own contents (see [RoomFrameGeometry]), so the two never
  /// compete — widening this ratio again would shrink the photo, not the mat.
  static const double photoAspectRatio = 1.25;

  static const Color _ink = AppTheme.textPrimary;

  /// `Lv` chip text for every light casing: a warm brown that stays in the
  /// accents' hue family while clearing 4.5:1 on all three light chip fills
  /// (`original`/`polaroidClassic` 6.09, `corkboard` 4.60, `goldLeaf` 5.49).
  static const Color _levelInk = Color(0xFF8A4C0C);
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

  /// The original room card, preserved as a casing: plain white, soft shadow,
  /// no tilt and no accent, with the pre-redesign radii (card 22, photo 14) and
  /// its thinner 2px / 1.5px outlines.
  static const RoomFrameSkin original = RoomFrameSkin(
    style: RoomFrameStyle.original,
    unlockLevel: 1,
    rotationDegrees: 0,
    mountPadding: EdgeInsets.zero,
    mountRadius: 22,
    mountBorderWidth: 2,
    mountColor: Colors.white,
    mountShadows: [
      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
    ],
    innerCardColor: Colors.white,
    innerCardBorderWidth: 0,
    innerCardRadius: 20,
    photoInset: EdgeInsets.fromLTRB(12, 12, 12, 0),
    photoBorderWidth: 1.5,
    photoRadius: 14,
    matPadding: EdgeInsets.fromLTRB(4, 10, 4, 12),
    nameColor: _ink,
    captionColor: _muted,
    levelColor: AppTheme.secondaryColor,
    levelTextColor: _levelInk,
    hungerRingColor: Color(0xFFED8787),
    hungerTrackColor: Color(0x1F000000),
    hungerValueColor: _ink,
    hungerFillColor: Colors.white,
    topAccent: RoomFrameTopAccent.none,
    petShadow: _petShadow,
  );

  /// `4a` 拍立得 · 經典 — true polaroid proportions, washi tape, deep bottom mat.
  static const RoomFrameSkin polaroidClassic = RoomFrameSkin(
    style: RoomFrameStyle.polaroidClassic,
    unlockLevel: 1,
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
    levelTextColor: _levelInk,
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
    unlockLevel: 3,
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
    levelTextColor: _levelInk,
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
    unlockLevel: 5,
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
    levelTextColor: _levelInk,
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
    unlockLevel: 8,
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
        RoomFrameStyle.original: original,
        RoomFrameStyle.polaroidClassic: polaroidClassic,
        RoomFrameStyle.corkboard: corkboard,
        RoomFrameStyle.goldLeaf: goldLeaf,
        RoomFrameStyle.nightGlow: nightGlow,
      };

  /// A room that has never picked a casing keeps the card it already had.
  static const RoomFrameStyle defaultStyle = RoomFrameStyle.original;

  /// 換相框 ships in 3.0.0. Below it, every surface of the feature is dark:
  /// long press falls back to the room options sheet, the coach bubble is not
  /// drawn (so it does not spend its one-shot flag before there is anything to
  /// teach), and every card renders [defaultStyle] — the pre-redesign card.
  ///
  /// The gate reads the running app version rather than a build flag so a
  /// 2.4.x build cut from this tree cannot expose the feature by accident.
  static const String minAppVersion = '3.0.0';

  /// Whether this build may show 換相框 at all.
  ///
  /// A null [appVersion] reads as unsupported, matching [PetCatalog]: the
  /// version resolves asynchronously from `PackageInfo`, and a feature that
  /// flickers on before the gate is known is worse than one that appears a
  /// frame late.
  static bool isAvailableOnAppVersion(String? appVersion) {
    return SharedDecorCompatibility.supportsAppVersion(
      minAppVersion: minAppVersion,
      appVersion: appVersion,
    );
  }

  /// The casing a room card wears on this build: what the room picked once the
  /// feature is live, and always the pre-redesign card before that.
  ///
  /// Equipped casings survive the gate closed — they live in Hive and are read
  /// back untouched — so a player who picked one in 3.0.0 and rolled back to
  /// 2.4.x sees the original card, then their casing again on re-upgrade.
  static RoomFrameSkin resolveForAppVersion(
    RoomFrameStyle? style, {
    required String? appVersion,
  }) {
    return resolve(isAvailableOnAppVersion(appVersion) ? style : null);
  }

  static RoomFrameSkin resolve(RoomFrameStyle? style) {
    return byStyle[style ?? defaultStyle] ?? original;
  }

  /// Ordered for the 換相框 swatch grid: the original card, then 拍立得, then
  /// 收藏卡.
  static const List<RoomFrameStyle> displayOrder = <RoomFrameStyle>[
    RoomFrameStyle.original,
    RoomFrameStyle.polaroidClassic,
    RoomFrameStyle.corkboard,
    RoomFrameStyle.goldLeaf,
    RoomFrameStyle.nightGlow,
  ];

  /// Room level at which [style] unlocks.
  static int unlockLevel(RoomFrameStyle style) => resolve(style).unlockLevel;

  /// Whether a room at [roomLevel] may equip [style].
  ///
  /// An unknown level (a room whose pet summary has not loaded) reads as
  /// level 1, so a failed summary load can never hand out a gated casing. The
  /// picker grandfathers whatever the room already wears, so the conservative
  /// reading cannot strip a casing either — at worst the higher swatches read
  /// as locked until the summary lands.
  static bool isUnlocked(RoomFrameStyle style, int? roomLevel) {
    return (roomLevel ?? 1) >= unlockLevel(style);
  }

  static Set<RoomFrameStyle> unlockedFor(int? roomLevel) {
    return {
      for (final style in displayOrder)
        if (isUnlocked(style, roomLevel)) style,
    };
  }
}
