import 'package:pet/l10n/app_localizations.dart';

import 'app_whats_new_entry.dart';

class AppWhatsNewCatalog {
  const AppWhatsNewCatalog._();

  static const List<AppWhatsNewEntry> entries = <AppWhatsNewEntry>[
    AppWhatsNewEntry(
      version: '1.1.2',
      titleBuilder: _version112Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version112Bullet1,
        _version112Bullet2,
        _version112Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.1.1',
      titleBuilder: _version111Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version111Bullet1,
        _version111Bullet2,
        _version111Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.1.0',
      titleBuilder: _version110Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version110Bullet1,
        _version110Bullet2,
        _version110Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
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

  static String _version112Title(AppLocalizations l10n) => l10n.whatsNew112Title;
  static String _version112Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew112Bullet1;
  static String _version112Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew112Bullet2;
  static String _version112Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew112Bullet3;

  static String _version111Title(AppLocalizations l10n) => l10n.whatsNew111Title;
  static String _version111Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew111Bullet1;
  static String _version111Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew111Bullet2;
  static String _version111Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew111Bullet3;

  static String _version110Title(AppLocalizations l10n) => l10n.whatsNew110Title;

  static String _version110Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew110Bullet1;

  static String _version110Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew110Bullet2;

  static String _version110Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew110Bullet3;

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
