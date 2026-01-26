import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/ui/user_avatar.dart';

class BlockedUsersSheet extends StatefulWidget {
  const BlockedUsersSheet({
    super.key,
    required this.currentUserId,
    this.onBlockListChanged,
  });

  final String currentUserId;
  final VoidCallback? onBlockListChanged;

  @override
  State<BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

class _BlockedUsersSheetState extends State<BlockedUsersSheet> {
  bool _loading = true;
  String? _error;
  bool _changed = false;
  final List<_BlockedUserEntry> _entries = [];
  final Set<String> _unblockingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('blocks')
          .select('blocked_user_id,created_at')
          .eq('blocker_id', widget.currentUserId)
          .order('created_at', ascending: false);

      final rows = response as List<dynamic>;
      final blockedIds = <String>[];
      final createdAtById = <String, DateTime?>{};
      for (final row in rows) {
        final id = row['blocked_user_id'] as String?;
        if (id == null || id.isEmpty) {
          continue;
        }
        blockedIds.add(id);
        final createdAtRaw = row['created_at'];
        createdAtById[id] = _parseOptionalDate(createdAtRaw);
      }

      if (blockedIds.isEmpty) {
        _entries.clear();
        return;
      }

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('user_id,nickname,avatar_url')
          .filter('user_id', 'in', blockedIds);

      final profiles = profileResponse as List<dynamic>;
      final profileById = <String, _ProfileInfo>{};
      for (final row in profiles) {
        final id = row['user_id'] as String?;
        if (id == null || id.isEmpty) {
          continue;
        }
        profileById[id] = _ProfileInfo(
          nickname: row['nickname'] as String?,
          avatarUrl: row['avatar_url'] as String?,
        );
      }

      _entries
        ..clear()
        ..addAll(
          blockedIds.map((id) {
            final profile = profileById[id];
            return _BlockedUserEntry(
              userId: id,
              nickname: profile?.nickname,
              avatarUrl: profile?.avatarUrl,
              createdAt: createdAtById[id],
            );
          }),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = AppLocalizations.of(
          context,
        )!.blockedUsersLoadFailed(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  DateTime? _parseOptionalDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _unblockUser(_BlockedUserEntry entry) async {
    if (_unblockingIds.contains(entry.userId)) {
      return;
    }

    setState(() {
      _unblockingIds.add(entry.userId);
    });

    try {
      await Supabase.instance.client
          .from('blocks')
          .delete()
          .eq('blocker_id', widget.currentUserId)
          .eq('blocked_user_id', entry.userId);

      if (!mounted) {
        return;
      }

      setState(() {
        _entries.removeWhere((item) => item.userId == entry.userId);
        _unblockingIds.remove(entry.userId);
        _changed = true;
      });

      widget.onBlockListChanged?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.blockedUserUnblocked),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _unblockingIds.remove(entry.userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.blockedUserUnblockFailed(error.toString()),
          ),
        ),
      );
    }
  }

  void _close() {
    Navigator.pop(context, _changed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.blockedUsersTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.commonReload,
                ),
                IconButton(
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                  tooltip: l10n.commonClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: Text(l10n.commonTryAgain),
                    ),
                  ],
                ),
              )
            else if (_entries.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.blockedUsersEmpty),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _entries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final displayName = (entry.nickname ?? '').trim().isEmpty
                        ? l10n.commonUser
                        : entry.nickname!.trim();
                    final showId = (entry.nickname ?? '').trim().isEmpty;
                    final subtitle = showId
                        ? l10n.blockedUserIdTruncated(_truncateId(entry.userId))
                        : null;
                    final isUnblocking = _unblockingIds.contains(entry.userId);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _buildAvatar(entry),
                      title: Text(displayName),
                      subtitle: subtitle == null ? null : Text(subtitle),
                      trailing: isUnblocking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => _unblockUser(entry),
                              child: Text(l10n.commonUnblock),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(_BlockedUserEntry entry) {
    final displayName = (entry.nickname ?? '').trim();
    final fallback = displayName.isNotEmpty ? displayName : entry.userId;
    return UserAvatar(
      avatar: entry.avatarUrl,
      fallbackText: fallback,
      size: 40,
    );
  }

  String _truncateId(String id) {
    if (id.length <= 12) {
      return id;
    }
    final start = id.substring(0, 6);
    final end = id.substring(id.length - 4);
    return '$start…$end';
  }
}

class _BlockedUserEntry {
  _BlockedUserEntry({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.createdAt,
  });

  final String userId;
  final String? nickname;
  final String? avatarUrl;
  final DateTime? createdAt;
}

class _ProfileInfo {
  _ProfileInfo({required this.nickname, required this.avatarUrl});

  final String? nickname;
  final String? avatarUrl;
}
