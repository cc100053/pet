import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../pet/pet_catalog.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/adaptive_layout.dart';
import '../../shared/ui/juice_wrappers.dart';
import '../../shared/ui/pet_name_text_style.dart';
import '../../shared/ui/user_avatar.dart';
import 'widgets/home_responsive.dart';
import 'widgets/room_frame_card.dart';
import 'widgets/room_frame_picker_sheet.dart';
import 'widgets/room_frame_skins.dart';

/// Below this satiety, "feed me" outranks anything else the caption could say.
const double _hungryCaptionThreshold = 0.3;

/// Resolved caption line: what to say, who is saying it, and its glyph.
class _RoomCaption {
  const _RoomCaption(this.text, this.kind, this.icon);

  final String text;
  final RoomFrameCaptionKind kind;
  final IconData? icon;
}

class RoomSelectionView extends StatelessWidget {
  const RoomSelectionView({
    super.key,
    required this.rooms,
    this.unreadCountByRoom = const {},
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onSelectRoom,
    required this.onLeaveRoom,
    required this.creatingRoom,
    required this.joiningRoom,
    this.refreshingRooms = false,
    this.userAvatarById = const {},
    this.userNameById = const {},
    this.roomEquippedSkusBySlot = const {},
    this.roomFrameStyleByRoom = const {},
    this.onEquipRoomFrame,
    this.onOpenStore,
    this.coins = 0,
    this.diamonds = 0,
    this.selectedRoomId,
    this.userAvatarUrl,
    this.currentAppVersion,
    this.topBanner,
    this.highlightCreateRoomCta = false,
    this.createRoomCtaKey,
    this.highlightJoinRoomCta = false,
    this.joinRoomCtaKey,
  });

  final List<Map<String, dynamic>> rooms;
  final Map<String, int> unreadCountByRoom;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final ValueChanged<String> onSelectRoom;
  final ValueChanged<String> onLeaveRoom;
  final bool creatingRoom;
  final bool joiningRoom;
  final bool refreshingRooms;
  final Map<String, String?> userAvatarById;
  final Map<String, String?> userNameById;
  final Map<String, Map<String, String>> roomEquippedSkusBySlot;

  /// Casing each room currently wears, keyed by room id. Rooms without an entry
  /// fall back to [RoomFrameSkins.defaultStyle].
  final Map<String, RoomFrameStyle> roomFrameStyleByRoom;

  /// Commits a casing change. When null, long-pressing a card falls back to the
  /// room options sheet instead of opening 換相框.
  final Future<void> Function(String roomId, RoomFrameStyle style)?
  onEquipRoomFrame;
  final VoidCallback? onOpenStore;
  final int coins;
  final int diamonds;
  final String? selectedRoomId;
  final String? userAvatarUrl;
  final String? currentAppVersion;
  final Widget? topBanner;
  final bool highlightCreateRoomCta;
  final Key? createRoomCtaKey;
  final bool highlightJoinRoomCta;
  final Key? joinRoomCtaKey;

