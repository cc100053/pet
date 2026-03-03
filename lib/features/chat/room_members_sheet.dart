import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/errors/user_facing_error.dart';
import '../../shared/ui/user_avatar.dart';

class RoomMembersSheet extends StatefulWidget {
  const RoomMembersSheet({
    super.key,
    required this.roomId,
    required this.currentUserId,
  });

  final String roomId;
  final String currentUserId;

  @override
  State<RoomMembersSheet> createState() => _RoomMembersSheetState();
}

class _RoomMembersSheetState extends State<RoomMembersSheet> {
  bool _loading = true;
  String? _error;
  final List<_RoomMemberEntry> _entries = [];

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
          .from('room_members')
          .select('user_id,role,joined_at')
          .eq('room_id', widget.roomId)
          .eq('is_active', true)
          .order('joined_at', ascending: true);

      final rows = response as List<dynamic>;
      final memberIds = <String>[];
      final roleByUserId = <String, String>{};
      for (final row in rows) {
        final userId = row['user_id'] as String?;
        if (userId == null || userId.isEmpty) {
          continue;
        }
        memberIds.add(userId);
        roleByUserId[userId] = (row['role'] as String?) ?? 'member';
      }

      if (memberIds.isEmpty) {
        _entries.clear();
        return;
      }

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('user_id,nickname,avatar_url')
          .filter('user_id', 'in', memberIds);

      final profileRows = profileResponse as List<dynamic>;
      final profileByUserId = <String, _ProfileInfo>{};
      for (final row in profileRows) {
        final userId = row['user_id'] as String?;
        if (userId == null || userId.isEmpty) {
          continue;
        }
        profileByUserId[userId] = _ProfileInfo(
          nickname: row['nickname'] as String?,
          avatarUrl: row['avatar_url'] as String?,
        );
      }

      _entries
        ..clear()
        ..addAll(
          memberIds.map((userId) {
            final profile = profileByUserId[userId];
            return _RoomMemberEntry(
              userId: userId,
              role: roleByUserId[userId] ?? 'member',
              nickname: profile?.nickname,
              avatarUrl: profile?.avatarUrl,
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
        )!.chatRoomMembersLoadFailed(userFacingError(context, error));
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _close() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                    l10n.chatRoomMembersTitle,
                    style: Theme.of(context).textTheme.titleLarge,
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.chatRoomMembersEmpty),
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
                    final fallback = displayName.isNotEmpty
                        ? displayName
                        : entry.userId;
                    final isOwner = entry.role.toLowerCase() == 'owner';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: UserAvatar(
                        avatar: entry.avatarUrl,
                        fallbackText: fallback,
                        size: 40,
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(displayName)),
                          if (isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l10n.chatRoomMemberRoleOwner,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: entry.userId == widget.currentUserId
                          ? Text(l10n.chatRoomMemberYou)
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomMemberEntry {
  const _RoomMemberEntry({
    required this.userId,
    required this.role,
    required this.nickname,
    required this.avatarUrl,
  });

  final String userId;
  final String role;
  final String? nickname;
  final String? avatarUrl;
}

class _ProfileInfo {
  const _ProfileInfo({required this.nickname, required this.avatarUrl});

  final String? nickname;
  final String? avatarUrl;
}
