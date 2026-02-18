import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../../services/profile/profile_cache_service.dart';
import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/cached_network_image_view.dart';
import '../../shared/ui/full_screen_photo_viewer.dart';
import '../../shared/ui/user_avatar.dart';
import 'models/memory_feed.dart';
import 'services/memory_calendar_data_service.dart';

part 'widgets/calendar_header.dart';
part 'widgets/calendar_weekday_strip.dart';
part 'widgets/calendar_month_navigator.dart';
part 'widgets/calendar_month_card.dart';
part 'widgets/calendar_day_cell.dart';
part 'widgets/calendar_day_bubble.dart';

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
  final MemoryCalendarDataService _dataService =
      MemoryCalendarDataService.instance;
  late DateTime _focusedMonth;
  bool _loading = true;
  String? _error;
  final Map<DateTime, List<MemoryFeed>> _feedsByDay = {};
  final Set<String> _blockedUserIds = {};
  final Map<String, ProfileSummary> _senderProfiles = {};
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
      await _loadSenderProfiles();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.calendarLoadFailed(userFacingError(context, error));
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
    _blockedUserIds.clear();
    final blocked = await _dataService.loadBlockedUserIds(
      currentUserId: widget.currentUserId,
    );
    _blockedUserIds.addAll(blocked);
  }

  Future<void> _loadMonth() async {
    final feeds = await _dataService.loadMonthFeeds(
      roomId: widget.roomId,
      month: _focusedMonth,
      blockedUserIds: _blockedUserIds,
    );

    _feedsByDay
      ..clear()
      ..addEntries(_groupByDay(feeds).entries);
  }

  Future<void> _loadLatestFeed() async {
    final feeds = await _dataService.loadLatestFeeds(
      roomId: widget.roomId,
      blockedUserIds: _blockedUserIds,
    );

    _latestFeed = feeds.isEmpty ? null : feeds.first;
  }

  Future<void> _loadSenderProfiles() async {
    final senderIds = <String>{};
    for (final feeds in _feedsByDay.values) {
      for (final feed in feeds) {
        final senderId = feed.senderId;
        if (senderId != null && senderId.isNotEmpty) {
          senderIds.add(senderId);
        }
      }
    }

    final latestSenderId = _latestFeed?.senderId;
    if (latestSenderId != null && latestSenderId.isNotEmpty) {
      senderIds.add(latestSenderId);
    }

    _senderProfiles.clear();
    if (senderIds.isEmpty) {
      return;
    }

    final profiles = await _dataService.loadSenderProfiles(senderIds);
    _senderProfiles.addAll(profiles);
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _CalendarColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _CalendarHeader(
                label: _monthLabel(context, _focusedMonth),
                subtitle: l10n.calendarTitle,
                onMenuTap: () => _handleHeaderTap(context),
              ),
            ),
            Expanded(child: _buildCalendarBody(context)),
          ],
        ),
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
        ? <MemoryFeed>[]
        : List<MemoryFeed>.from(_feedsByDay[latestDateKey] ?? [latestFeed]);
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
                senderProfiles: _senderProfiles,
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
                senderProfile: latestFeed == null
                    ? null
                    : _senderProfiles[latestFeed.senderId],
                senderFallbackText: latestFeed == null
                    ? null
                    : _fallbackSenderName(latestFeed.senderId),
                dateLabel: latestFeed == null
                    ? _formatShortDate(context, now)
                    : _formatShortDate(context, latestFeed.createdAt.toLocal()),
                emptyLabel: l10n.calendarNoPhotoYet,
                fallbackLabel: l10n.calendarLatestPhoto,
                onTap: latestFeed == null
                    ? null
                    : () {
                        final dateKey = latestDateKey ?? _dayKeyForDate(now);
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
                senderProfiles: _senderProfiles,
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
      builder: (context) => _MemoryDaySheet(
        date: date,
        feeds: feeds,
        senderProfiles: _senderProfiles,
      ),
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

  String _fallbackSenderName(String? senderId) {
    if (senderId == null || senderId.isEmpty) {
      return '?';
    }
    final profile = _senderProfiles[senderId];
    final nickname = profile?.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    return senderId;
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.feed,
    required this.senderProfile,
    required this.senderFallbackText,
    required this.dateLabel,
    required this.emptyLabel,
    required this.fallbackLabel,
    required this.onTap,
  });

  final MemoryFeed? feed;
  final ProfileSummary? senderProfile;
  final String? senderFallbackText;
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
              child: Stack(
                children: [
                  AspectRatio(
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
                            portraitFriendlyCrop: true,
                            errorWidget: Container(
                              color: _CalendarColors.surfaceMuted,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                  ),
                  if (feed != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _PhotoSenderBadge(
                        avatarUrl: senderProfile?.avatarUrl,
                        fallbackText: senderFallbackText,
                        size: 30,
                      ),
                    ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        dateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
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
    required this.senderProfiles,
    required this.onTap,
    required this.emptyLabel,
    required this.placeholderLabel,
  });

  final List<MemoryFeed> feeds;
  final Map<String, ProfileSummary> senderProfiles;
  final void Function(MemoryFeed feed) onTap;
  final String emptyLabel;
  final String placeholderLabel;

  @override
  Widget build(BuildContext context) {
    final items = feeds
        .map(
          (feed) => _RecentMemoryCard(
            feed: feed,
            senderProfile: senderProfiles[feed.senderId],
            senderFallbackText: _senderDisplayName(
              senderId: feed.senderId,
              senderProfiles: senderProfiles,
            ),
            onTap: () => onTap(feed),
          ),
        )
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
  const _RecentMemoryCard({
    required this.feed,
    required this.senderProfile,
    required this.senderFallbackText,
    required this.onTap,
  }) : isPlaceholder = false,
       placeholderLabel = null;

  const _RecentMemoryCard.placeholder({required this.placeholderLabel})
    : feed = null,
      senderProfile = null,
      senderFallbackText = null,
      onTap = null,
      isPlaceholder = true;

  final MemoryFeed? feed;
  final ProfileSummary? senderProfile;
  final String? senderFallbackText;
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
              child: Stack(
                children: [
                  AspectRatio(
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
                            portraitFriendlyCrop: true,
                            errorWidget: Container(
                              color: _CalendarColors.surfaceMuted,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                  ),
                  if (!isPlaceholder && feed != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: _PhotoSenderBadge(
                        avatarUrl: senderProfile?.avatarUrl,
                        fallbackText: senderFallbackText,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            if (!isPlaceholder && feed != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 7,
                      color: _CalendarColors.secondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        senderFallbackText ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _CalendarColors.textMuted,
                        ),
                      ),
                    ),
                  ],
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

String _senderDisplayName({
  required String? senderId,
  required Map<String, ProfileSummary> senderProfiles,
}) {
  if (senderId == null || senderId.isEmpty) {
    return '?';
  }
  final profile = senderProfiles[senderId];
  final nickname = profile?.nickname?.trim();
  if (nickname != null && nickname.isNotEmpty) {
    return nickname;
  }
  return senderId;
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
  const _MemoryDaySheet({
    required this.date,
    required this.feeds,
    required this.senderProfiles,
  });

  final DateTime date;
  final List<MemoryFeed> feeds;
  final Map<String, ProfileSummary> senderProfiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat.yMMMd(locale).format(date);
    final imageUrls = feeds.map((feed) => feed.imageUrl).toList();
    final captions = feeds.map((feed) => feed.caption).toList();

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
                            GestureDetector(
                              onTap: () {
                                FullScreenPhotoViewer.open(
                                  context,
                                  imageUrls: imageUrls,
                                  captions: captions,
                                  initialIndex: index,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    ColoredBox(
                                      color: _CalendarColors.surfaceMuted,
                                      child: CachedNetworkImageView(
                                        imageUrl: feed.imageUrl,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.contain,
                                        errorWidget: Container(
                                          height: 200,
                                          color: theme.colorScheme.surface,
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: _PhotoSenderBadge(
                                        avatarUrl: senderProfiles[feed.senderId]
                                            ?.avatarUrl,
                                        fallbackText: _senderDisplayName(
                                          senderId: feed.senderId,
                                          senderProfiles: senderProfiles,
                                        ),
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  timeLabel,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: _CalendarColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _senderDisplayName(
                                      senderId: feed.senderId,
                                      senderProfiles: senderProfiles,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: _CalendarColors.textMuted,
                                        ),
                                  ),
                                ),
                              ],
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
  static const Color background = Color(0xFFFFF8EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFFF1E3);
  static const Color outline = Color(0xFFF6D8B4);
  static const Color outlineSoft = Color(0xFFFBE5CC);
  static const Color lineSoft = Color(0xFFFBCB99);
  static const Color textStrong = Color(0xFF3D2A1A);
  static const Color textMuted = Color(0xFF88674A);
  static const Color primary = Color(0xFFFF8A3D);
  static const Color primarySoft = Color(0xFFFFE6CE);
  static const Color secondary = Color(0xFF43B581);
  static const Color shadow = Color(0x1F6E3C0F);
}

class _PhotoSenderBadge extends StatelessWidget {
  const _PhotoSenderBadge({
    required this.avatarUrl,
    required this.fallbackText,
    required this.size,
  });

  final String? avatarUrl;
  final String? fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _CalendarColors.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: _CalendarColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: UserAvatar(
        avatar: avatarUrl,
        fallbackText: fallbackText,
        size: size - 4,
      ),
    );
  }
}
