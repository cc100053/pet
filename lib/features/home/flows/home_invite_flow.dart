part of '../home_view.dart';

extension _HomeInviteFlow on _HomeViewState {
  Future<void> _showRoomLockedDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.roomLockedTitle,
        message: l10n.roomLockedMessage,
        actions: [
          AppDialogAction.primary(
            label: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowNewRoomInvitePrompt {
    final roomId = _roomId;
    if (roomId == null) {
      return false;
    }
    if (!_showNewRoomInvitePrompt) {
      return false;
    }
    if (_newRoomInviteRoomId != roomId) {
      return false;
    }
    return _isSoloRoom;
  }

  String? _extractInviteCode(dynamic response) {
    if (response is String) {
      return response;
    }
    if (response is Map) {
      final value = response.values.isNotEmpty ? response.values.first : null;
      if (value is String) {
        return value;
      }
    }
    if (response is List && response.isNotEmpty) {
      final value = response.first;
      if (value is String) {
        return value;
      }
      if (value is Map) {
        final inner = value.values.isNotEmpty ? value.values.first : null;
        if (inner is String) {
          return inner;
        }
      }
    }
    return null;
  }

  List<String> _extractInviteCodes(dynamic response) {
    final codes = <String>{};
    if (response is List) {
      for (final entry in response) {
        if (entry is String) {
          final trimmed = entry.trim();
          if (trimmed.isNotEmpty) {
            codes.add(trimmed);
          }
          continue;
        }
        if (entry is Map) {
          final value = entry['code'];
          if (value is String) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              codes.add(trimmed);
            }
          }
        }
      }
    } else if (response is Map) {
      final value = response['code'];
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          codes.add(trimmed);
        }
      }
    } else if (response is String) {
      final trimmed = response.trim();
      if (trimmed.isNotEmpty) {
        codes.add(trimmed);
      }
    }
    return codes.toList(growable: false);
  }

  Future<List<String>> _fetchActiveInviteCodes(String roomId) async {
    final response = await Supabase.instance.client.rpc(
      'list_room_invite_codes',
      params: {'p_room_id': roomId},
    );
    final codes = _extractInviteCodes(response);
    if (codes.length <= 1) {
      return codes;
    }
    return codes.take(3).toList(growable: false);
  }

  bool _isInviteCodeLimitReachedError(Object error) {
    return error.toString().toLowerCase().contains('invite_code_limit_reached');
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    showJuiceSnackbar(
      context: context,
      message: l10n.roomInviteCodeCopiedMessage,
      tone: AppDialogTone.success,
    );
  }

  Future<void> _shareInviteCode(String code) async {
    final l10n = AppLocalizations.of(context)!;
    final displayCode = AppInviteLinkService.normalizeInviteCode(code);
    if (displayCode == null) {
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: AppInviteLinkService.shareText(
            caption: l10n.roomInviteShareCaption,
            code: displayCode,
          ),
          title: l10n.roomInviteCodeTitle,
          subject: l10n.roomInviteCodeTitle,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: l10n.roomInviteShareFailed(userFacingError(context, error)),
        tone: AppDialogTone.danger,
      );
    }
  }

  Future<void> _showInviteCodeDialog(String code) async {
    final l10n = AppLocalizations.of(context)!;
    var showingCopiedPrompt = false;
    final displayCode = AppInviteLinkService.normalizeInviteCode(code);
    if (displayCode == null) {
      return;
    }
    showJuiceToast(
      context: context,
      message: l10n.roomInviteCodeTitle,
      position: JuicePosition.center,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.roomInviteCodeMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          JuicyScaleButton(
            onTap: () {
              unawaited(() async {
                if (showingCopiedPrompt) {
                  return;
                }
                showingCopiedPrompt = true;
                try {
                  await _copyInviteCode(displayCode);
                } finally {
                  showingCopiedPrompt = false;
                }
              }());
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black87, width: 1.5),
              ),
              child: Center(
                child: Text(
                  displayCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.roomInviteCodeTapHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: JuicyScaleButton(
                  onTap: () {
                    unawaited(() async {
                      if (showingCopiedPrompt) {
                        return;
                      }
                      showingCopiedPrompt = true;
                      try {
                        await _copyInviteCode(displayCode);
                      } finally {
                        showingCopiedPrompt = false;
                      }
                    }());
                  },
                  child: _InviteActionButton(
                    icon: Icons.copy_rounded,
                    label: l10n.roomInviteCopyCodeAction,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: JuicyScaleButton(
                  onTap: () {
                    unawaited(_shareInviteCode(displayCode));
                  },
                  child: _InviteActionButton(
                    icon: Icons.ios_share_rounded,
                    label: l10n.roomInviteShareAction,
                    backgroundColor: const Color(0xFFFFD600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actionLabel: l10n.commonClose,
    );
  }

  Future<void> _generateInviteCode() async {
    if (_inviteCodeLoading) {
      return;
    }
    final roomId = _roomId;
    if (roomId == null) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _setInviteCodeLoading(true);
    try {
      final response = await Supabase.instance.client.rpc(
        'get_or_create_room_invite_code',
        params: {'p_room_id': roomId},
      );
      final code = _extractInviteCode(response);
      if (code == null || code.isEmpty) {
        throw Exception('invite_code_missing');
      }
      if (!mounted) {
        return;
      }
      _applyGeneratedInviteCode(roomId: roomId, code: code);
      await _showInviteCodeDialog(code);
    } catch (error) {
      if (_isInviteCodeLimitReachedError(error)) {
        try {
          final codes = await _fetchActiveInviteCodes(roomId);
          if (codes.isNotEmpty && mounted) {
            await _showInviteCodeDialog(codes.first);
            return;
          }
        } catch (_) {}
      }
      if (!mounted) {
        return;
      }
      showJuiceToast(
        context: context,
        message: l10n.roomInviteCodeRegenerateFailed(
          userFacingError(context, error),
        ),
        tone: AppDialogTone.danger,
      );
    } finally {
      if (mounted) {
        _setInviteCodeLoading(false);
      }
    }
  }

  void _dismissNewRoomInvitePrompt() {
    _dismissNewRoomInvitePromptState();
  }

  Widget _buildNewRoomInvitePrompt() {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedScale(
      scale: _shouldShowNewRoomInvitePrompt ? 1 : 0.96,
      duration: 220.ms,
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: _shouldShowNewRoomInvitePrompt ? 1 : 0,
        duration: 180.ms,
        curve: Curves.easeOut,
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black87, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.roomInvitePromptTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissNewRoomInvitePrompt,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                l10n.roomInvitePromptBody,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
              const Gap(10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _inviteCodeLoading ? null : _generateInviteCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _inviteCodeLoading
                        ? l10n.roomInvitePromptGenerating
                        : l10n.roomInvitePromptAction,
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

class _InviteActionButton extends StatelessWidget {
  const _InviteActionButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black),
          const Gap(6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.mPlusRounded1c(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
