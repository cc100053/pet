import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/onboarding/first_day_checklist.dart';
import 'package:pet/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Set<String> claimed,
  bool collapsed = false,
  ValueChanged<FirstDayTask>? onTap,
  VoidCallback? onDismiss,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FirstDayChecklistCard(
          petName: 'Mochi',
          tasks: FirstDayTask.forKeeper(isOwner: true),
          claimed: claimed,
          collapsed: collapsed,
          onToggleCollapsed: () {},
          onTapTask: onTap ?? (_) {},
          onDismiss: onDismiss ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  test('owner invites a co-keeper; an invited keeper says hi instead', () {
    expect(FirstDayTask.forKeeper(isOwner: true), [
      FirstDayTask.firstFeed,
      FirstDayTask.coKeeperJoined,
      FirstDayTask.firstFurniture,
    ]);
    expect(FirstDayTask.forKeeper(isOwner: false), [
      FirstDayTask.firstFeed,
      FirstDayTask.firstChat,
      FirstDayTask.firstFurniture,
    ]);
  });

  test('promised coins match claim_onboarding_reward', () {
    final sql = File(
      'supabase/migrations/20261008074506_onboarding_rewards_new_accounts_only.sql',
    ).readAsStringSync();
    for (final task in FirstDayTask.values) {
      expect(
        sql,
        contains("when '${task.key}' then ${task.coins}"),
        reason: '${task.key} amount drifted from the server',
      );
    }
  });

  test('only accounts created on or after the cutoff are eligible', () {
    expect(isFirstDayEligibleAccount('2026-10-08T00:00:00Z'), isTrue);
    expect(
      isFirstDayEligibleAccount('2026-11-01T09:30:00.123456+00:00'),
      isTrue,
    );
    expect(isFirstDayEligibleAccount('2026-10-07T23:59:59Z'), isFalse);
    expect(isFirstDayEligibleAccount(null), isFalse);
    expect(isFirstDayEligibleAccount('not a date'), isFalse);
  });

  test('push soft ask: first feed, then once more after the snooze', () {
    final now = DateTime.utc(2026, 10, 20);
    expect(
      shouldSoftAskForPush(askedCount: 0, snoozedUntil: null, now: now),
      isTrue,
    );
    expect(
      shouldSoftAskForPush(
        askedCount: 1,
        snoozedUntil: now.add(const Duration(hours: 1)),
        now: now,
      ),
      isFalse,
    );
    expect(
      shouldSoftAskForPush(askedCount: 1, snoozedUntil: now, now: now),
      isTrue,
    );
    // Said yes (no snooze recorded): never ask again.
    expect(
      shouldSoftAskForPush(askedCount: 1, snoozedUntil: null, now: now),
      isFalse,
    );
    expect(
      shouldSoftAskForPush(
        askedCount: 2,
        snoozedUntil: DateTime.utc(2000),
        now: now,
      ),
      isFalse,
    );
    expect(kPushSoftAskSnooze, const Duration(days: 3));
  });

  test('account cutoff matches the server', () {
    final sql = File(
      'supabase/migrations/20261008074506_onboarding_rewards_new_accounts_only.sql',
    ).readAsStringSync();
    expect(sql, contains("created_at >= timestamptz '2026-10-08 00:00:00+00'"));
    expect(kFirstDayAccountCutoff, DateTime.utc(2026, 10, 8));
  });

  testWidgets('shows progress, strikes done tasks, taps open tasks', (
    tester,
  ) async {
    FirstDayTask? tapped;
    await _pump(
      tester,
      claimed: {FirstDayTask.firstFeed.key},
      onTap: (task) => tapped = task,
    );
    expect(find.text("Mochi's first day"), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    // Done tasks are not tappable.
    await tester.tap(find.text('Feed Mochi a photo'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped, isNull);

    await tester.tap(find.text('Get a co-keeper'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped, FirstDayTask.coKeeperJoined);
  });

  testWidgets('collapsed shows only the header; close dismisses', (
    tester,
  ) async {
    var dismissed = false;
    await _pump(
      tester,
      claimed: const {},
      collapsed: true,
      onDismiss: () => dismissed = true,
    );
    expect(find.text('Get a co-keeper'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    expect(dismissed, isTrue);
  });
}
