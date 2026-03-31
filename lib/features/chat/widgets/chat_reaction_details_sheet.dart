import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/user_avatar.dart';

enum ChatReactionDetailsSheetAction { reply, copy, report, block }

typedef ChatReactionSheetReactionHandler =
    Future<ChatReactionDetailsSheetUpdate?> Function(String emoji);

class ChatReactionDetailsSheetUpdate {
  const ChatReactionDetailsSheetUpdate({
    required this.entries,
    required this.selectedReactionEmoji,
  });

  final List<ChatReactionDetailsSheetEntry> entries;
  final String? selectedReactionEmoji;
}

class ChatReactionDetailsSheetEntry {
  const ChatReactionDetailsSheetEntry({
    required this.userId,
    required this.displayName,
    required this.emoji,
    required this.createdAt,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final String userId;
  final String displayName;
  final String emoji;
  final DateTime createdAt;
  final String? avatarUrl;
  final bool isCurrentUser;
}

class ChatReactionDetailsSheet extends StatefulWidget {
  const ChatReactionDetailsSheet({
    super.key,
    required this.reactionOptions,
    required this.entries,
    required this.selectedReactionEmoji,
    required this.copyEnabled,
    required this.isMine,
    required this.isBlocked,
    this.initialFilterEmoji,
    this.onReactionSelected,
    this.showMessageActions = true,
  });

  final List<String> reactionOptions;
  final List<ChatReactionDetailsSheetEntry> entries;
  final String? selectedReactionEmoji;
  final bool copyEnabled;
  final bool isMine;
  final bool isBlocked;
  final String? initialFilterEmoji;
  final ChatReactionSheetReactionHandler? onReactionSelected;
  final bool showMessageActions;

  @override
  State<ChatReactionDetailsSheet> createState() =>
      _ChatReactionDetailsSheetState();
}

class _ChatReactionDetailsSheetState extends State<ChatReactionDetailsSheet> {
  late List<ChatReactionDetailsSheetEntry> _entries;
  late String? _selectedReactionEmoji;
  late String? _selectedFilterEmoji;
  bool _isUpdatingReaction = false;
  String? _pendingEmoji;

  @override
  void initState() {
    super.initState();
    _entries = List<ChatReactionDetailsSheetEntry>.from(widget.entries);
    _selectedReactionEmoji = widget.selectedReactionEmoji;
    _selectedFilterEmoji = _resolveInitialFilterEmoji();
  }

  String? _resolveInitialFilterEmoji() {
    final preferred = widget.initialFilterEmoji?.trim();
    if (preferred != null && preferred.isNotEmpty) {
      return preferred;
    }
    final selected = widget.selectedReactionEmoji?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }
    if (_entries.isNotEmpty) {
      return _entries.first.emoji;
    }
    return null;
  }

  String? _resolveNextFilterEmoji(
    String tappedEmoji,
    List<ChatReactionDetailsSheetEntry> entries,
    String? selectedReactionEmoji,
  ) {
    if (entries.any((entry) => entry.emoji == tappedEmoji)) {
      return tappedEmoji;
    }
    final selected = selectedReactionEmoji?.trim();
    if (selected != null &&
        selected.isNotEmpty &&
        entries.any((entry) => entry.emoji == selected)) {
      return selected;
    }
    if (entries.isNotEmpty) {
      return entries.first.emoji;
    }
    return null;
  }

  Map<String, int> get _reactionCounts {
    final counts = <String, int>{};
    for (final entry in _entries) {
      counts.update(entry.emoji, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<ChatReactionDetailsSheetEntry> get _filteredEntries {
    final selected = _selectedFilterEmoji;
    if (selected == null || selected.isEmpty) {
      return _entries;
    }
    return _entries.where((entry) => entry.emoji == selected).toList();
  }

  Future<void> _handleReactionTap(String emoji) async {
    final onReactionSelected = widget.onReactionSelected;
    if (_isUpdatingReaction || onReactionSelected == null) {
      return;
    }

    setState(() {
      _isUpdatingReaction = true;
      _pendingEmoji = emoji;
    });

    try {
      final update = await onReactionSelected(emoji);
      if (!mounted) {
        return;
      }
      if (update != null) {
        setState(() {
          _entries = List<ChatReactionDetailsSheetEntry>.from(update.entries);
          _selectedReactionEmoji = update.selectedReactionEmoji;
          _selectedFilterEmoji = _resolveNextFilterEmoji(
            emoji,
            _entries,
            _selectedReactionEmoji,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingReaction = false;
          _pendingEmoji = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final counts = _reactionCounts;
    final filteredEntries = _filteredEntries;

    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.78),
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
                Text(
                  l10n.chatReactionCount(_entries.length),
                  key: const ValueKey('chatReactionSheetHeader'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ReactionFilterChip(
                        key: const ValueKey('chatReactionSheetFilterAll'),
                        selected: _selectedFilterEmoji == null,
                        enabled: !_isUpdatingReaction,
                        onTap: () =>
                            setState(() => _selectedFilterEmoji = null),
                        child: const Icon(
                          Icons.emoji_emotions_outlined,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...widget.reactionOptions.map((emoji) {
                        final count = counts[emoji] ?? 0;
                        final selected = _selectedFilterEmoji == emoji;
                        final isPending = _pendingEmoji == emoji;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _ReactionFilterChip(
                            key: ValueKey<String>(
                              'chatReactionSheetFilter_$emoji',
                            ),
                            selected: selected,
                            enabled: !_isUpdatingReaction,
                            onTap: () => _handleReactionTap(emoji),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                if (isPending) ...[
                                  const SizedBox(width: 6),
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ] else if (count > 0) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: selected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: filteredEntries.isEmpty
                      ? const SizedBox(height: 48)
                      : ListView.separated(
                          key: const ValueKey('chatReactionSheetList'),
                          shrinkWrap: true,
                          itemCount: filteredEntries.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, thickness: 0.5),
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return ListTile(
                              key: ValueKey<String>(
                                'chatReactionSheetRow_${entry.userId}_${entry.emoji}',
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 2,
                              ),
                              leading: UserAvatar(
                                avatar: entry.avatarUrl,
                                fallbackText: entry.displayName,
                                size: 38,
                              ),
                              title: Text(
                                entry.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: entry.isCurrentUser
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              trailing: Text(
                                entry.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            );
                          },
                        ),
                ),
                if (widget.showMessageActions) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  ListTile(
                    key: const ValueKey('chatReactionSheetReplyAction'),
                    leading: const Icon(Icons.reply_rounded),
                    title: Text(l10n.chatReplyAction),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(ChatReactionDetailsSheetAction.reply),
                  ),
                  ListTile(
                    key: const ValueKey('chatReactionSheetCopyAction'),
                    leading: const Icon(Icons.content_copy_rounded),
                    title: Text(l10n.chatCopyAction),
                    enabled: widget.copyEnabled,
                    onTap: widget.copyEnabled
                        ? () => Navigator.of(
                            context,
                          ).pop(ChatReactionDetailsSheetAction.copy)
                        : null,
                  ),
                  if (!widget.isMine)
                    ListTile(
                      key: const ValueKey('chatReactionSheetReportAction'),
                      leading: const Icon(Icons.report_gmailerrorred_outlined),
                      title: Text(l10n.chatReportMessageTitle),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(ChatReactionDetailsSheetAction.report),
                    ),
                  if (!widget.isMine)
                    ListTile(
                      key: const ValueKey('chatReactionSheetBlockAction'),
                      leading: const Icon(Icons.block),
                      title: Text(
                        widget.isBlocked
                            ? l10n.chatUserAlreadyBlocked
                            : l10n.chatBlockUser,
                      ),
                      enabled: !widget.isBlocked,
                      onTap: widget.isBlocked
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(ChatReactionDetailsSheetAction.block),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionFilterChip extends StatelessWidget {
  const _ReactionFilterChip({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppTheme.primaryColor.withValues(alpha: 0.36)
        : Colors.black.withValues(alpha: 0.06);
    final backgroundColor = selected
        ? AppTheme.primaryColor.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surfaceContainerLow;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
