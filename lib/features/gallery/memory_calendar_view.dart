import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../shared/ui/cached_network_image_view.dart';

class MemoryCalendarView extends StatefulWidget {
  const MemoryCalendarView({
    super.key,
    required this.roomId,
    this.currentUserId,
  });

  final String roomId;
  final String? currentUserId;

  @override
  State<MemoryCalendarView> createState() => _MemoryCalendarViewState();
}

class _MemoryCalendarViewState extends State<MemoryCalendarView> {
  late DateTime _focusedMonth;
  bool _loading = true;
  String? _error;
  final Map<DateTime, List<MemoryFeed>> _feedsByDay = {};
  final Set<String> _blockedUserIds = {};
  MemoryFeed? _latestFeed;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _reloadMonth();
  }

  Future<void> _reloadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _loadBlockedUsers();
      await _loadLatestFeed();
      await _loadMonth();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.calendarLoadFailed(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadBlockedUsers() async {
    final userId = widget.currentUserId;
    _blockedUserIds.clear();
    if (userId == null) {
      return;
    }

    final response = await Supabase.instance.client
        .from('blocks')
        .select('blocked_user_id')
        .eq('blocker_id', userId);

    final rows = response as List<dynamic>;
    for (final row in rows) {
      final id = row['blocked_user_id'] as String?;
      if (id != null && id.isNotEmpty) {
        _blockedUserIds.add(id);
      }
    }
  }

  Future<void> _loadMonth() async {
    final start = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);

    final response = await Supabase.instance.client
        .from('messages')
        .select('id,sender_id,image_url,caption,created_at')
        .eq('room_id', widget.roomId)
        .eq('type', 'image_feed')
        .gte('created_at', start.toUtc().toIso8601String())
        .lt('created_at', end.toUtc().toIso8601String())
        .order('created_at', ascending: true);

    final rows = response as List<dynamic>;
    final feeds = rows
        .map((row) => MemoryFeed.fromJson(row))
        .where((feed) => feed.imageUrl.isNotEmpty)
        .where(
          (feed) =>
              feed.senderId == null || !_blockedUserIds.contains(feed.senderId),
        )
        .toList();

    _feedsByDay
      ..clear()
      ..addEntries(_groupByDay(feeds).entries);
  }

  Future<void> _loadLatestFeed() async {
    final response = await Supabase.instance.client
        .from('messages')
        .select('id,sender_id,image_url,caption,created_at')
        .eq('room_id', widget.roomId)
        .eq('type', 'image_feed')
        .order('created_at', ascending: false)
        .limit(10);

    final rows = response as List<dynamic>;
    final feeds = rows
        .map((row) => MemoryFeed.fromJson(row))
        .where((feed) => feed.imageUrl.isNotEmpty)
        .where(
          (feed) =>
              feed.senderId == null || !_blockedUserIds.contains(feed.senderId),
        )
        .toList();

    _latestFeed = feeds.isEmpty ? null : feeds.first;
  }

  Map<DateTime, List<MemoryFeed>> _groupByDay(List<MemoryFeed> feeds) {
    final map = <DateTime, List<MemoryFeed>>{};
    for (final feed in feeds) {
      final local = feed.createdAt.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      map.putIfAbsent(key, () => []).add(feed);
    }
    return map;
  }

  void _shiftMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
    });
    _reloadMonth();
  }

  String _monthLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMM(locale).format(date);
  }

  String _monthYearLabel(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMM(locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CalendarColors.background,
      body: SafeArea(child: _buildCalendarBody(context)),
    );
  }

  Widget _buildCalendarBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _reloadMonth,
                child: Text(AppLocalizations.of(context)!.commonTryAgain),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final weekdayLabels = _weekdayLabelsForLocale(context);
    final latestInMonth = _latestFeedFromMonth();
    final latestFeed = _latestFeed ?? latestInMonth;
    final latestDateKey = latestFeed == null
        ? null
        : _dayKeyForDate(latestFeed.createdAt.toLocal());
    final latestDayFeeds = latestDateKey == null
        ? const <MemoryFeed>[]
        : List<MemoryFeed>.from(
            _feedsByDay[latestDateKey] ?? [latestFeed],
          );
    latestDayFeeds.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recentFeeds = _buildRecentFeeds(latestFeed);

    return RefreshIndicator(
      onRefresh: _reloadMonth,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CalendarHeader(
                label: _monthLabel(context, _focusedMonth),
                onMenuTap: () => _handleHeaderTap(context),
              ),
              const SizedBox(height: 16),
              _WeekdayStrip(
                labels: weekdayLabels,
                dates: _currentWeekDates(now),
                feedsByDay: _feedsByDay,
              ),
              const SizedBox(height: 18),
              _MonthNavigator(
                label: _monthYearLabel(context, _focusedMonth),
                onPrevious: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              const SizedBox(height: 12),
              _MonthCalendarCard(
                focusedMonth: _focusedMonth,
                feedsByDay: _feedsByDay,
                onDayTap: (date, feeds) =>
                    _openDayDetails(context, date, feeds),
                weekdayLabels: weekdayLabels,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.calendarLatestPhoto,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _CalendarColors.textStrong,
                ),
              ),
              const SizedBox(height: 12),
              _TodayCard(
                feed: latestFeed,
                dateLabel: latestFeed == null
                    ? _formatShortDate(context, now)
                    : _formatShortDate(context, latestFeed.createdAt.toLocal()),
                emptyLabel: l10n.calendarNoPhotoYet,
                fallbackLabel: l10n.calendarLatestPhoto,
                onTap: latestFeed == null
                    ? null
                    : () {
                        final dateKey =
                            latestDateKey ?? _dayKeyForDate(now);
                        _openDayDetails(context, dateKey, latestDayFeeds);
                      },
              ),
              const SizedBox(height: 20),
              Text(
                l10n.calendarEarlier,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _CalendarColors.textStrong,
                ),
              ),
              const SizedBox(height: 12),
              _RecentRow(
                feeds: recentFeeds,
                onTap: (feed) {
                  final local = feed.createdAt.toLocal();
                  final dateKey = DateTime(local.year, local.month, local.day);
                  final feeds = _feedsByDay[dateKey] ?? const [];
                  _openDayDetails(context, dateKey, feeds);
                },
                emptyLabel: l10n.calendarNoEarlierMemories,
                placeholderLabel: l10n.calendarAddMemory,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDayDetails(
    BuildContext context,
    DateTime date,
    List<MemoryFeed> feeds,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _CalendarColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MemoryDaySheet(date: date, feeds: feeds),
    );
  }

  void _handleHeaderTap(BuildContext context) {
    Navigator.maybePop(context);
  }

  List<MemoryFeed> _buildRecentFeeds(MemoryFeed? excludedFeed) {
    final feeds = <MemoryFeed>[];
    for (final entry in _feedsByDay.entries) {
      feeds.addAll(entry.value);
    }
    feeds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (excludedFeed != null) {
      feeds.removeWhere((feed) => feed.id == excludedFeed.id);
    }
    return feeds.take(3).toList();
  }

  MemoryFeed? _latestFeedFromMonth() {
    final feeds = <MemoryFeed>[];
    for (final entry in _feedsByDay.entries) {
      feeds.addAll(entry.value);
    }
    if (feeds.isEmpty) {
      return null;
    }
    feeds.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return feeds.last;
  }

  List<DateTime> _currentWeekDates(DateTime reference) {
    final startOffset = reference.weekday % 7;
    final start = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).subtract(Duration(days: startOffset));
    return List.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  DateTime _dayKeyForDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<String> _weekdayLabelsForLocale(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = DateTime(2020, 1, 5);
    return List.generate(
      7,
      (index) => DateFormat.E(
        locale,
      ).format(DateTime(start.year, start.month, start.day + index)),
    );
  }

  String _formatShortDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.Md(locale).format(date);
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.label, required this.onMenuTap});

  final String label;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onMenuTap),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: _CalendarColors.textStrong,
          ),
        ),
      ],
    );
  }
}

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

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _CalendarColors.textStrong,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  const _MonthCalendarCard({
    required this.focusedMonth,
    required this.feedsByDay,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _CalendarColors.outlineSoft),
        boxShadow: [
          BoxShadow(
            color: _CalendarColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
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

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.feeds,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final List<MemoryFeed> feeds;
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
            ],
          ),
        ),
      ),
    );
  }
}

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

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.feed,
    required this.dateLabel,
    required this.emptyLabel,
    required this.fallbackLabel,
    required this.onTap,
  });

  final MemoryFeed? feed;
  final String dateLabel;
  final String emptyLabel;
  final String fallbackLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caption = _captionOrFallback(feed, dateLabel);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _CalendarColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _CalendarColors.outline),
          boxShadow: [
            BoxShadow(
              color: _CalendarColors.shadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: feed == null
                    ? Container(
                        color: _CalendarColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: Text(
                          emptyLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _CalendarColors.textMuted,
                          ),
                        ),
                      )
                    : CachedNetworkImageView(
                        imageUrl: feed!.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: _CalendarColors.surfaceMuted,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: _CalendarColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _CalendarColors.outlineSoft),
              ),
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _CalendarColors.textStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _captionOrFallback(MemoryFeed? feed, String dateLabel) {
    final caption = feed?.caption?.trim();
    if (caption != null && caption.isNotEmpty) {
      return caption;
    }
    return '$fallbackLabel • $dateLabel';
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.feeds,
    required this.onTap,
    required this.emptyLabel,
    required this.placeholderLabel,
  });

  final List<MemoryFeed> feeds;
  final void Function(MemoryFeed feed) onTap;
  final String emptyLabel;
  final String placeholderLabel;

  @override
  Widget build(BuildContext context) {
    final items = feeds
        .map((feed) => _RecentMemoryCard(feed: feed, onTap: () => onTap(feed)))
        .toList();

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _CalendarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _CalendarColors.outlineSoft),
        ),
        child: Text(
          emptyLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _CalendarColors.textMuted),
        ),
      );
    }

    while (items.length < 3) {
      items.add(
        _RecentMemoryCard.placeholder(placeholderLabel: placeholderLabel),
      );
    }

    return Row(
      children: [
        for (final item in items) ...[
          Expanded(child: item),
          if (item != items.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _RecentMemoryCard extends StatelessWidget {
  const _RecentMemoryCard({required this.feed, required this.onTap})
    : isPlaceholder = false,
      placeholderLabel = null;

  const _RecentMemoryCard.placeholder({required this.placeholderLabel})
    : feed = null,
      onTap = null,
      isPlaceholder = true;

  final MemoryFeed? feed;
  final VoidCallback? onTap;
  final bool isPlaceholder;
  final String? placeholderLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isPlaceholder ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _CalendarColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _CalendarColors.outlineSoft),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: isPlaceholder || feed == null
                    ? Container(
                        color: _CalendarColors.surfaceMuted,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.photo_outlined,
                          color: _CalendarColors.textMuted,
                        ),
                      )
                    : CachedNetworkImageView(
                        imageUrl: feed!.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: _CalendarColors.surfaceMuted,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _buildCardLabel(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isPlaceholder
                    ? _CalendarColors.textMuted
                    : _CalendarColors.textStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildCardLabel(BuildContext context) {
    if (isPlaceholder || feed == null) {
      return placeholderLabel ?? '';
    }
    final caption = feed!.caption?.trim();
    if (caption != null && caption.isNotEmpty) {
      return caption;
    }
    final local = feed!.createdAt.toLocal();
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.Md(locale).format(local);
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CalendarColors.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _CalendarColors.outlineSoft),
          ),
          child: Icon(icon, color: _CalendarColors.textStrong),
        ),
      ),
    );
  }
}

