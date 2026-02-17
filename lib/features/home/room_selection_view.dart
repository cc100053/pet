import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';
import '../pet/pet_catalog.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/pet_name_text_style.dart';
import '../../shared/ui/user_avatar.dart';
import 'widgets/home_responsive.dart';

class RoomSelectionView extends StatelessWidget {
  const RoomSelectionView({
    super.key,
    required this.rooms,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onSelectRoom,
    required this.onLeaveRoom,
    required this.creatingRoom,
    required this.joiningRoom,
    this.userAvatarById = const {},
    this.userNameById = const {},
    this.selectedRoomId,
    this.userAvatarUrl,
    this.topBanner,
  });

  final List<Map<String, dynamic>> rooms;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final ValueChanged<String> onSelectRoom;
  final ValueChanged<String> onLeaveRoom;
  final bool creatingRoom;
  final bool joiningRoom;
  final Map<String, String?> userAvatarById;
  final Map<String, String?> userNameById;
  final String? selectedRoomId;
  final String? userAvatarUrl;
  final Widget? topBanner;

  static const _filmBase = Color(0xFFFFF9F2);

  @override
  Widget build(BuildContext context) {
    final totalSlots = math.max(4, rooms.length + 1);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = HomeResponsiveSpec.fromWidth(constraints.maxWidth);
        final horizontalPadding = responsive.pick(
          compact: 14,
          regular: 20,
          expanded: 24,
        );
        final headerTopPadding = responsive.pick(
          compact: 10,
          regular: 16,
          expanded: 18,
        );
        final meButtonSize = responsive.pick(
          compact: 38,
          regular: 42,
          expanded: 44,
        );
        final gridSpacing = responsive.pick(
          compact: 12,
          regular: 16,
          expanded: 18,
        );
        final gridBottomInset = responsive.pick(
          compact: 98,
          regular: 112,
          expanded: 118,
        );
        final ctaBottomInset = responsive.pick(
          compact: 8,
          regular: 10,
          expanded: 12,
        );
        final crossAxisCount = responsive.isCompact ? 1 : 2;
        final bgTopOrbSize = responsive.pick(
          compact: 132,
          regular: 180,
          expanded: 200,
        );
        final bgBottomOrbSize = responsive.pick(
          compact: 150,
          regular: 200,
          expanded: 220,
        );

        return Stack(
          children: [
            Positioned.fill(child: Container(color: AppTheme.backgroundColor)),
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
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.roomSelectionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        if (responsive.isCompact)
                          IconButton(
                            onPressed: joiningRoom ? null : onJoinRoom,
                            icon: const Icon(Icons.key_rounded, size: 20),
                            color: AppTheme.textSecondary,
                            tooltip: l10n.roomSelectionEnterInvite,
                            visualDensity: VisualDensity.compact,
                          )
                        else
                          TextButton.icon(
                            onPressed: joiningRoom ? null : onJoinRoom,
                            icon: const Icon(Icons.key_rounded, size: 18),
                            label: Text(
                              joiningRoom
                                  ? l10n.roomSelectionJoining
                                  : l10n.roomSelectionEnterInvite,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                            ),
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
                        fontSize: responsive.pick(
                          compact: 13,
                          regular: 14,
                          expanded: 15,
                        ),
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
                                  (availableWidth - totalGap) / crossAxisCount;
                              final cardMinHeight = _roomCardMinHeight(
                                itemWidth,
                                responsive,
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
                                    );
                                  }
                                  return _buildEmptySlot(
                                    context,
                                    l10n,
                                    responsive,
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
                            child: _buildPrimaryCta(context, l10n, responsive),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildRoomCard(
    BuildContext context,
    Map<String, dynamic> room,
    AppLocalizations l10n,
    HomeResponsiveSpec responsive,
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
    final petDefinition = PetCatalog.byId(petType);
    final displayName = petName == null || petName.isEmpty
        ? petDefinition.name(l10n)
        : petName;
    final unreadCount = () {
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
    final memoryFrameAspectRatio = _memoryFrameAspectRatio(responsive);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: roomId == null ? null : () => onSelectRoom(roomId),
        onLongPress: roomId == null
            ? null
            : () => _showRoomOptions(context, roomId, displayName, l10n),
        child: Ink(
          decoration: BoxDecoration(
            color: _filmBase,
            borderRadius: BorderRadius.circular(18),
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
                  responsive.pick(compact: 10, regular: 12, expanded: 14),
                  responsive.pick(compact: 10, regular: 12, expanded: 14),
                  responsive.pick(compact: 10, regular: 12, expanded: 14),
                  responsive.pick(compact: 10, regular: 12, expanded: 14),
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
                          showAvatar: !responsive.isCompact,
                        ),
                      ),
                    ),
                    Gap(responsive.pick(compact: 6, regular: 8, expanded: 10)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: petNameTextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: responsive.pick(
                                compact: 12,
                                regular: 13,
                                expanded: 14,
                              ),
                            ),
                          ),
                        ),
                        Gap(
                          responsive.pick(compact: 4, regular: 6, expanded: 8),
                        ),
                        _RoomPetIconWithFloatingLevel(
                          assetPath: petDefinition.stayAsset,
                          level: petLevel,
                          size: responsive.pick(
                            compact: 24,
                            regular: 28,
                            expanded: 30,
                          ),
                          badgeFontSize: responsive.pick(
                            compact: 9,
                            regular: 10,
                            expanded: 10,
                          ),
                        ),
                        Gap(
                          responsive.pick(compact: 4, regular: 6, expanded: 8),
                        ),
                        _RoomHealthRing(
                          value: healthValue,
                          size: responsive.pick(
                            compact: 24,
                            regular: 28,
                            expanded: 30,
                          ),
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
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              if (hasUnread)
                Positioned(
                  top: 10,
                  right: isLocked ? 44 : 10,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: responsive.pick(
                        compact: 22,
                        regular: 24,
                        expanded: 24,
                      ),
                      height: responsive.pick(
                        compact: 22,
                        regular: 24,
                        expanded: 24,
                      ),
                      child: Container(
                        key: roomId == null
                            ? null
                            : Key('room_unread_indicator_$roomId'),
                        alignment: Alignment.center,
                        constraints: BoxConstraints(
                          minWidth: responsive.pick(
                            compact: 18,
                            regular: 20,
                            expanded: 20,
                          ),
                          minHeight: responsive.pick(
                            compact: 18,
                            regular: 20,
                            expanded: 20,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.pick(
                            compact: 5,
                            regular: 6,
                            expanded: 6,
                          ),
                          vertical: responsive.pick(
                            compact: 2,
                            regular: 2,
                            expanded: 2,
                          ),
                        ),
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
                            fontSize: responsive.pick(
                              compact: 8,
                              regular: 9,
                              expanded: 9,
                            ),
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (isLocked)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pick(
                        compact: 6,
                        regular: 8,
                        expanded: 8,
                      ),
                      vertical: responsive.pick(
                        compact: 3,
                        regular: 4,
                        expanded: 4,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.roomLockedBadge,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.pick(
                          compact: 9,
                          regular: 10,
                          expanded: 10,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
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
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: creatingRoom ? null : onCreateRoom,
        child: Ink(
          decoration: BoxDecoration(
            color: _filmBase,
            borderRadius: BorderRadius.circular(18),
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
                width: responsive.pick(compact: 72, regular: 90, expanded: 98),
                height: responsive.pick(compact: 72, regular: 90, expanded: 98),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12, width: 1.2),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: responsive.pick(compact: 22, regular: 26, expanded: 28),
                  color: AppTheme.textSecondary,
                ),
              ),
              Gap(responsive.pick(compact: 8, regular: 10, expanded: 12)),
              Text(
                l10n.roomSelectionEmptySlot,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  fontSize: responsive.pick(
                    compact: 13,
                    regular: 14,
                    expanded: 15,
                  ),
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

  double _roomCardMinHeight(double cardWidth, HomeResponsiveSpec responsive) {
    final frameHeight = cardWidth / _memoryFrameAspectRatio(responsive);
    final verticalPadding =
        responsive.pick(compact: 10, regular: 12, expanded: 14) * 2;
    final footerGap = responsive.pick(compact: 6, regular: 8, expanded: 10);
    final footerHeight = responsive.pick(compact: 2, regular: 2, expanded: 2);
    return frameHeight + verticalPadding + footerGap + footerHeight;
  }

  Widget _buildPrimaryCta(
    BuildContext context,
    AppLocalizations l10n,
    HomeResponsiveSpec responsive,
  ) {
    final radius = BorderRadius.circular(999);
    return Opacity(
      opacity: creatingRoom ? 0.6 : 1,
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
                    vertical: responsive.pick(
                      compact: 12,
                      regular: 14,
                      expanded: 15,
                    ),
                    horizontal: responsive.pick(
                      compact: 14,
                      regular: 18,
                      expanded: 20,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppTheme.primaryColor,
                        size: responsive.pick(
                          compact: 18,
                          regular: 20,
                          expanded: 21,
                        ),
                      ),
                      Gap(responsive.pick(compact: 6, regular: 8, expanded: 9)),
                      Text(
                        creatingRoom
                            ? l10n.roomSelectionCreating
                            : l10n.roomSelectionCreatePet,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: responsive.pick(
                                compact: 15,
                                regular: 16,
                                expanded: 17,
                              ),
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
    required this.showAvatar,
  });

  final String imageUrl;
  final String caption;
  final String? senderAvatar;
  final String? senderFallbackText;
  final HomeResponsiveSpec responsive;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final hasCaption = caption.trim().isNotEmpty;
    final captionTopPadding =
        responsive.pick(compact: 16, regular: 16, expanded: 16) * scale;
    final tokens = _RoomSelectionFrameTokens.from(
      scale: scale,
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
                          fontSize: 13 * scale,
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
    required this.assetPath,
    required this.level,
    this.size = 28,
    this.badgeFontSize = 10,
  });

  final String assetPath;
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
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
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
