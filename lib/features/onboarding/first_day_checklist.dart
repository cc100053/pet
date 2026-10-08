import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/ui/juice_wrappers.dart';

/// Accounts created from this instant get the first-day checklist and its
/// rewards; older accounts never do. Mirrors the check in
/// `claim_onboarding_reward` (supabase/migrations/20261008074506_*).
final DateTime kFirstDayAccountCutoff = DateTime.utc(2026, 10, 8);

/// Whether an account (auth `created_at`, ISO 8601) is new enough for the
/// first-day checklist. Unknown or unparsable dates count as not eligible.
bool isFirstDayEligibleAccount(String? createdAt) {
  final created = DateTime.tryParse(createdAt ?? '');
  return created != null && !created.isBefore(kFirstDayAccountCutoff);
}

/// One-time onboarding tasks. [key] and [coins] mirror
/// `claim_onboarding_reward` (supabase/migrations/20261008074506_*); the
/// server is the authority, [coins] is only what the card promises.
enum FirstDayTask {
  firstFeed('first_feed', 20),
  coKeeperJoined('co_keeper_joined', 50),
  firstFurniture('first_furniture', 10),
  firstChat('first_chat', 10);

  const FirstDayTask(this.key, this.coins);

  final String key;
  final int coins;

  /// The room owner brings a co-keeper; an invited keeper says hi instead.
  static List<FirstDayTask> forKeeper({required bool isOwner}) => [
    firstFeed,
    isOwner ? coKeeperJoined : firstChat,
    firstFurniture,
  ];

  String label(AppLocalizations l10n, String petName) => switch (this) {
    firstFeed => l10n.firstDayTaskFeed(petName),
    coKeeperJoined => l10n.firstDayTaskCoKeeper,
    firstFurniture => l10n.firstDayTaskFurniture,
    firstChat => l10n.firstDayTaskChat,
  };
}

/// "`petName`'s first day": three tasks, done ones struck through, the first
/// open one styled as the next action. Tapping a row runs its action.
class FirstDayChecklistCard extends StatelessWidget {
  const FirstDayChecklistCard({
    super.key,
    required this.petName,
    required this.tasks,
    required this.claimed,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onTapTask,
    required this.onDismiss,
  });

  final String petName;
  final List<FirstDayTask> tasks;
  final Set<String> claimed;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<FirstDayTask> onTapTask;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final done = tasks.where((t) => claimed.contains(t.key)).length;
    final next = tasks.cast<FirstDayTask?>().firstWhere(
      (t) => !claimed.contains(t!.key),
      orElse: () => null,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.ink, width: 2.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  expanded: !collapsed,
                  child: InkWell(
                    onTap: onToggleCollapsed,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.firstDayTitle(petName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$done / ${tasks.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.leafDeep,
                            ),
                          ),
                          Icon(
                            collapsed
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppTheme.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppTheme.ink,
              ),
            ],
          ),
          if (!collapsed) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tasks.isEmpty ? 0 : done / tasks.length,
                  minHeight: 8,
                  backgroundColor: AppTheme.softLine,
                  color: AppTheme.leafStrong,
                ),
              ),
            ),
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: _TaskRow(
                  label: task.label(l10n, petName),
                  coins: task.coins,
                  done: claimed.contains(task.key),
                  isNext: task == next,
                  onTap: () => onTapTask(task),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.label,
    required this.coins,
    required this.done,
    required this.isNext,
    required this.onTap,
  });

  final String label;
  final int coins;
  final bool done;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFFE8F5EC)
            : (isNext ? Colors.white : Colors.transparent),
        borderRadius: BorderRadius.circular(14),
        border: isNext
            ? Border.all(color: AppTheme.ink, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 24,
            color: done ? AppTheme.leafStrong : AppTheme.ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isNext ? FontWeight.w800 : FontWeight.w700,
                color: done ? AppTheme.textSecondary : AppTheme.textPrimary,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$coins',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: done ? AppTheme.textSecondary : AppTheme.ink,
            ),
          ),
        ],
      ),
    );
    if (done) {
      return Semantics(label: label, checked: true, child: row);
    }
    return Semantics(
      button: true,
      checked: false,
      label: label,
      excludeSemantics: true,
      child: JuicyScaleButton(onTap: onTap, child: row),
    );
  }
}
