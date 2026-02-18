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

  Future<void> _showInviteCodeDialog(String code) async {
    final l10n = AppLocalizations.of(context)!;
    var showingCopiedPrompt = false;
    await showAppDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: l10n.roomInviteCodeTitle,
        message: l10n.roomInviteCodeMessage,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  if (showingCopiedPrompt) {
                    return;
                  }
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!mounted) {
                    return;
                  }
                  showingCopiedPrompt = true;
                  await _showInviteCopiedPremiumPopup(l10n);
                  showingCopiedPrompt = false;
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
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
          ],
        ),
        actions: [
          AppDialogAction.primary(
            label: l10n.commonClose,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteCopiedPremiumPopup(AppLocalizations l10n) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.commonClose,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, _) {
        final theme = Theme.of(dialogContext);
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.64),
                          const Color(0xFFEFF7FF).withValues(alpha: 0.52),
                          const Color(0xFFFFF2D8).withValues(alpha: 0.42),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.78),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 34,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFD58B), Color(0xFFFFB76A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFFB86A,
                                ).withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 28,
                            color: Color(0xFF7A3E00),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.roomInviteCodeCopiedTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: const Color(0xFF142033),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.roomInviteCodeCopiedMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF2D3C52),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2DBB91), Color(0xFF1E9F7A)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E9F7A,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                l10n.commonClose,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
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
        'regenerate_invite_code',
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.roomInviteCodeRegenerateFailed(
              userFacingError(context, error),
            ),
          ),
        ),
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
