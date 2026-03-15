import 'package:pet/l10n/app_localizations.dart';

typedef AppWhatsNewTextBuilder = String Function(AppLocalizations l10n);

class AppWhatsNewEntry {
  const AppWhatsNewEntry({
    required this.version,
    required this.titleBuilder,
    required this.bulletBuilders,
    this.actionLabelBuilder,
  });

  final String version;
  final AppWhatsNewTextBuilder titleBuilder;
  final List<AppWhatsNewTextBuilder> bulletBuilders;
  final AppWhatsNewTextBuilder? actionLabelBuilder;

  String title(AppLocalizations l10n) => titleBuilder(l10n);

  List<String> bullets(AppLocalizations l10n) =>
      bulletBuilders.map((builder) => builder(l10n)).toList(growable: false);

  String? actionLabel(AppLocalizations l10n) => actionLabelBuilder?.call(l10n);
}
