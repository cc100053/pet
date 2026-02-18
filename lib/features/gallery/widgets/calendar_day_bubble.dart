part of '../memory_calendar_view.dart';

class _DayBubble extends StatelessWidget {
  const _DayBubble({
    required this.isToday,
    required this.hasFeed,
    required this.isInMonth,
  });

  final bool isToday;
  final bool hasFeed;
  final bool isInMonth;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isToday
        ? _CalendarColors.primary
        : _CalendarColors.outline;
    final Color fillColor = isToday
        ? _CalendarColors.primary
        : hasFeed
        ? _CalendarColors.primarySoft
        : _CalendarColors.surface;
    final double opacity = isInMonth ? 1 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: fillColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
        ),
      ),
    );
  }
}
