import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class ChatMessageActionSheet extends StatelessWidget {
  const ChatMessageActionSheet({
    super.key,
    required this.reactionOptions,
    required this.selectedReaction,
    required this.copyEnabled,
    required this.isMine,
    required this.isBlocked,
    required this.onReactionSelected,
    required this.onReply,
    required this.onCopy,
    required this.onReport,
    required this.onBlock,
    required this.onMoreReactions,
  });

  final List<String> reactionOptions;
  final String? selectedReaction;
  final bool copyEnabled;
  final bool isMine;
  final bool isBlocked;
  final ValueChanged<String> onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final VoidCallback onMoreReactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  reactionOptions.map((emoji) {
                    final isSelected = selectedReaction == emoji;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => onReactionSelected(emoji),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.14)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(
                                      alpha: 0.36,
                                    )
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    );
                  }).toList()..add(
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey(
                          'chatMessageActionSheetMoreReactions',
                        ),
                        borderRadius: BorderRadius.circular(999),
                        onTap: onMoreReactions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Text(
                            l10n.chatMoreReactionsAction,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: Text(l10n.chatReplyAction),
            onTap: onReply,
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_rounded),
            title: Text(l10n.chatCopyAction),
            enabled: copyEnabled,
            onTap: copyEnabled ? onCopy : null,
          ),
          if (!isMine)
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_outlined),
              title: Text(l10n.chatReportMessageTitle),
              onTap: onReport,
            ),
          if (!isMine)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(
                isBlocked ? l10n.chatUserAlreadyBlocked : l10n.chatBlockUser,
              ),
              enabled: !isBlocked,
              onTap: isBlocked ? null : onBlock,
            ),
        ],
      ),
    );
  }
}
