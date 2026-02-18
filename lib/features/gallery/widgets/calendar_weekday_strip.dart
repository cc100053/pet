part of '../memory_calendar_view.dart';

class _WeekdayStrip extends StatelessWidget {
  const _WeekdayStrip({
    required this.labels,
    required this.dates,
    required this.feedsByDay,
  });

  final List<String> labels;
  final List<DateTime> dates;
  final Map<DateTime, List<MemoryFeed>> feedsByDay;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: _CalendarColors.textMuted,
      fontWeight: FontWeight.w600,
    );

    return Column(
      children: [
        Row(
          children: labels
              .map(
                (label) => Expanded(
                  child: Center(child: Text(label, style: labelStyle)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _CalendarColors.lineSoft,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: dates.map((date) {
                  final key = DateTime(date.year, date.month, date.day);
                  final hasFeed = (feedsByDay[key] ?? const []).isNotEmpty;
                  final now = DateTime.now();
                  final isToday =
                      now.year == date.year &&
                      now.month == date.month &&
                      now.day == date.day;
                  return _DayBubble(
                    isToday: isToday,
                    hasFeed: hasFeed,
                    isInMonth: date.month == now.month,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
