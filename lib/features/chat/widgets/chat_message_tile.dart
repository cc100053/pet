import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/cached_network_image_view.dart';
import '../chat_message.dart';

class ChatMessageTile extends StatelessWidget {
  const ChatMessageTile({
    super.key,
    required this.message,
    required this.isMe,
    required this.isOptimistic,
    this.onLongPress,
    this.onImageTap,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isOptimistic;
  final VoidCallback? onLongPress;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      final l10n = AppLocalizations.of(context)!;
      final text = _localizedSystemMessage(l10n);
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ),
      );
    }

    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final content = message.isImageFeed
        ? _FeedMessageCard(
            message: message,
            isMe: isMe,
            isOptimistic: isOptimistic,
            onImageTap: onImageTap,
          )
        : _TextMessageBubble(message: message, isMe: isMe);

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Opacity(opacity: isOptimistic ? 0.7 : 1.0, child: content),
      ),
    );
  }

  String _localizedSystemMessage(AppLocalizations l10n) {
    final raw = message.body?.trim();
    if (raw == null || raw.isEmpty) {
      return l10n.chatSystemUpdate;
    }

    final lower = raw.toLowerCase();
    final phrases = <String>['cleaned the poop', '清理了便便', 'うんちを掃除した'];
    final matchedPhrase = phrases.firstWhere(
      (phrase) => lower.contains(phrase),
      orElse: () => '',
    );
    if (matchedPhrase.isNotEmpty) {
      final phraseIndex = lower.indexOf(matchedPhrase);
      final nameRaw = phraseIndex > 0 ? raw.substring(0, phraseIndex) : '';
      final name = nameRaw.trim().isEmpty ? l10n.chatSystemUpdate : nameRaw.trim();
      final amountFromBody = RegExp(r'\\+(\\d+)')
          .firstMatch(raw)
          ?.group(1);
      final amount = message.coinsAwarded > 0
          ? message.coinsAwarded.toString()
          : (amountFromBody ?? '0');
      return l10n.chatCleanPoopMessage(name, amount);
    }

    final renamedFromMessage = _parseRenameFromMessage(raw, l10n);
    if (renamedFromMessage != null) {
      return renamedFromMessage;
    }

    final renameMatch = RegExp(
      r'^(.+?)\\s*renamed the pet to\\s*(.+?)\\s*\\.?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (renameMatch != null) {
      final name = (renameMatch.group(1) ?? '').trim().isEmpty
          ? l10n.chatSystemUpdate
          : renameMatch.group(1)!.trim();
      final petName = (renameMatch.group(2) ?? '').trim();
      if (petName.isNotEmpty) {
        return l10n.chatPetRenamedMessage(
          name,
          l10n.petNameUnnamed,
          petName,
        );
      }
    }

    final renameLocalizedMatch = RegExp(
      r'^(.+?)\\s*(?:renamed the pet to|將寵物名字改為|改了寵物名字為|ペットの名前を)(.+?)\\s*\\.?$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (renameLocalizedMatch != null) {
      final name = (renameLocalizedMatch.group(1) ?? '').trim().isEmpty
          ? l10n.chatSystemUpdate
          : renameLocalizedMatch.group(1)!.trim();
      final petName = (renameLocalizedMatch.group(2) ?? '').trim();
      if (petName.isNotEmpty) {
        return l10n.chatPetRenamedMessage(
          name,
          l10n.petNameUnnamed,
          petName,
        );
      }
    }

    return raw.replaceAll('Coins', l10n.chatCandyLabel);
  }

  String? _parseRenameFromMessage(String raw, AppLocalizations l10n) {
    final lower = raw.toLowerCase();
    const phrase = 'renamed the pet from';
    final phraseIndex = lower.indexOf(phrase);
    if (phraseIndex == -1) {
      return null;
    }

    final userPart = raw.substring(0, phraseIndex).trim();
    final userName = userPart.isEmpty ? l10n.chatSystemUpdate : userPart;
    final rest = raw.substring(phraseIndex + phrase.length).trim();
    if (rest.isEmpty) {
      return null;
    }

    final lowerRest = rest.toLowerCase();
    final toIndex = lowerRest.lastIndexOf(' to ');
    if (toIndex == -1) {
      return null;
    }

    final oldNameRaw = rest.substring(0, toIndex).trim();
    var newName = rest.substring(toIndex + 4).trim();
    newName = newName.replaceAll(RegExp(r'[.]$'), '').trim();
    if (newName.isEmpty) {
      return null;
    }

    final normalizedOld = oldNameRaw.trim();
    final isUnnamed = normalizedOld.isEmpty ||
        normalizedOld.toLowerCase() == 'unnamed';
    final oldName = isUnnamed ? l10n.petNameUnnamed : normalizedOld;

    return l10n.chatPetRenamedMessage(userName, oldName, newName);
  }
}

class _TextMessageBubble extends StatelessWidget {
  const _TextMessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final decoration = isMe
        ? BoxDecoration(
            color: AppTheme.chatBubbleMe,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(2),
            ),
          )
        : BoxDecoration(
            color: AppTheme.chatBubbleOther,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          );

    final textColor = AppTheme.textPrimary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.chatPartnerLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Text(
            message.body ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _formatTime(message.createdAt),
              style: TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _FeedMessageCard extends StatelessWidget {
  const _FeedMessageCard({
    required this.message,
    required this.isMe,
    required this.isOptimistic,
    required this.onImageTap,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isOptimistic;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final decoration = isMe
        ? BoxDecoration(
            color: AppTheme.chatBubbleMe,
            borderRadius: BorderRadius.circular(16),
          )
        : BoxDecoration(
            color: AppTheme.chatBubbleOther,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          );

    return Container(
      width: 260,
      padding: const EdgeInsets.all(10),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Partner Name + Coins)
          Row(
            children: [
              if (!isMe) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.chatPartnerLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (message.coinsAwarded > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${message.coinsAwarded}',
                        style: const TextStyle(
                          color: Colors.brown,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onImageTap,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageContent(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Caption or Label
          if (message.caption != null && message.caption!.isNotEmpty)
            Text(
              message.caption!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),

          // Labels/Tags (temporarily disabled)
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (message.localImagePath != null) {
      final file = File(message.localImagePath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    if (message.imageUrl != null) {
      return CachedNetworkImageView(
        imageUrl: message.imageUrl!,
        fit: BoxFit.cover,
        placeholder: Container(color: Colors.grey[200]),
        errorWidget: const Icon(Icons.broken_image),
      );
    }
    return Container(color: Colors.grey[300]);
  }

}
