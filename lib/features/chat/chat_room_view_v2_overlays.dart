part of 'chat_room_view_v2.dart';

class _ChatHistoryLoadingOverlay extends StatelessWidget {
  const _ChatHistoryLoadingOverlay({
    super.key,
    required this.label,
    required this.isDarkBackground,
  });

  final String label;
  final bool isDarkBackground;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkBackground
        ? Colors.black.withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.94);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;
    final spinnerColor = isDarkBackground
        ? Colors.white
        : AppTheme.primaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2.1,
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JumpToLatestPill extends StatelessWidget {
  const _JumpToLatestPill({
    super.key,
    required this.label,
    required this.pendingCount,
    required this.isDarkBackground,
    required this.onTap,
  });

  final String label;
  final int pendingCount;
  final bool isDarkBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDarkBackground
        ? const Color(0xFF222B35).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);
    final borderColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final iconColor = isDarkBackground
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.textSecondary;
    final textColor = isDarkBackground ? Colors.white : AppTheme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: TextFieldTapRegion(
        child: InkWell(
          key: const ValueKey('chatJumpToLatestButton'),
          onTap: onTap,
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward_rounded, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  key: const ValueKey('chatJumpToLatestLabel'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    key: const ValueKey('chatScrollToLatestPendingCount'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
