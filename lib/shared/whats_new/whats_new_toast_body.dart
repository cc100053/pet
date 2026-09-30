import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../theme/app_theme.dart';
import 'app_whats_new_entry.dart';

/// Centered version pill plus up to three tinted tiles (icon, headline,
/// optional detail).
/// The entry title is the toast's `message`, so it is not repeated here.
class WhatsNewToastBody extends StatelessWidget {
  const WhatsNewToastBody({
    super.key,
    required this.version,
    required this.entry,
  });

  final String version;
  final AppWhatsNewEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bullets = entry.bullets(l10n).take(3).toList(growable: false);

    // Full-width tinted tiles: their edges, not the ragged text, set the
    // card's left and right lines.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _VersionPill(version: version)),
        for (var index = 0; index < bullets.length; index++) ...[
          SizedBox(height: index == 0 ? 14 : 8),
          _Tile(
            icon: entry.bulletIcon(index),
            headline: bullets[index],
            detail: entry.bulletDetail(l10n, index),
          ),
        ],
      ],
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.leaf.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          l10n.whatsNewVersionLabel(version),
          style: GoogleFonts.mPlusRounded1c(
            color: AppTheme.leafDeep,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.headline, this.detail});

  final AppWhatsNewIcon icon;
  final String headline;
  final String? detail;

  static (IconData, Color) _style(AppWhatsNewIcon icon) => switch (icon) {
    AppWhatsNewIcon.newItem => (Icons.chair_rounded, AppTheme.secondaryColor),
    AppWhatsNewIcon.newPet => (Icons.pets_rounded, AppTheme.wood),
    AppWhatsNewIcon.design => (Icons.palette_rounded, AppTheme.sakura),
    AppWhatsNewIcon.feature => (Icons.auto_awesome_rounded, AppTheme.leaf),
    AppWhatsNewIcon.social => (Icons.forum_rounded, AppTheme.sky),
    AppWhatsNewIcon.fix => (Icons.build_rounded, AppTheme.textSecondary),
  };

  @override
  Widget build(BuildContext context) {
    final (iconData, tint) = _style(icon);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              size: 22,
              color: Color.lerp(tint, AppTheme.ink, 0.35),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.mPlusRounded1c(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: GoogleFonts.mPlusRounded1c(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
