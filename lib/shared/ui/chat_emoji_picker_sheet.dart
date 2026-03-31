import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

import '../../features/chat/chat_reaction_options.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

Future<String?> showChatEmojiPickerSheet(
  BuildContext context, {
  String? selectedEmoji,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ChatEmojiPickerSheet(selectedEmoji: selectedEmoji),
  );
}

class _ChatEmojiPickerSheet extends StatelessWidget {
  const _ChatEmojiPickerSheet({this.selectedEmoji});

  final String? selectedEmoji;

  Locale _pickerLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return const Locale('ja');
      case 'zh':
        return const Locale('zh');
      default:
        return const Locale('en');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final pickerLocale = _pickerLocale(Localizations.localeOf(context));

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.82),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.chatAllEmojiAction,
                          key: const ValueKey('chatEmojiPickerTitle'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('chatEmojiPickerCloseButton'),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  if (selectedEmoji != null && selectedEmoji!.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        key: const ValueKey('chatEmojiPickerSelectedChip'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                        child: Text(
                          selectedEmoji!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  if (selectedEmoji != null && selectedEmoji!.trim().isNotEmpty)
                    const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kChatExpandedReactionSuggestions
                          .map((emoji) {
                            final isSelected = selectedEmoji == emoji;
                            return InkWell(
                              key: ValueKey('chatEmojiPickerSuggestion_$emoji'),
                              onTap: () => Navigator.of(context).pop(emoji),
                              borderRadius: BorderRadius.circular(999),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(
                                          alpha: 0.10,
                                        )
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withValues(
                                            alpha: 0.28,
                                          )
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: EmojiPicker(
                        onEmojiSelected: (_, emoji) =>
                            Navigator.of(context).pop(emoji.emoji),
                        config: Config(
                          height: null,
                          locale: pickerLocale,
                          emojiViewConfig: EmojiViewConfig(
                            columns: 8,
                            emojiSizeMax:
                                28 *
                                (foundation.defaultTargetPlatform ==
                                        TargetPlatform.iOS
                                    ? 1.20
                                    : 1.0),
                            backgroundColor: theme.colorScheme.surface,
                            recentsLimit: 28,
                            loadingIndicator: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            initCategory: Category.SMILEYS,
                            backgroundColor: theme.colorScheme.surface,
                            indicatorColor: AppTheme.primaryColor,
                            iconColor: AppTheme.textSecondary,
                            iconColorSelected: AppTheme.primaryColor,
                            dividerColor: theme.dividerColor.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            enabled: false,
                          ),
                          viewOrderConfig: const ViewOrderConfig(
                            top: EmojiPickerItem.emojiView,
                            middle: EmojiPickerItem.categoryBar,
                            bottom: EmojiPickerItem.searchBar,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
