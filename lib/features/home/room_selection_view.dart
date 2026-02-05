import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import '../pet/pet_catalog.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/ui/user_avatar.dart';
import 'widgets/home_polaroid_memory_frame.dart';

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

  static const _filmBase = Color(0xFFFFF9F2);

  @override
  Widget build(BuildContext context) {
    final totalSlots = max(4, rooms.length + 1);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppTheme.backgroundColor)),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    _buildMeButton(),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        l10n.roomSelectionTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  l10n.roomSelectionSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: totalSlots,
                  itemBuilder: (context, index) {
                    if (index < rooms.length) {
                      final room = rooms[index];
                      return _buildRoomCard(context, room, l10n)
                          .animate()
                          .fadeIn(delay: (80 * index).ms)
                          .slideY(begin: 0.1, end: 0);
                    }
                    return _buildEmptySlot(context, l10n)
                        .animate()
                        .fadeIn(delay: (80 * index).ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _buildPrimaryCta(context, l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeButton() {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: 42,
            height: 42,
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
              size: 42,
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
  ) {
    final roomId = room['id'] as String?;
    final isSelected = roomId != null && roomId == selectedRoomId;
    final latestPhoto = room['latest_photo'] as String?;
    final latestCaption = (room['latest_caption'] as String? ?? '').trim();
    final latestSenderId = room['latest_sender_id'] as String?;
    final senderAvatar =
        latestSenderId == null ? null : userAvatarById[latestSenderId];
    final senderName =
        latestSenderId == null ? null : userNameById[latestSenderId];
    final petName = (room['pet_name'] as String?)?.trim();
    final petType = room['pet_type'] as String?;
    final petDefinition = PetCatalog.byId(petType);
    final displayName =
        petName == null || petName.isEmpty ? petDefinition.name(l10n) : petName;
    final healthValue = (room['pet_health'] as num?)?.toDouble() ?? 0.0;
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
              color: isSelected ? AppTheme.textPrimary : Colors.black12,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: IgnorePointer(
                    child: HomePolaroidMemoryFrame(
                      imageUrl: latestPhoto ?? '',
                      caption: latestCaption,
                      userLabel: '',
                      senderAvatar: senderAvatar,
                      senderFallbackText: senderName,
                    ),
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const Gap(6),
                    _buildPetIcon(petDefinition.stayAsset),
                    const Gap(6),
                    _RoomHealthBar(value: healthValue),
                  ],
                ),
              ],
            ),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
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

  Widget _buildEmptySlot(BuildContext context, AppLocalizations l10n) {
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
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12, width: 1.2),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Gap(10),
              Text(
                l10n.roomSelectionEmptySlot,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryCta(BuildContext context, AppLocalizations l10n) {
    return Opacity(
      opacity: creatingRoom ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: creatingRoom ? null : onCreateRoom,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  creatingRoom
                      ? l10n.roomSelectionCreating
                      : l10n.roomSelectionCreatePet,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetIcon(String assetPath) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

class _RoomHealthBar extends StatelessWidget {
  const _RoomHealthBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 70,
      height: 12,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.black87, width: 1.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(1.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: clamped,
                child: Container(
                  color: const Color(0xFFed8787),
                ),
              ),
            ),
          ),
        ],
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
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
              ),
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
