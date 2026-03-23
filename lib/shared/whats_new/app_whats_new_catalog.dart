import 'package:pet/l10n/app_localizations.dart';

import 'app_whats_new_entry.dart';

class AppWhatsNewCatalog {
  const AppWhatsNewCatalog._();

  static const List<AppWhatsNewEntry> entries = <AppWhatsNewEntry>[
    AppWhatsNewEntry(
      version: '1.0.6',
      titleBuilder: _version106Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version106Bullet1,
        _version106Bullet2,
        _version106Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.0.5',
      titleBuilder: _version105Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version105Bullet1,
        _version105Bullet2,
        _version105Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
  ];

  static AppWhatsNewEntry? entryForVersion(String version) {
    for (final entry in entries) {
      if (entry.version == version) {
        return entry;
      }
    }
    return null;
  }

  static String _version106Title(AppLocalizations l10n) =>
      l10n.whatsNew106Title;

  static String _version106Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew106Bullet1;

  static String _version106Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew106Bullet2;

  static String _version106Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew106Bullet3;

  static String _version105Title(AppLocalizations l10n) =>
      l10n.whatsNew105Title;

  static String _version105Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew105Bullet1;

  static String _version105Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew105Bullet2;

  static String _version105Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew105Bullet3;

  static String _continueLabel(AppLocalizations l10n) =>
      l10n.whatsNewContinueAction;
}