  /// Warm cream vertical gradient behind the whole screen.
  static const LinearGradient _backdrop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFBF3), Color(0xFFFFF3E2)],
  );

  static const Color _emptySlotBorder = Color(0x47000000);
  static const Color _emptySlotLabel = Color(0xFF9A9187);
  static String? _lastLayoutDebugLogKey;

  @override
  Widget build(BuildContext context) {
    final totalSlots = math.max(4, rooms.length + 1);
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = adaptiveContentMaxWidth(
          constraints.maxWidth,
          tabletMaxWidth: 560,
        );
        final responsive = HomeResponsiveSpec.fromWidth(constraints.maxWidth);
        final uiScale = homeUiScale(constraints.maxWidth);
        if (kDebugMode) {
          final key = [
            constraints.maxWidth.toStringAsFixed(1),
            maxContentWidth.isFinite
                ? maxContentWidth.toStringAsFixed(1)
                : 'inf',
            responsive.breakpoint.name,
            uiScale.toStringAsFixed(2),
          ].join('|');
          if (_lastLayoutDebugLogKey != key) {
            _lastLayoutDebugLogKey = key;
            debugPrint(
              '[ROOM_SELECTION_LAYOUT] viewportWidth=${constraints.maxWidth.toStringAsFixed(1)} '
              'maxContentWidth=${maxContentWidth.isFinite ? maxContentWidth.toStringAsFixed(1) : 'infinity'} '
              'breakpoint=${responsive.breakpoint.name} '
              'scale=${uiScale.toStringAsFixed(2)}',
            );
          }
        }
        final horizontalPadding =
            responsive.pick(compact: 14, regular: 18, expanded: 22) * uiScale;
        final headerTopPadding =
            responsive.pick(compact: 10, regular: 14, expanded: 18) * uiScale;
        final avatarSize = 42.0 * uiScale;
        final rowSpacing = 16.0 * uiScale;
        final columnSpacing = 14.0 * uiScale;
        // The CTA floats over the grid, so the grid has to end above it: the
        // button (56) + its hard shadow (5) + the gap below it + breathing room
        // above, or the last row of cards hides underneath.
        final gridBottomInset =
            responsive.pick(compact: 112, regular: 122, expanded: 132) *
            uiScale;
        // The button is the heaviest object on screen; sitting it 8pt off the
        // safe area made it look like it had slipped off the bottom edge. Give
        // it a margin in the same family as the horizontal padding.
        final ctaBottomInset =
            responsive.pick(compact: 22, regular: 24, expanded: 26) * uiScale;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: _backdrop),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        headerTopPadding,
                        horizontalPadding,
                        0,
                      ),
                      child: Row(
                        children: [
                          _buildMeButton(buttonSize: avatarSize),
                          Gap(10 * uiScale),
                          Expanded(
                            child: _AdaptiveHeaderTitle(
                              text: l10n.roomSelectionTitle,
                              height: 30 * uiScale,
                              style: TextStyle(
                                fontSize: 22 * uiScale,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                height: 1.1,
                              ),
                            ),
                          ),
                          _buildRefreshIndicator(uiScale),
                          _buildInvitePill(context, l10n, uiScale),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12 * uiScale,
                        horizontalPadding,
                        18 * uiScale,
                      ),
                      child: Text(
                        l10n.roomSelectionSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5 * uiScale,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (topBanner != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          8,
                        ),
                        child: topBanner!,
                      ),
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: LayoutBuilder(
                              builder: (context, gridConstraints) {
                                const crossAxisCount = 2;
                                final availableWidth =
                                    gridConstraints.maxWidth -
                                    (horizontalPadding * 2);
                                final itemWidth =
                                    (availableWidth -
                                        (columnSpacing *
                                            (crossAxisCount - 1))) /
                                    crossAxisCount;
                                final cellHeight = _cellHeight(
                                  itemWidth: itemWidth,
                                  uiScale: uiScale,
                                );

                                return GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    horizontalPadding,
                                    8,
                                    horizontalPadding,
                                    gridBottomInset,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: rowSpacing,
                                        crossAxisSpacing: columnSpacing,
                                        childAspectRatio:
                                            itemWidth / cellHeight,
                                      ),
                                  itemCount: totalSlots,
                                  itemBuilder: (context, index) {
                                    if (index < rooms.length) {
                                      return _buildRoomCard(
                                        context,
                                        rooms[index],
                                        l10n,
                                        uiScale,
                                      );
                                    }
                                    return _buildEmptySlot(l10n, uiScale);
                                  },
                                );
                              },
                            ),
                          ),
                          Positioned(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            bottom: ctaBottomInset,
                            child: SafeArea(
                              top: false,
                              child: _buildPrimaryCta(l10n, uiScale),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tallest card any skin needs at [itemWidth]. Every cell in the grid is the
  /// same height, so mixed skins must all fit the widest-chrome one.
  double _cellHeight({required double itemWidth, required double uiScale}) {
    var tallest = 0.0;
    for (final skin in RoomFrameSkins.byStyle.values) {
      final height = RoomFrameCard.estimateHeight(
        availableWidth: itemWidth,
        skin: skin,
        scale: uiScale,
      );
      tallest = math.max(tallest, height);
    }
    return tallest;
  }

  Widget _buildMeButton({required double buttonSize}) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black87, width: 2.5),
            ),
            child: ClipOval(
              child: UserAvatar(
                avatar: userAvatarUrl,
                fallbackText: null,
                size: buttonSize,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefreshIndicator(double uiScale) {
    return AnimatedOpacity(
      opacity: refreshingRooms ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: IgnorePointer(
        ignoring: !refreshingRooms,
        child: Padding(
          padding: EdgeInsets.only(right: 8 * uiScale),
          child: SizedBox(
            width: 14 * uiScale,
            height: 14 * uiScale,
            child: const CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  /// 邀請碼 pill: white, 2.5px black87, fully rounded, `0 3px 0` hard shadow.
  Widget _buildInvitePill(
    BuildContext context,
    AppLocalizations l10n,
    double uiScale,
  ) {
    final radius = BorderRadius.circular(999);
    return AnimatedContainer(
      key: joinRoomCtaKey,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: highlightJoinRoomCta
            ? Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.88),
                width: 2.2,
              )
            : null,
        boxShadow: highlightJoinRoomCta
            ? [
                BoxShadow(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.26),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: _HardShadowPressButton(
        onTap: joiningRoom ? null : onJoinRoom,
        borderRadius: radius,
        shadowDepth: 3 * uiScale,
        color: Colors.white,
        borderWidth: 2.5,
        padding: EdgeInsets.symmetric(
          horizontal: 12 * uiScale,
          vertical: 8 * uiScale,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.key_rounded,
              size: 15 * uiScale,
              color: AppTheme.primaryColor,
            ),
            Gap(5 * uiScale),
            Text(
              joiningRoom
                  ? l10n.roomSelectionJoining
                  : l10n.roomSelectionEnterInvite,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12 * uiScale,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    Map<String, dynamic> room,
    AppLocalizations l10n,
    double uiScale,
  ) {
    final roomId = room['id'] as String?;
    final isLocked = room['is_locked'] == true;
    final latestPhoto = room['latest_photo'] as String?;
    final latestCaption = (room['latest_caption'] as String? ?? '').trim();
    final petName = (room['pet_name'] as String?)?.trim();
    final petType = room['pet_type'] as String?;
    final petDefinition = PetCatalog.byIdForAppVersion(
      petType,
      appVersion: currentAppVersion,
    );
    final displayName = petName == null || petName.isEmpty
        ? petDefinition.name(l10n)
        : petName;
    final unreadCount = _resolveUnreadCount(room, roomId);
    final hungerValue = (room['pet_health'] as num?)?.toDouble() ?? 0.0;
    final petLevel = (room['pet_level'] as num?)?.toInt();
    final equippedSkusBySlot = roomId == null
        ? const <String, String>{}
        : (roomEquippedSkusBySlot[roomId] ?? const <String, String>{});
    final skin = RoomFrameSkins.resolve(
      roomId == null ? null : roomFrameStyleByRoom[roomId],
    );

    final caption = _resolveCaption(
      l10n: l10n,
      latestCaption: latestCaption,
      hasPhoto: latestPhoto != null && latestPhoto.isNotEmpty,
      hungerValue: hungerValue,
      displayName: displayName,
    );

    final frame = RoomFrameCard(
      skin: skin,
      imageUrl: latestPhoto ?? '',
      petName: displayName,
      caption: caption.text,
      captionKind: caption.kind,
      captionIcon: caption.icon,
      petLevel: petLevel,
      hungerValue: hungerValue,
      petId: petDefinition.id,
      petAssetPath: petDefinition.stayAsset,
      equippedSkusBySlot: equippedSkusBySlot,
      unreadCount: unreadCount,
      scale: uiScale,
      dimmed: isLocked,
      unreadBadgeKey: roomId == null
          ? null
          : Key('room_unread_indicator_$roomId'),
    );

    // The free-plan lock chip is not part of the frame design, but it is the
    // only signal that a room is paywalled. Keep it on the rim, never over the
    // photo message zone.
    final card = isLocked
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              frame,
              PositionedDirectional(
                top: 0,
                start: 0,
                child: IgnorePointer(
                  child: _buildLockedBadgeChip(l10n.roomLockedBadge, uiScale),
                ),
              ),
            ],
          )
        : frame;

    if (roomId == null) {
      return card;
    }

    return GestureDetector(
      onLongPress: () =>
          _handleLongPress(context, room, roomId, displayName, skin, l10n),
      child: JuicyScaleButton(
        // Spec: scale .96 on press; the skin's own rotation is preserved because
        // it lives inside the card, under this transform.
        lowerBound: 0.96,
        upperBound: 1.02,
        onTap: () => onSelectRoom(roomId),
        child: card,
      ),
    );
  }

  /// Text for the card's caption line, which is never allowed to be empty.
  ///
  /// A blank line under the name reads as a hole in the card, and hiding it
  /// would leave cards in the same grid at different heights. So the slot always
  /// says the most useful true thing available, falling back down this ladder —
  /// and everything below the first rung is marked as app-written, not human.
  _RoomCaption _resolveCaption({
    required AppLocalizations l10n,
    required String latestCaption,
    required bool hasPhoto,
    required double hungerValue,
    required String displayName,
  }) {
    if (latestCaption.isNotEmpty) {
      return _RoomCaption(latestCaption, RoomFrameCaptionKind.message, null);
    }
    if (hungerValue.isFinite && hungerValue < _hungryCaptionThreshold) {
      return _RoomCaption(
        l10n.roomSelectionStatusHungry(displayName),
        RoomFrameCaptionKind.status,
        Icons.restaurant_rounded,
      );
    }
    if (hasPhoto) {
      return _RoomCaption(
        l10n.roomSelectionStatusNewPhoto,
        RoomFrameCaptionKind.status,
        Icons.photo_camera_back_rounded,
      );
    }
    return _RoomCaption(
      l10n.roomSelectionStatusNoPhoto,
      RoomFrameCaptionKind.status,
      Icons.add_a_photo_rounded,
    );
  }

  Widget _buildLockedBadgeChip(String text, double uiScale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8 * uiScale,
        vertical: 4 * uiScale,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.5 * uiScale,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          height: 1,
        ),
      ),
    );
  }

  int _resolveUnreadCount(Map<String, dynamic> room, String? roomId) {
    if (roomId != null) {
      final providerCount = unreadCountByRoom[roomId];
      if (providerCount != null) {
        return providerCount;
      }
    }
    final raw = room['unread_count'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    return room['has_unread'] == true ? 1 : 0;
  }

  Future<void> _handleLongPress(
    BuildContext context,
    Map<String, dynamic> room,
    String roomId,
    String displayName,
    RoomFrameSkin skin,
    AppLocalizations l10n,
  ) async {
    final equip = onEquipRoomFrame;
    if (equip == null) {
      await _showRoomOptions(context, roomId, displayName, l10n);
      return;
    }
    final petDefinition = PetCatalog.byIdForAppVersion(
      room['pet_type'] as String?,
      appVersion: currentAppVersion,
    );
    final latestPhoto = (room['latest_photo'] as String?) ?? '';
    final hungerValue = (room['pet_health'] as num?)?.toDouble() ?? 0.0;
    // Same ladder as the grid card, so the sheet previews the real caption.
    final caption = _resolveCaption(
      l10n: l10n,
      latestCaption: ((room['latest_caption'] as String?) ?? '').trim(),
      hasPhoto: latestPhoto.isNotEmpty,
      hungerValue: hungerValue,
      displayName: displayName,
    );
    await showRoomFramePickerSheet(
      context: context,
      preview: RoomFramePreviewData(
        imageUrl: latestPhoto,
        petName: displayName,
        caption: caption.text,
        captionKind: caption.kind,
        captionIcon: caption.icon,
        petLevel: (room['pet_level'] as num?)?.toInt(),
        hungerValue: hungerValue,
        petId: petDefinition.id,
        petAssetPath: petDefinition.stayAsset,
        equippedSkusBySlot:
            roomEquippedSkusBySlot[roomId] ?? const <String, String>{},
      ),
      equippedStyle: skin.style,
      // Casings unlock by room level, so the gate is per room.
      roomLevel: (room['pet_level'] as num?)?.toInt(),
      coins: coins,
      diamonds: diamonds,
      onStoreTap: onOpenStore ?? () {},
      onEquip: (style) => equip(roomId, style),
      onLeaveRoom: () => onLeaveRoom(roomId),
    );
  }

  Future<void> _showRoomOptions(
    BuildContext context,
    String roomId,
    String petName,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.roomOptionsTitle, style: titleStyle),
              const Gap(4),
              Text(
                petName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: petNameTextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                ),
              ),
              const Gap(16),
              _RoomActionTile(
                // Same glyph as the 換相框 header's leave button — one action,
                // one icon, whichever way the player reaches it.
                icon: Icons.logout_rounded,
                label: l10n.roomOptionLeave,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  onLeaveRoom(roomId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 空位 placeholder: dashed rim, dashed `+` square, muted label.
  Widget _buildEmptySlot(AppLocalizations l10n, double uiScale) {
    return JuicyScaleButton(
      lowerBound: 0.96,
      upperBound: 1.02,
      onTap: creatingRoom ? null : onCreateRoom,
      child: CustomPaint(
        painter: _DashedRoundedBorderPainter(
          color: _emptySlotBorder,
          strokeWidth: 3 * uiScale,
          radius: 20 * uiScale,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                painter: _DashedRoundedBorderPainter(
                  color: _emptySlotBorder,
                  strokeWidth: 2.4 * uiScale,
                  radius: 13 * uiScale,
                ),
                child: SizedBox(
                  width: 42 * uiScale,
                  height: 42 * uiScale,
                  child: Icon(
                    Icons.add_rounded,
                    size: 22 * uiScale,
                    color: _emptySlotLabel,
                  ),
                ),
              ),
              Gap(10 * uiScale),
              Text(
                l10n.roomSelectionEmptySlot,
                style: TextStyle(
                  fontSize: 12 * uiScale,
                  fontWeight: FontWeight.w900,
                  color: _emptySlotLabel,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryCta(AppLocalizations l10n, double uiScale) {
    final radius = BorderRadius.circular(22 * uiScale);
    return Opacity(
      opacity: creatingRoom ? 0.6 : 1,
      child: AnimatedContainer(
        key: createRoomCtaKey,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: highlightCreateRoomCta
              ? Border.all(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.88),
                  width: 2.2,
                )
              : null,
          boxShadow: highlightCreateRoomCta
              ? [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.34),
                    blurRadius: 18,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: _HardShadowPressButton(
          onTap: creatingRoom ? null : onCreateRoom,
          borderRadius: radius,
          shadowDepth: 5 * uiScale,
          color: AppTheme.primaryColor,
          borderWidth: 3,
          height: 56 * uiScale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 20 * uiScale),
              Gap(6 * uiScale),
              Text(
                creatingRoom
                    ? l10n.roomSelectionCreating
                    : l10n.roomSelectionCreatePet,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16 * uiScale,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hard-shadow surface that presses into its own shadow: `translateY(depth)`
/// with the shadow collapsing to 0, per the design's press state.
///
/// It keeps the [JuicyScaleButton] contract that matters — `lightImpact` on
/// press, `mediumImpact` on release, and the callback fired immediately on
/// release rather than after the animation.
class _HardShadowPressButton extends StatefulWidget {
  const _HardShadowPressButton({
    required this.child,
    required this.onTap,
    required this.borderRadius,
    required this.shadowDepth,
    required this.color,
    required this.borderWidth,
    this.padding,
    this.height,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double shadowDepth;
  final Color color;
  final double borderWidth;
  final EdgeInsets? padding;
  final double? height;

  @override
  State<_HardShadowPressButton> createState() => _HardShadowPressButtonState();
}

class _HardShadowPressButtonState extends State<_HardShadowPressButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final depth = _pressed ? 0.0 : widget.shadowDepth;
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap == null) {
          return;
        }
        HapticFeedback.lightImpact();
        _setPressed(true);
      },
      onTapUp: (_) {
        if (widget.onTap == null) {
          return;
        }
        // Fire immediately; the release animation is cosmetic.
        widget.onTap!.call();
        HapticFeedback.mediumImpact();
        _setPressed(false);
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, widget.shadowDepth - depth, 0),
        height: widget.height,
        padding: widget.padding,
        alignment: widget.height != null ? Alignment.center : null,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: widget.borderRadius,
          border: Border.all(color: Colors.black87, width: widget.borderWidth),
          boxShadow: depth <= 0
              ? const []
              : [BoxShadow(color: Colors.black87, offset: Offset(0, depth))],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Dashed rounded rectangle, used for the 空位 placeholder rim and its `+` well.
class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  static const double dashLength = 7;
  static const double gapLength = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final half = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      half,
      half,
      math.max(0, size.width - strokeWidth),
      math.max(0, size.height - strokeWidth),
    );
    if (rect.isEmpty) {
      return;
    }
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(math.max(0, radius))),
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

class _AdaptiveHeaderTitle extends StatelessWidget {
  const _AdaptiveHeaderTitle({
    required this.text,
    required this.style,
    this.height = 36,
  });

  final String text;
  final TextStyle? style;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, maxLines: 1),
        ),
      ),
    );
  }
}

class _RoomActionTile extends StatelessWidget {
  const _RoomActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: ListTile(
              leading: Icon(icon, color: color),
              title: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
