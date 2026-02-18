part of '../memory_calendar_view.dart';

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.feeds,
    required this.senderProfile,
    required this.senderFallbackText,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final List<MemoryFeed> feeds;
  final ProfileSummary? senderProfile;
  final String? senderFallbackText;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feed = feeds.isEmpty ? null : feeds.last;
    final borderColor = isToday
        ? _CalendarColors.primary
        : _CalendarColors.outlineSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: _CalendarColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isToday ? 1.6 : 1),
          ),
          child: Stack(
            children: [
              if (feed != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImageView(
                      imageUrl: feed.imageUrl,
                      fit: BoxFit.cover,
                      portraitFriendlyCrop: true,
                      errorWidget: Container(
                        color: _CalendarColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, size: 16),
                      ),
                    ),
                  ),
                ),
              if (feed != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: feed == null
                        ? _CalendarColors.surface
                        : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${date.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: feed == null
                          ? _CalendarColors.textStrong
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (feed != null)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: _PhotoSenderBadge(
                    avatarUrl: senderProfile?.avatarUrl,
                    fallbackText: senderFallbackText,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
