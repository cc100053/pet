import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet/l10n/app_localizations.dart';

import 'app_locale_controller.dart';

class LanguageSelectorSheet extends ConsumerWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeState = ref.watch(appLocaleProvider);
    final controller = ref.read(appLocaleProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: RadioGroup<AppLanguageOption>(
          groupValue: localeState.option,
          onChanged: (value) async {
            if (value == null) {
              return;
            }
            await controller.setOption(value);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.languageTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _LanguageOptionTile(
                title: l10n.languageSystem,
                subtitle: l10n.languageSystemSubtitle,
                value: AppLanguageOption.system,
              ),
              _LanguageOptionTile(
                title: l10n.languageEnglish,
                value: AppLanguageOption.english,
              ),
              _LanguageOptionTile(
                title: l10n.languageJapanese,
                value: AppLanguageOption.japanese,
              ),
              _LanguageOptionTile(
                title: l10n.languageKorean,
                value: AppLanguageOption.korean,
              ),
              _LanguageOptionTile(
                title: l10n.languageChineseSimplified,
                value: AppLanguageOption.chineseSimplified,
              ),
              _LanguageOptionTile(
                title: l10n.languageChineseTraditional,
                value: AppLanguageOption.chineseTraditional,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final AppLanguageOption value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppLanguageOption>(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
    );
  }
}
