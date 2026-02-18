part of '../memory_calendar_view.dart';

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.focusedMonth,
    required this.feedsByDay,
    required this.senderProfiles,
    required this.onDayTap,
    this.weekdayLabels = const [
      'Sun',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
    ],
  });

  final DateTime focusedMonth;
  final Map<DateTime, List<MemoryFeed>> feedsByDay;
  final Map<String, ProfileSummary> senderProfiles;
  final List<String> weekdayLabels;
  final void Function(DateTime date, List<MemoryFeed> feeds) onDayTap;

  @override
  Widget build(BuildContext context) {
    final year = focusedMonth.year;
    final month = focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final leadingEmpty = firstDay.weekday % 7;
    final totalCells = leadingEmpty + daysInMonth;
    final cellCount = totalCells <= 35 ? 35 : 42;

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: _CalendarColors.textMuted,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: _CalendarColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _CalendarColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: _CalendarColors.shadow,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(child: Text(label, style: labelStyle)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: cellCount,
            itemBuilder: (context, index) {
              final dayIndex = index - leadingEmpty + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(year, month, dayIndex);
              final key = DateTime(date.year, date.month, date.day);
              final feeds = feedsByDay[key] ?? const [];
              final now = DateTime.now();
              final isToday =
                  now.year == date.year &&
                  now.month == date.month &&
                  now.day == date.day;

              return _MonthDayCell(
                date: date,
                feeds: feeds,
                senderProfile: feeds.isEmpty
                    ? null
                    : senderProfiles[feeds.last.senderId],
                senderFallbackText: feeds.isEmpty
                    ? null
                    : _senderDisplayName(
                        senderId: feeds.last.senderId,
                        senderProfiles: senderProfiles,
                      ),
                isToday: isToday,
                onTap: feeds.isEmpty ? null : () => onDayTap(date, feeds),
              );
            },
          ),
        ],
      ),
    );
  }
}
