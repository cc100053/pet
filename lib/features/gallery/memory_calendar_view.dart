import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  late DateTime _focusedMonth;
  bool _loading = true;
  String? _error;
  final Map<DateTime, List<MemoryFeed>> _feedsByDay = {};
  final Set<String> _blockedUserIds = {};

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
      await _loadMonth();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load memories: $error';
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
        .where((feed) =>
            feed.senderId == null || !_blockedUserIds.contains(feed.senderId))
        .toList();

    _feedsByDay
      ..clear()
      ..addEntries(_groupByDay(feeds).entries);
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

  String _monthLabel(DateTime date) {
    final monthIndex = date.month - 1;
    if (monthIndex < 0 || monthIndex >= _monthNames.length) {
      return '${date.month}/${date.year}';
    }
    return '${_monthNames[monthIndex]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memories'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _reloadMonth,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthHeader(
            label: _monthLabel(_focusedMonth),
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          _WeekdayRow(labels: _weekdayLabels),
          Expanded(child: _buildCalendarBody(context)),
        ],
      ),
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
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final leadingEmpty = firstDay.weekday % 7;
    final totalCells = leadingEmpty + daysInMonth;
    final cellCount = totalCells <= 35 ? 35 : 42;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.78,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        final dayIndex = index - leadingEmpty + 1;
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(year, month, dayIndex);
        final key = DateTime(date.year, date.month, date.day);
        final feeds = _feedsByDay[key] ?? const [];
        final today = DateTime.now();
        final isToday = today.year == date.year &&
            today.month == date.month &&
            today.day == date.day;

        return _DayCell(
          date: date,
          feeds: feeds,
          isToday: isToday,
          onTap: feeds.isEmpty
              ? null
              : () => _openDayDetails(context, date, feeds),
        );
      },
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
      builder: (context) => _MemoryDaySheet(
        date: date,
        feeds: feeds,
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: Colors.black54);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Center(child: Text(label, style: style)),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
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
    final surface = theme.colorScheme.surface;
    final highlight = theme.colorScheme.primaryContainer;
    final borderColor = theme.colorScheme.outlineVariant;

    final previews = feeds.take(2).toList();

    return Material(
      color: isToday ? highlight : surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: previews.isEmpty
                    ? const SizedBox.shrink()
                    : Row(
                        children: previews
                            .map(
                              (feed) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      feed.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          Container(
                                        color: theme.colorScheme.surface,
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              if (feeds.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${feeds.length - 2}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
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

class _MemoryDaySheet extends StatelessWidget {
  const _MemoryDaySheet({required this.date, required this.feeds});

  final DateTime date;
  final List<MemoryFeed> feeds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: theme.textTheme.titleMedium,
                    ),
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
                  ? const Center(child: Text('No memories for this day.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final feed = feeds[index];
                        final localTime = feed.createdAt.toLocal();
                        final timeLabel =
                            TimeOfDay.fromDateTime(localTime).format(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                feed.imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Container(
                                  height: 200,
                                  color: theme.colorScheme.surface,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              timeLabel,
                              style: theme.textTheme.labelMedium,
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
