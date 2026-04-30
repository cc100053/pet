import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';
import '../pet/pet_animated_image.dart';
import '../pet/pet_catalog.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/adaptive_layout.dart';
import '../../shared/ui/pet_name_text_style.dart';
import '../../shared/ui/user_avatar.dart';
import 'widgets/home_responsive.dart';
import 'widgets/pet_equipment_overlay.dart';

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
  final String? selectedRoomId;
  final String? userAvatarUrl;
  final String? currentAppVersion;
  final Widget? topBanner;
  final bool highlightCreateRoomCta;
  final Key? createRoomCtaKey;
  final bool highlightJoinRoomCta;
  final Key? joinRoomCtaKey;

  static const _filmBase = Color(0xFFFFF9F2);
  static String? _lastLayoutDebugLogKey;

  @override
  Widget build(BuildContext context) {
    final totalSlots = math.max(4, rooms.length + 1);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
            responsive.pick(compact: 14, regular: 20, expanded: 24) * uiScale;
        final headerTopPadding =
            responsive.pick(compact: 10, regular: 16, expanded: 18) * uiScale;
        final meButtonSize =
            responsive.pick(compact: 38, regular: 42, expanded: 44) * uiScale;
        final gridSpacing =
            responsive.pick(compact: 12, regular: 16, expanded: 18) * uiScale;
        final gridBottomInset =
            responsive.pick(compact: 98, regular: 112, expanded: 118) * uiScale;
        final ctaBottomInset =
            responsive.pick(compact: 8, regular: 10, expanded: 12) * uiScale;
        final crossAxisCount = responsive.isCompact ? 1 : 2;
        final bgTopOrbSize =
            responsive.pick(compact: 132, regular: 180, expanded: 200) *
            uiScale;
        final bgBottomOrbSize =
            responsive.pick(compact: 150, regular: 200, expanded: 220) *
            uiScale;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: AppTheme.backgroundColor),
                ),
                Positioned(
                  top: -bgTopOrbSize * 0.34,
                  right: -bgTopOrbSize * 0.22,
                  child: Container(
                    width: bgTopOrbSize,
                    height: bgTopOrbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 120,
                  left: -bgBottomOrbSize * 0.25,
                  child: Container(
                    width: bgBottomOrbSize,
                    height: bgBottomOrbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          headerTopPadding,
                          horizontalPadding,
                          8,
                        ),
                        child: Row(
                          children: [
                            _buildMeButton(buttonSize: meButtonSize),
                            Gap(
                              responsive.pick(
                                    compact: 8,
                                    regular: 12,
                                    expanded: 14,
                                  ) *
                                  uiScale,
                            ),
                            Expanded(
                              child: _AdaptiveHeaderTitle(
                                text: l10n.roomSelectionTitle,
                                height:
                                    responsive.pick(
                                      compact: 30,
                                      regular: 34,
                                      expanded: 36,
                                    ) *
                                    uiScale,
                                style:
                                    (responsive.isCompact
                                            ? theme.textTheme.titleLarge
                                            : theme.textTheme.headlineSmall)
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: refreshingRooms ? 1 : 0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: IgnorePointer(
                                ignoring: !refreshingRooms,
                                child: Container(
                                  margin: EdgeInsets.only(right: 8 * uiScale),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * uiScale,
                                    vertical: 6 * uiScale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: SizedBox(
                                    width: 14 * uiScale,
                                    height: 14 * uiScale,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppTheme.textSecondary,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _buildJoinRoomHeaderAction(
                              context,
                              l10n,
                              responsive,
                              uiScale,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          4,
                          horizontalPadding,
                          12,
                        ),
                        child: Text(
                          l10n.roomSelectionSubtitle,
                          maxLines: responsive.isCompact ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            fontSize:
                                responsive.pick(
                                  compact: 13,
                                  regular: 14,
                                  expanded: 15,
                                ) *
                                uiScale,
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
                                  final availableWidth =
                                      gridConstraints.maxWidth -
                                      (horizontalPadding * 2);
                                  final totalGap =
                                      gridSpacing * (crossAxisCount - 1);
                                  final itemWidth =
                                      (availableWidth - totalGap) /
                                      crossAxisCount;
                                  final cardMinHeight = _roomCardMinHeight(
                                    itemWidth,
                                    responsive,
                                    uiScale,
                                  );
                                  final childAspectRatio =
                                      itemWidth / cardMinHeight;

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
                                          mainAxisSpacing: gridSpacing,
                                          crossAxisSpacing: gridSpacing,
                                          childAspectRatio: childAspectRatio,
                                        ),
                                    itemCount: totalSlots,
                                    itemBuilder: (context, index) {
                                      if (index < rooms.length) {
                                        return _buildRoomCard(
                                          context,
                                          rooms[index],
                                          l10n,
                                          responsive,
                                          uiScale,
                                        );
                                      }
                                      return _buildEmptySlot(
                                        context,
                                        l10n,
                                        responsive,
                                        uiScale,
                                      );
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
                                child: _buildPrimaryCta(
                                  context,
                                  l10n,
                                  responsive,
                                  uiScale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeButton({required double buttonSize}) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: UserAvatar(
              avatar: userAvatarUrl,
              fallbackText: null,
              size: buttonSize,
            ),
          ),
        );
      },
    );
  }

  Widget _buildJoinRoomHeaderAction(
    BuildContext context,
    AppLocalizations l10n,
    HomeResponsiveSpec responsive,
    double uiScale,
  ) {
    final radius = BorderRadius.circular(responsive.isCompact ? 999 : 18);
    final action = responsive.isCompact
        ? IconButton(
            onPressed: joiningRoom ? null : onJoinRoom,
            icon: Icon(Icons.key_rounded, size: 20 * uiScale),
            color: AppTheme.textSecondary,
            tooltip: l10n.roomSelectionEnterInvite,
            visualDensity: VisualDensity.compact,
          )
        : TextButton.icon(
            onPressed: joiningRoom ? null : onJoinRoom,
            icon: Icon(Icons.key_rounded, size: 18 * uiScale),
            label: Text(
              joiningRoom
                  ? l10n.roomSelectionJoining
                  : l10n.roomSelectionEnterInvite,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
            ),
          );

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
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: highlightJoinRoomCta
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
          child: action,
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    Map<String, dynamic> room,
    AppLocalizations l10n,
    HomeResponsiveSpec responsive,
    double uiScale,
  ) {
    final roomId = room['id'] as String?;
    final isSelected = roomId != null && roomId == selectedRoomId;
    final isLocked = room['is_locked'] == true;
    final latestPhoto = room['latest_photo'] as String?;
    final latestCaption = (room['latest_caption'] as String? ?? '').trim();
    final latestSenderId = room['latest_sender_id'] as String?;
    final senderAvatar = latestSenderId == null
        ? null
        : userAvatarById[latestSenderId];
    final senderName = latestSenderId == null
        ? null
        : userNameById[latestSenderId];
    final petName = (room['pet_name'] as String?)?.trim();
    final petType = room['pet_type'] as String?;
    final petDefinition = PetCatalog.byIdForAppVersion(
      petType,
      appVersion: currentAppVersion,
    );
    final displayName = petName == null || petName.isEmpty
        ? petDefinition.name(l10n)
        : petName;
    final unreadCount = () {
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
    }();
    final hasUnread = unreadCount > 0;
    final unreadText = '${unreadCount.clamp(1, 99)}';
    final healthValue = (room['pet_health'] as num?)?.toDouble() ?? 0.0;
    final petLevel = (room['pet_level'] as num?)?.toInt();
    final equippedSkusBySlot = roomId == null
        ? const <String, String>{}
        : (roomEquippedSkusBySlot[roomId] ?? const <String, String>{});
    final memoryFrameAspectRatio = _memoryFrameAspectRatio(responsive);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * uiScale),
        onTap: roomId == null ? null : () => onSelectRoom(roomId),
        onLongPress: roomId == null
            ? null
            : () => _showRoomOptions(context, roomId, displayName, l10n),
        child: Ink(
          decoration: BoxDecoration(
            color: _filmBase,
            borderRadius: BorderRadius.circular(18 * uiScale),
            border: Border.all(
              color: isSelected
                  ? AppTheme.textPrimary
                  : (isLocked ? Colors.black38 : Colors.black12),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.pick(compact: 10, regular: 12, expanded: 14) *
                      uiScale,
                  responsive.pick(compact: 10, regular: 12, expanded: 14) *
                      uiScale,
                  responsive.pick(compact: 10, regular: 12, expanded: 14) *
                      uiScale,
                  responsive.pick(compact: 10, regular: 12, expanded: 14) *
                      uiScale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: memoryFrameAspectRatio,
                      child: IgnorePointer(
                        child: _RoomSelectionMemoryFrame(
                          imageUrl: latestPhoto ?? '',
                          caption: latestCaption,
                          senderAvatar: senderAvatar,
                          senderFallbackText: senderName,
                          responsive: responsive,
                          uiScale: uiScale,
                          showAvatar: !responsive.isCompact,
                        ),
                      ),
                    ),
                    Gap(
                      responsive.pick(compact: 6, regular: 8, expanded: 10) *
                          uiScale,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: petNameTextStyle(
                              color: AppTheme.textPrimary,
                              fontSize:
                                  responsive.pick(
                                    compact: 12,
                                    regular: 13,
                                    expanded: 14,
                                  ) *
                                  uiScale,
                            ),
                          ),
                        ),
                        Gap(
                          responsive.pick(compact: 4, regular: 6, expanded: 8) *
                              uiScale,
                        ),
                        _RoomPetIconWithFloatingLevel(
                          petId: petDefinition.id,
                          assetPath: petDefinition.stayAsset,
                          equippedSkusBySlot: equippedSkusBySlot,
                          level: petLevel,
                          size:
                              responsive.pick(
                                compact: 24,
                                regular: 28,
                                expanded: 30,
                              ) *
                              uiScale,
                          badgeFontSize:
                              responsive.pick(
                                compact: 9,
                                regular: 10,
                                expanded: 10,
                              ) *
                              uiScale,
                        ),
                        Gap(
                          responsive.pick(compact: 4, regular: 6, expanded: 8) *
                              uiScale,
                        ),
                        _RoomHealthRing(
                          value: healthValue,
                          size:
                              responsive.pick(
                                compact: 24,
                                regular: 28,
                                expanded: 30,
                              ) *
                              uiScale,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18 * uiScale),
                      ),
                    ),
                  ),
                ),
              if (hasUnread)
                PositionedDirectional(
                  top: 10 * uiScale,
                  end: 10 * uiScale,
                  child: IgnorePointer(
                    child: _buildUnreadCountBadge(
                      responsive: responsive,
                      unreadText: unreadText,
                      uiScale: uiScale,
                      key: roomId == null
                          ? null
                          : Key('room_unread_indicator_$roomId'),
                    ),
                  ),
                ),
              if (isLocked)
                PositionedDirectional(
                  top: 10 * uiScale,
                  start: 10 * uiScale,
                  child: IgnorePointer(
                    child: _buildLockedBadgeChip(
                      responsive: responsive,
                      text: l10n.roomLockedBadge,
                      uiScale: uiScale,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadCountBadge({
    required HomeResponsiveSpec responsive,
    required String unreadText,
    required double uiScale,
    Key? key,
  }) {
    final size =
        responsive.pick(compact: 22, regular: 24, expanded: 24) * uiScale;
    return Container(
      key: key,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        unreadText,
        maxLines: 1,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize:
              responsive.pick(compact: 10, regular: 11, expanded: 11) * uiScale,
        ),
      ),
    );
  }

  Widget _buildLockedBadgeChip({
    required HomeResponsiveSpec responsive,
    required String text,
    required double uiScale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
            responsive.pick(compact: 6, regular: 8, expanded: 8) * uiScale,
        vertical:
            responsive.pick(compact: 3, regular: 4, expanded: 4) * uiScale,
      ),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize:
              responsive.pick(compact: 9, regular: 10, expanded: 10) * uiScale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
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
                icon: Icons.exit_to_app_rounded,
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

  Widget _buildEmptySlot(
    BuildContext context,
    AppLocalizations l10n,
    HomeResponsiveSpec responsive,
    double uiScale,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18 * uiScale),
        onTap: creatingRoom ? null : onCreateRoom,
        child: Ink(
          decoration: BoxDecoration(
            color: _filmBase,
            borderRadius: BorderRadius.circular(18 * uiScale),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width:
                    responsive.pick(compact: 72, regular: 90, expanded: 98) *
                    uiScale,
                height:
                    responsive.pick(compact: 72, regular: 90, expanded: 98) *
                    uiScale,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14 * uiScale),
                  border: Border.all(color: Colors.black12, width: 1.2),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size:
                      responsive.pick(compact: 22, regular: 26, expanded: 28) *
                      uiScale,
                  color: AppTheme.textSecondary,
                ),
              ),
              Gap(
                responsive.pick(compact: 8, regular: 10, expanded: 12) *
                    uiScale,
              ),
              Text(
                l10n.roomSelectionEmptySlot,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  fontSize:
                      responsive.pick(compact: 13, regular: 14, expanded: 15) *
                      uiScale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _memoryFrameAspectRatio(HomeResponsiveSpec responsive) {
    return responsive.pick(compact: 1.25, regular: 0.88, expanded: 0.92);
  }

  double _roomCardMinHeight(
    double cardWidth,
    HomeResponsiveSpec responsive,
    double uiScale,
  ) {
    final frameHeight = cardWidth / _memoryFrameAspectRatio(responsive);
    final verticalPadding =
        responsive.pick(compact: 10, regular: 12, expanded: 14) * 2 * uiScale;
    final footerGap =
        responsive.pick(compact: 6, regular: 8, expanded: 10) * uiScale;
    final footerHeight =
        responsive.pick(compact: 2, regular: 2, expanded: 2) * uiScale;
    return frameHeight + verticalPadding + footerGap + footerHeight;
  }

  Widget _buildPrimaryCta(
    BuildContext context,
    AppLocalizations l10n,
    HomeResponsiveSpec responsive,
    double uiScale,
  ) {
    final radius = BorderRadius.circular(999);
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
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: Colors.white.withValues(alpha: 0.34),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.72),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: creatingRoom ? null : onCreateRoom,
                  borderRadius: radius,
                  splashColor: AppTheme.primaryColor.withValues(alpha: 0.14),
                  highlightColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical:
                          responsive.pick(
                            compact: 12,
                            regular: 14,
                            expanded: 15,
                          ) *
                          uiScale,
                      horizontal:
                          responsive.pick(
                            compact: 14,
                            regular: 18,
                            expanded: 20,
                          ) *
                          uiScale,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.primaryColor,
                          size:
                              responsive.pick(
                                compact: 18,
                                regular: 20,
                                expanded: 21,
                              ) *
                              uiScale,
                        ),
                        Gap(
                          responsive.pick(compact: 6, regular: 8, expanded: 9) *
                              uiScale,
                        ),
                        Text(
                          creatingRoom
                              ? l10n.roomSelectionCreating
                              : l10n.roomSelectionCreatePet,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize:
                                    responsive.pick(
                                      compact: 15,
                                      regular: 16,
                                      expanded: 17,
                                    ) *
                                    uiScale,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

class _RoomSelectionMemoryFrame extends StatelessWidget {
  const _RoomSelectionMemoryFrame({
    required this.imageUrl,
    required this.caption,
    required this.senderAvatar,
    required this.senderFallbackText,
    required this.responsive,
    required this.uiScale,
    required this.showAvatar,
  });

  final String imageUrl;
  final String caption;
  final String? senderAvatar;
  final String? senderFallbackText;
  final HomeResponsiveSpec responsive;
  final double uiScale;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final hasCaption = caption.trim().isNotEmpty;
    final captionTopPadding =
        responsive.pick(compact: 16, regular: 16, expanded: 16) * uiScale;
    final tokens = _RoomSelectionFrameTokens.from(
      scale: uiScale,
      responsive: responsive,
      showAvatar: showAvatar,
    );

    return Container(
      padding: EdgeInsets.all(tokens.innerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: CustomMultiChildLayout(
        delegate: _RoomSelectionFrameLayoutDelegate(tokens: tokens),
        children: [
          LayoutId(
            id: _RoomSelectionFrameSlot.photo,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black87, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isEmpty
                    ? const _RoomFramePlaceholder()
                    : CachedNetworkImageView(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        portraitFriendlyCrop: true,
                      ),
              ),
            ),
          ),
          LayoutId(
            id: _RoomSelectionFrameSlot.caption,
            child: hasCaption
                ? Padding(
                    padding: EdgeInsets.only(top: captionTopPadding),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        caption.trim(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13 * uiScale,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (showAvatar)
            LayoutId(
              id: _RoomSelectionFrameSlot.avatar,
              child: Center(
                child: Container(
                  width: tokens.avatarSize,
                  height: tokens.avatarSize,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    avatar: senderAvatar,
                    fallbackText: senderFallbackText,
                    size: tokens.avatarSize - 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _RoomSelectionFrameSlot { photo, caption, avatar }

class _RoomSelectionFrameTokens {
  const _RoomSelectionFrameTokens({
    required this.innerPadding,
    required this.avatarSize,
    required this.photoRatio,
    required this.avatarOverlapRatio,
  });

  final double innerPadding;
  final double avatarSize;
  final double photoRatio;
  final double avatarOverlapRatio;

  factory _RoomSelectionFrameTokens.from({
    required double scale,
    required HomeResponsiveSpec responsive,
    required bool showAvatar,
  }) {
    return _RoomSelectionFrameTokens(
      innerPadding: 12 * scale,
      avatarSize: showAvatar
          ? responsive.pick(compact: 34, regular: 40, expanded: 36) * scale
          : 0,
      photoRatio: responsive.pick(compact: 0.76, regular: 0.76, expanded: 0.76),
      avatarOverlapRatio: responsive.pick(
        compact: 0.58,
        regular: 0.60,
        expanded: 0.62,
      ),
    );
  }
}

class _RoomSelectionFrameLayoutDelegate extends MultiChildLayoutDelegate {
  _RoomSelectionFrameLayoutDelegate({required this.tokens});

  final _RoomSelectionFrameTokens tokens;

  @override
  void performLayout(Size size) {
    final photoHeight = (size.height * tokens.photoRatio).clamp(
      0.0,
      size.height,
    );
    final captionHeight = math.max(0.0, size.height - photoHeight);

    if (hasChild(_RoomSelectionFrameSlot.photo)) {
      layoutChild(
        _RoomSelectionFrameSlot.photo,
        BoxConstraints.tight(Size(size.width, photoHeight)),
      );
      positionChild(_RoomSelectionFrameSlot.photo, Offset.zero);
    }

    if (hasChild(_RoomSelectionFrameSlot.caption)) {
      layoutChild(
        _RoomSelectionFrameSlot.caption,
        BoxConstraints.tight(Size(size.width, captionHeight)),
      );
      positionChild(_RoomSelectionFrameSlot.caption, Offset(0, photoHeight));
    }

    if (hasChild(_RoomSelectionFrameSlot.avatar)) {
      final avatarSize = tokens.avatarSize;
      layoutChild(
        _RoomSelectionFrameSlot.avatar,
        BoxConstraints.tight(Size(avatarSize, avatarSize)),
      );
      final dx = (size.width - avatarSize) / 2;
      final dy = photoHeight - (avatarSize * tokens.avatarOverlapRatio);
      positionChild(_RoomSelectionFrameSlot.avatar, Offset(dx, dy));
    }
  }

  @override
  bool shouldRelayout(covariant _RoomSelectionFrameLayoutDelegate oldDelegate) {
    return oldDelegate.tokens != tokens;
  }
}

class _RoomFramePlaceholder extends StatelessWidget {
  const _RoomFramePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.photo,
        size: 34,
        color: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }
}

class _RoomPetIconWithFloatingLevel extends StatelessWidget {
  const _RoomPetIconWithFloatingLevel({
    required this.petId,
    required this.assetPath,
    required this.equippedSkusBySlot,
    required this.level,
    this.size = 28,
    this.badgeFontSize = 10,
  });

  final String petId;
  final String assetPath;
  final Map<String, String> equippedSkusBySlot;
  final int? level;
  final double size;
  final double badgeFontSize;

  @override
  Widget build(BuildContext context) {
    final imageSize = size * 0.79;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: imageSize,
            height: imageSize,
            child: PetAnimationFrameBuilder(
              sourceAsset: assetPath,
              builder: (context, petAsset, animationProgress, _) {
                final previewSize = Size.square(imageSize);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PetEquipmentOverlay(
                      petId: petId,
                      equippedSkusBySlot: equippedSkusBySlot,
                      petSize: previewSize,
                      layer: PetEquipmentOverlayLayer.behindPet,
                      animationProgress: animationProgress,
                    ),
                    Image.asset(
                      petAsset,
                      width: previewSize.width,
                      height: previewSize.height,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                    PetEquipmentOverlay(
                      petId: petId,
                      equippedSkusBySlot: equippedSkusBySlot,
                      petSize: previewSize,
                      layer: PetEquipmentOverlayLayer.frontPet,
                      animationProgress: animationProgress,
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: size - 2,
            child: _RoomLevelBadge(level: level, fontSize: badgeFontSize),
          ),
        ],
      ),
    );
  }
}

class _RoomHealthRing extends StatelessWidget {
  const _RoomHealthRing({required this.value, this.size = 28});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    final healthNumber = (clamped * 100).round();
    final numberFontSize = size <= 24 ? 8.0 : 9.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RoomHealthRingPainter(progress: clamped, size: size),
          ),
          Text(
            '$healthNumber',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: numberFontSize,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomLevelBadge extends StatelessWidget {
  const _RoomLevelBadge({required this.level, required this.fontSize});

  final int? level;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      level == null ? 'Lv --' : 'Lv $level',
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: AppTheme.secondaryColor,
        height: 1,
      ).copyWith(fontSize: fontSize),
    );
  }
}

class _RoomHealthRingPainter extends CustomPainter {
  _RoomHealthRingPainter({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final strokeWidth = this.size <= 24 ? 2.4 : 3.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.black26;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFed8787);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomHealthRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
