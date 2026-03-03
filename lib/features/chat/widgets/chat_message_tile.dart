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
    this.useLightForeground = false,
    this.senderName,
    this.onLongPress,
    this.onImageTap,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isOptimistic;
  final bool useLightForeground;
  final String? senderName;
  final VoidCallback? onLongPress;
  final VoidCallback? onImageTap;

  // Color palette for different users (Telegram-style)
  static const List<Color> _userColors = [
    Color(0xFFE17076), // Coral red
    Color(0xFF7BC862), // Green
    Color(0xFF65AADD), // Blue
    Color(0xFFEE7AE9), // Pink
    Color(0xFFFAA74A), // Orange
    Color(0xFF6EC9CB), // Teal
    Color(0xFFE47ACD), // Magenta
    Color(0xFF8E85EE), // Purple
  ];

  /// Returns a consistent color for a given user ID
  static Color colorForUserId(String? userId) {
    if (userId == null || userId.isEmpty) return _userColors[0];
    return _userColors[userId.hashCode.abs() % _userColors.length];
  }

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
            color: useLightForeground
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: useLightForeground
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    // Build the message content (bubble)
    final bubbleContent = message.isImageFeed
        ? _FeedMessageCard(
            message: message,
            isMe: isMe,
            isOptimistic: isOptimistic,
            onImageTap: onImageTap,
            senderName: senderName,
          )
        : _TextMessageBubble(
            message: message,
            isMe: isMe,
            senderName: senderName,
          );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Opacity(opacity: isOptimistic ? 0.7 : 1.0, child: bubbleContent),
      ),
    );
  }

  String _localizedSystemMessage(AppLocalizations l10n) {
    final raw = message.body?.trim();
    if (raw == null || raw.isEmpty) {
      return l10n.chatSystemUpdate;
    }

    final hungerAlert = _parseHungerAlert(raw, l10n);
    if (hungerAlert != null) {
      return hungerAlert.level == 10
          ? l10n.chatPetHungryUrgentMessage(hungerAlert.petName)
          : l10n.chatPetHungryReminderMessage(hungerAlert.petName);
    }

    final lower = raw.toLowerCase();
    final phrases = <String>['cleaned the poop', '清理了便便', 'うんちを掃除した', '배변을 치웠'];
    final matchedPhrase = phrases.firstWhere(
      (phrase) => lower.contains(phrase),
      orElse: () => '',
    );
    if (matchedPhrase.isNotEmpty) {
      final phraseIndex = lower.indexOf(matchedPhrase);
      final nameRaw = phraseIndex > 0 ? raw.substring(0, phraseIndex) : '';
      final name = nameRaw.trim().isEmpty
          ? l10n.chatSystemUpdate
          : nameRaw.trim();
      final amountFromBody = RegExp(r'\\+(\\d+)').firstMatch(raw)?.group(1);
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
        return l10n.chatPetRenamedMessage(name, l10n.petNameUnnamed, petName);
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
        return l10n.chatPetRenamedMessage(name, l10n.petNameUnnamed, petName);
      }
    }

    return raw.replaceAll('Coins', l10n.chatCandyLabel);
  }

  _HungerAlertInfo? _parseHungerAlert(String raw, AppLocalizations l10n) {
    final level = raw.startsWith('hunger_alert_50::')
        ? 50
        : (raw.startsWith('hunger_alert_30::')
              ? 30
              : (raw.startsWith('hunger_alert_10::') ? 10 : null));
    if (level == null) {
      return null;
    }
    final separatorIndex = raw.indexOf('::');
    final petName = separatorIndex >= 0
        ? raw.substring(separatorIndex + 2).trim()
        : '';
    return _HungerAlertInfo(
      level: level,
      petName: petName.isEmpty ? l10n.petNameUnknown : petName,
    );
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
    final oldLower = normalizedOld.toLowerCase();
    final isUnnamed =
        normalizedOld.isEmpty ||
        oldLower == 'unnamed' ||
        normalizedOld == '이름 없음';
    final oldName = isUnnamed ? l10n.petNameUnnamed : normalizedOld;

    return l10n.chatPetRenamedMessage(userName, oldName, newName);
  }
}

