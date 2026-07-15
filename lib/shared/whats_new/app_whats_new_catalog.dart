import 'package:pet/l10n/app_localizations.dart';

import 'app_whats_new_entry.dart';

class AppWhatsNewCatalog {
  const AppWhatsNewCatalog._();

  static const List<AppWhatsNewEntry> entries = <AppWhatsNewEntry>[
    AppWhatsNewEntry(
      version: '2.2.5',
      titleBuilder: _version225Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[_version225Bullet1],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.2.4',
      titleBuilder: _version224Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version224Bullet1,
        _version224Bullet2,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.2.3',
      titleBuilder: _version223Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version223Bullet1,
        _version223Bullet2,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.2.2',
      titleBuilder: _version222Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version222Bullet1,
        _version222Bullet2,
        _version222Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.2.1',
      titleBuilder: _version221Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version221Bullet1,
        _version221Bullet2,
        _version221Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.2.0',
      titleBuilder: _version220Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version220Bullet1,
        _version220Bullet2,
        _version220Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.1.0',
      titleBuilder: _version210Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version210Bullet1,
        _version210Bullet2,
        _version210Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.0.2',
      titleBuilder: _version202Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[_version202Bullet1],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.0.1',
      titleBuilder: _version201Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version201Bullet1,
        _version201Bullet2,
        _version201Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '2.0.0',
      titleBuilder: _version200Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version200Bullet1,
        _version200Bullet2,
        _version200Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.4.0',
      titleBuilder: _version140Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version140Bullet1,
        _version140Bullet2,
        _version140Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.3.0',
      titleBuilder: _version130Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version130Bullet1,
        _version130Bullet2,
        _version130Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.2.0',
      titleBuilder: _version120Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version120Bullet1,
        _version120Bullet2,
        _version120Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.1.4',
      titleBuilder: _version114Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[_version114Bullet1],
      actionLabelBuilder: _continueLabel,
    ),
    AppWhatsNewEntry(
      version: '1.1.3',
      titleBuilder: _version113Title,
      bulletBuilders: <AppWhatsNewTextBuilder>[
        _version113Bullet1,
        _version113Bullet2,
        _version113Bullet3,
      ],
      actionLabelBuilder: _continueLabel,
    ),
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

  static String _version224Title(AppLocalizations l10n) =>
      l10n.whatsNew224Title;
  static String _version224Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew224Bullet1;
  static String _version224Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew224Bullet2;

  static String _version225Title(AppLocalizations l10n) =>
      l10n.whatsNew225Title;
  static String _version225Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew225Bullet1;

  static String _version223Title(AppLocalizations l10n) =>
      l10n.whatsNew223Title;
  static String _version223Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew223Bullet1;
  static String _version223Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew223Bullet2;

  static String _version222Title(AppLocalizations l10n) =>
      l10n.whatsNew222Title;
  static String _version222Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew222Bullet1;
  static String _version222Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew222Bullet2;
  static String _version222Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew222Bullet3;

  static String _version221Title(AppLocalizations l10n) =>
      l10n.whatsNew221Title;
  static String _version221Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew221Bullet1;
  static String _version221Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew221Bullet2;
  static String _version221Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew221Bullet3;

  static String _version220Title(AppLocalizations l10n) =>
      l10n.whatsNew220Title;
  static String _version220Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew220Bullet1;
  static String _version220Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew220Bullet2;
  static String _version220Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew220Bullet3;

  static String _version210Title(AppLocalizations l10n) =>
      l10n.whatsNew210Title;
  static String _version210Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew210Bullet1;
  static String _version210Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew210Bullet2;
  static String _version210Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew210Bullet3;

  static String _version201Title(AppLocalizations l10n) =>
      l10n.whatsNew201Title;
  static String _version201Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew201Bullet1;
  static String _version201Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew201Bullet2;
  static String _version201Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew201Bullet3;

  static String _version202Title(AppLocalizations l10n) =>
      l10n.whatsNew202Title;
  static String _version202Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew202Bullet1;

  static String _version200Title(AppLocalizations l10n) =>
      l10n.whatsNew200Title;
  static String _version200Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew200Bullet1;
  static String _version200Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew200Bullet2;
  static String _version200Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew200Bullet3;

  static String _version140Title(AppLocalizations l10n) =>
      l10n.whatsNew140Title;
  static String _version140Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew140Bullet1;
  static String _version140Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew140Bullet2;
  static String _version140Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew140Bullet3;

  static String _version130Title(AppLocalizations l10n) =>
      l10n.whatsNew130Title;
  static String _version130Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew130Bullet1;
  static String _version130Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew130Bullet2;
  static String _version130Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew130Bullet3;

  static String _version120Title(AppLocalizations l10n) =>
      l10n.whatsNew120Title;
  static String _version120Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew120Bullet1;
  static String _version120Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew120Bullet2;
  static String _version120Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew120Bullet3;

  static String _version114Title(AppLocalizations l10n) =>
      l10n.whatsNew114Title;
  static String _version114Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew114Bullet1;

  static String _version113Title(AppLocalizations l10n) =>
      l10n.whatsNew113Title;
  static String _version113Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew113Bullet1;
  static String _version113Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew113Bullet2;
  static String _version113Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew113Bullet3;

  static String _version112Title(AppLocalizations l10n) =>
      l10n.whatsNew112Title;
  static String _version112Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew112Bullet1;
  static String _version112Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew112Bullet2;
  static String _version112Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew112Bullet3;

  static String _version111Title(AppLocalizations l10n) =>
      l10n.whatsNew111Title;
  static String _version111Bullet1(AppLocalizations l10n) =>
      l10n.whatsNew111Bullet1;
  static String _version111Bullet2(AppLocalizations l10n) =>
      l10n.whatsNew111Bullet2;
  static String _version111Bullet3(AppLocalizations l10n) =>
      l10n.whatsNew111Bullet3;

  static String _version110Title(AppLocalizations l10n) =>
      l10n.whatsNew110Title;

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
