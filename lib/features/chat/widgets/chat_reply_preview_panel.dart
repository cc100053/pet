import 'package:flutter/material.dart';

class ChatReplyPreviewPanel extends StatelessWidget {
  const ChatReplyPreviewPanel({
    super.key,
    required this.senderName,
    required this.previewText,
    required this.accentColor,
    required this.senderColor,
    required this.previewTextColor,
    required this.backgroundColor,
    this.iconColor,
    this.isImage = false,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(10, 8, 10, 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.maxLines = 2,
    this.showJumpIcon = false,
    this.compact = false,
  });

  final String senderName;
  final String previewText;
  final Color accentColor;
  final Color senderColor;
  final Color previewTextColor;
  final Color backgroundColor;
  final Color? iconColor;
  final bool isImage;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final int maxLines;
  final bool showJumpIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 3,
            height: compact ? 28 : 32,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: senderColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12 : 12.5,
                    height: 1.2,
                    color: previewTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (isImage || showJumpIcon) ...[
            const SizedBox(width: 8),
            Icon(
              showJumpIcon ? Icons.arrow_upward_rounded : Icons.image_rounded,
              size: compact ? 15 : 16,
              color: iconColor ?? previewTextColor,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return panel;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: borderRadius, child: panel),
    );
  }
}
