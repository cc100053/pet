import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/localization/app_locale_controller.dart';
import '../../../shared/localization/language_selector_sheet.dart';

class HomeDrawer extends ConsumerWidget {
  final List<Map<String, dynamic>> rooms;
  final String? currentRoomId;
  final VoidCallback onNavigateToRoomSelection;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final Function(String roomId) onCalendarTap;
  final VoidCallback onStoreTap;
  final VoidCallback onInventoryTap;
  final VoidCallback onSignOut;
  final Widget? debugActions;

  const HomeDrawer({
    super.key,
    required this.rooms,
    required this.currentRoomId,
    required this.onNavigateToRoomSelection,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onCalendarTap,
    required this.onStoreTap,
    required this.onInventoryTap,
    required this.onSignOut,
    this.debugActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context)!;
    final localeState = ref.watch(appLocaleProvider);

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Text(
                      userId?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Text(
                  l10n.drawerMyRooms,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.drawerFreePlan.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: [
                // Quick Room Actions
                _DrawerItem(
                  icon: Icons.list_alt_rounded,
                  title: l10n.roomSelectionTitle,
                  subtitle: l10n.roomSelectionSubtitle,
                  onTap: onNavigateToRoomSelection,
                  isHighlight: true,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),

                _DrawerHeader(title: 'ACTIONS'),

                _DrawerItem(
                  icon: Icons.add_circle_outline,
                  title: l10n.drawerCreateRoom,
                  onTap: onCreateRoom,
                ),
                _DrawerItem(
                  icon: Icons.meeting_room_outlined,
                  title: l10n.drawerJoinWithCode,
                  onTap: onJoinRoom,
                ),

                const Gap(24),
                _DrawerHeader(title: 'UTILITIES'),

                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  title: l10n.calendarTitle,
                  onTap: () {
                    if (currentRoomId != null) {
                      onCalendarTap(currentRoomId!);
                    }
                  },
                ),
                _DrawerItem(
                  icon: Icons.storefront_outlined,
                  title: l10n.storeTitle,
                  onTap: onStoreTap,
                ),
                _DrawerItem(
                  icon: Icons.chair_alt_outlined,
                  title: l10n.furnitureInventoryTitle,
                  subtitle: l10n.furnitureInventorySubtitle,
                  onTap: onInventoryTap,
                ),

                const Gap(24),
                _DrawerHeader(title: 'PREFERENCES'),

                _DrawerItem(
                  icon: Icons.language_outlined,
                  title: l10n.languageTitle,
                  subtitle: _languageOptionLabel(localeState.option, l10n),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      builder: (_) => const LanguageSelectorSheet(),
                    );
                  },
                ),

                if (debugActions != null) ...[
                  const Gap(24),
                  _DrawerHeader(title: 'DEBUG'),
                  debugActions!,
                ],

                _DrawerItem(
                  icon: Icons.logout_rounded,
                  title:
                      'Sign Out', // Needs localization if available, or keep hardcoded for now
                  onTap: onSignOut,
                  textColor: AppTheme.errorColor,
                  iconColor: AppTheme.errorColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _languageOptionLabel(AppLanguageOption option, AppLocalizations l10n) {
    switch (option) {
      case AppLanguageOption.system:
        return l10n.languageSystem;
      case AppLanguageOption.english:
        return l10n.languageEnglish;
      case AppLanguageOption.chineseTraditional:
        return l10n.languageChineseTraditional;
      case AppLanguageOption.japanese:
        return l10n.languageJapanese;
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  final String title;
  const _DrawerHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isHighlight;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isHighlight = false,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: isHighlight
          ? BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            )
          : null,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlight
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                iconColor ??
                (isHighlight ? AppTheme.primaryColor : AppTheme.textSecondary),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? AppTheme.textPrimary,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color:
                      textColor?.withValues(alpha: 0.7) ??
                      AppTheme.textSecondary,
                  fontSize: 12,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
