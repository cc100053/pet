import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import '../../shared/theme/app_theme.dart';

class RoomSelectionView extends StatelessWidget {
  const RoomSelectionView({
    super.key,
    required this.rooms,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onSelectRoom,
    required this.creatingRoom,
    required this.joiningRoom,
    this.selectedRoomId,
  });

  final List<Map<String, dynamic>> rooms;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final ValueChanged<String> onSelectRoom;
  final bool creatingRoom;
  final bool joiningRoom;
  final String? selectedRoomId;

  static const _mint = Color(0xFF7ED9C0);
  static const _filmBase = Color(0xFFFFF9F2);
  static const _moodHigh = Color(0xFF67CBA0);
  static const _moodMid = Color(0xFFF3B562);
  static const _moodLow = Color(0xFF9CB1C7);
  static const _moodSad = Color(0xFFF28B82);

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
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.textPrimary,
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
    final mood = room['mood'] as String?;
    final moodColor = _moodColor(mood);
    final moodDotCount = _moodDotCount(mood);
    final latestPhoto = room['latest_photo'] as String?;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: roomId == null ? null : () => onSelectRoom(roomId),
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
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12, width: 1.2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: latestPhoto == null || latestPhoto.isEmpty
                              ? Container(
                                  color: const Color(0xFFF8F4EF),
                                  child: const Center(
                                    child: Icon(
                                      Icons.photo_rounded,
                                      size: 28,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: latestPhoto,
                                  fit: BoxFit.cover,
                                  placeholder: (context, _) =>
                                      Container(color: const Color(0xFFF8F4EF)),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: const Color(0xFFF8F4EF),
                                        child: const Center(
                                          child: Icon(
                                            Icons.photo_rounded,
                                            size: 28,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                ),
                        ),
                        Positioned(
                          bottom: 6,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: moodColor, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room['name'] ?? l10n.roomSelectionRoomFallback,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _buildMoodDots(moodDotCount, moodColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildMoodDots(int filled, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(4, (index) {
        final isActive = index < filled;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.black12,
          ),
        );
      }),
    );
  }

  int _moodDotCount(String? mood) {
    switch (mood) {
      case 'high':
        return 4;
      case 'mid':
        return 3;
      case 'low':
        return 2;
      case 'sad':
        return 1;
      default:
        return 0;
    }
  }

  Color _moodColor(String? mood) {
    switch (mood) {
      case 'high':
        return _moodHigh;
      case 'mid':
        return _moodMid;
      case 'low':
        return _moodLow;
      case 'sad':
        return _moodSad;
      default:
        return _mint;
    }
  }
}