class _HungerAlertInfo {
  const _HungerAlertInfo({required this.level, required this.petName});

  final int level;
  final String petName;
}

class _TextMessageBubble extends StatelessWidget {
  const _TextMessageBubble({
    required this.message,
    required this.isMe,
    this.senderName,
  });

  final ChatMessage message;
  final bool isMe;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMe ? AppTheme.chatBubbleMe : AppTheme.chatBubbleOther;

    final bubbleRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    final decoration = BoxDecoration(
      color: bubbleColor,
      borderRadius: bubbleRadius,
      border: null,
    );

    final textColor = AppTheme.textPrimary;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: decoration,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe && senderName != null && senderName!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ChatMessageTile.colorForUserId(message.senderId),
                  ),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 42),
                    child: Text(
                      message.body ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      _formatMessageTime(message.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Add bubble tail
    final tail = CustomPaint(
      size: const Size(8, 12),
      painter: _BubbleTailPainter(
        color: bubbleColor,
        isMe: isMe,
        hasBorder: false,
      ),
    );

    if (isMe) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          bubble,
          Transform.translate(offset: const Offset(-3, 0), child: tail),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Transform.translate(offset: const Offset(3, 0), child: tail),
          bubble,
        ],
      );
    }
  }
}

String _formatMessageTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Custom painter for Telegram-style bubble tail
class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.color,
    required this.isMe,
    this.hasBorder = false,
  });

  final Color color;
  final bool isMe;
  final bool hasBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isMe) {
      // Tail on right side, pointing right-down
      path.moveTo(0, 0);
      path.quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.3,
        size.width,
        size.height,
      );
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Tail on left side, pointing left-down
      path.moveTo(size.width, 0);
      path.quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.3,
        0,
        size.height,
      );
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);

    // Draw border if needed (for other's messages)
    if (hasBorder) {
      final borderPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isMe != isMe ||
        oldDelegate.hasBorder != hasBorder;
  }
}

class _FeedMessageCard extends StatelessWidget {
  const _FeedMessageCard({
    required this.message,
    required this.isMe,
    required this.isOptimistic,
    required this.onImageTap,
    this.senderName,
  });

  final ChatMessage message;
  final bool isMe;
  final bool isOptimistic;
  final VoidCallback? onImageTap;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    final hasCaption = message.caption != null && message.caption!.isNotEmpty;
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
          // Header (sender name on left, coins on right)
          if ((!isMe && senderName != null && senderName!.isNotEmpty) ||
              message.coinsAwarded > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  if (!isMe && senderName != null && senderName!.isNotEmpty)
                    Expanded(
                      child: Text(
                        senderName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ChatMessageTile.colorForUserId(
                            message.senderId,
                          ),
                        ),
                      ),
                    )
                  else
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
                            size: 15,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${message.coinsAwarded}',
                            style: const TextStyle(
                              color: Colors.brown,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onImageTap,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageContent(),
                      if (!hasCaption)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatMessageTime(message.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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

          const SizedBox(height: 8),

          // Caption or Label
          if (hasCaption)
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 42),
                    child: Text(
                      message.caption!,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Text(
                      _formatMessageTime(message.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Labels/Tags (temporarily disabled)
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    const letterboxColor = Color(0xFFF8F4EF);
    if (message.localImagePath != null) {
      final file = File(message.localImagePath!);
      if (file.existsSync()) {
        return DecoratedBox(
          decoration: const BoxDecoration(color: letterboxColor),
          child: Image.file(file, fit: BoxFit.cover),
        );
      }
    }
    if (message.imageUrl != null) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: letterboxColor),
        child: CachedNetworkImageView(
          imageUrl: message.imageUrl!,
          fit: BoxFit.cover,
          portraitFriendlyCrop: true,
          placeholder: Container(color: Colors.grey[200]),
          errorWidget: const Icon(Icons.broken_image),
        ),
      );
    }
    return Container(color: Colors.grey[300]);
  }
}