class _MemoryDaySheet extends StatelessWidget {
  const _MemoryDaySheet({required this.date, required this.feeds});

  final DateTime date;
  final List<MemoryFeed> feeds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMd(locale).format(date);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: _CalendarColors.lineSoft,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(dateLabel, style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: feeds.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.calendarNoMemoriesForDay,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final feed = feeds[index];
                        final localTime = feed.createdAt.toLocal();
                        final timeLabel = TimeOfDay.fromDateTime(
                          localTime,
                        ).format(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImageView(
                                imageUrl: feed.imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  height: 200,
                                  color: theme.colorScheme.surface,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeLabel,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _CalendarColors.textMuted,
                              ),
                            ),
                            if (feed.caption != null &&
                                feed.caption!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(feed.caption!),
                              ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemCount: feeds.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color outline = Color(0xFFE2E8F0);
  static const Color outlineSoft = Color(0xFFE5E7EB);
  static const Color lineSoft = Color(0xFFCBD5F5);
  static const Color textStrong = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color primary = Color(0xFF3B82F6);
  static const Color primarySoft = Color(0xFFDBEAFE);
  static const Color shadow = Color(0x1A1E293B);
}

class MemoryFeed {
  MemoryFeed({
    required this.id,
    required this.senderId,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String? senderId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;

  factory MemoryFeed.fromJson(Map<String, dynamic> json) {
    return MemoryFeed(
      id: (json['id'] as String?) ?? '',
      senderId: json['sender_id'] as String?,
      imageUrl: (json['image_url'] as String?) ?? '',
      caption: json['caption'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
