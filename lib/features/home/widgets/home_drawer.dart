import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/user_avatar.dart';
import '../../../shared/localization/app_locale_controller.dart';
import '../../../shared/localization/language_selector_sheet.dart';

class HomeDrawer extends ConsumerWidget {
  final String? userAvatarUrl;
  final String? userName;
  final VoidCallback onProfileTap;
  final VoidCallback onSignOut;
  final Widget? debugActions;

  const HomeDrawer({
    super.key,
    this.userAvatarUrl,
    this.userName,
    required this.onProfileTap,
    required this.onSignOut,
    this.debugActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context)!;
    final localeState = ref.watch(appLocaleProvider);

    return Drawer(
      width: 268,
      backgroundColor: const Color(0xFFFFF8ED),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD89A), Color(0xFFFFB56A)],
              ),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.28),
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      avatar: userAvatarUrl,
                      fallbackText: userId?.substring(0, 1),
                      size: 56,
                    ),
                  ),
                ),
                if (userName != null && userName!.trim().isNotEmpty) ...[
                  const Gap(12),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      userName!.trim(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3A2818),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _DrawerItem(
                          icon: Icons.account_circle_outlined,
                          title: l10n.drawerProfile,
                          onTap: onProfileTap,
                          isPrimary: true,
                        ),
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
                        if (debugActions != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.textSecondary.withValues(alpha: 0.12),
                              ),
                            ),
                            child: debugActions!,
                          ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 10),
                    child: _DrawerItem(
                      icon: Icons.logout_rounded,
                      title: l10n.commonSignOut,
                      onTap: onSignOut,
                      textColor: AppTheme.errorColor,
                      iconColor: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
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
      case AppLanguageOption.chineseSimplified:
        return l10n.languageChineseSimplified;
      case AppLanguageOption.chineseTraditional:
        return l10n.languageChineseTraditional;
      case AppLanguageOption.japanese:
        return l10n.languageJapanese;
      case AppLanguageOption.korean:
        return l10n.languageKorean;
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isPrimary = false,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: isPrimary
          ? BoxDecoration(
              color: const Color(0xFFFFE7BF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFC670)),
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.textSecondary.withValues(alpha: 0.12),
              ),
            ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFFFFC670).withValues(alpha: 0.25)
                : const Color(0xFFFFF2DE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color:
                iconColor ??
                (isPrimary ? const Color(0xFF8A4D1D) : AppTheme.textSecondary),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? const Color(0xFF2F261F),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color:
                      textColor?.withValues(alpha: 0.7) ??
                      const Color(0xFF7B6955),
                  fontSize: 12,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
