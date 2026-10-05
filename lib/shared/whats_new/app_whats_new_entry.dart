import 'package:pet/l10n/app_localizations.dart';

typedef AppWhatsNewTextBuilder = String Function(AppLocalizations l10n);

/// Fixed icon set for What's New rows; the toast maps each to an icon and tint.
enum AppWhatsNewIcon {
  newItem,
  newPet,
  newRoom,
  petTicket,
  design,
  feature,
  social,
  fix,
}

class AppWhatsNewEntry {
  const AppWhatsNewEntry({
    required this.version,
    required this.titleBuilder,
    required this.bulletBuilders,
    this.bulletIcons = const <AppWhatsNewIcon>[],
    this.bulletDetailBuilders = const <AppWhatsNewTextBuilder?>[],
    this.actionLabelBuilder,
    this.heroPetId,
  });

  final String version;
  final AppWhatsNewTextBuilder titleBuilder;

  /// Short row headlines.
  final List<AppWhatsNewTextBuilder> bulletBuilders;

  /// Per-row icon, parallel to [bulletBuilders]; missing rows use
  /// [AppWhatsNewIcon.feature].
  final List<AppWhatsNewIcon> bulletIcons;

  /// Optional one-line detail per row, parallel to [bulletBuilders].
  final List<AppWhatsNewTextBuilder?> bulletDetailBuilders;
  final AppWhatsNewTextBuilder? actionLabelBuilder;

  /// Pet shown animated above the rows, for releases that introduce a pet.
  final String? heroPetId;

  String title(AppLocalizations l10n) => titleBuilder(l10n);

  List<String> bullets(AppLocalizations l10n) =>
      bulletBuilders.map((builder) => builder(l10n)).toList(growable: false);

  AppWhatsNewIcon bulletIcon(int index) =>
      index < bulletIcons.length ? bulletIcons[index] : AppWhatsNewIcon.feature;

  String? bulletDetail(AppLocalizations l10n, int index) {
    if (index >= bulletDetailBuilders.length) {
      return null;
    }
    final detail = bulletDetailBuilders[index]?.call(l10n);
    return detail == null || detail.isEmpty ? null : detail;
  }

  String? actionLabel(AppLocalizations l10n) => actionLabelBuilder?.call(l10n);
}
