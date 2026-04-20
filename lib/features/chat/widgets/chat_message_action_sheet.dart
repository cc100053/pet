import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

enum ChatMessageActionSheetAlignment { left, right }

class ChatMessageActionSheetAnchor {
  const ChatMessageActionSheetAnchor({
    required this.messageRect,
    required this.touchPosition,
    required this.alignment,
    required this.safePadding,
  });

  final Rect messageRect;
  final Offset touchPosition;
  final ChatMessageActionSheetAlignment alignment;
  final EdgeInsets safePadding;
}

class ChatMessageActionSheet extends StatelessWidget {
  const ChatMessageActionSheet({
    super.key,
    required this.anchor,
    required this.preview,
    required this.reactionOptions,
    required this.selectedReaction,
    required this.copyEnabled,
    required this.editEnabled,
    required this.deleteEnabled,
    required this.isMine,
    required this.isBlocked,
    required this.onReactionSelected,
    required this.onReply,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
    required this.onMoreReactions,
  });

  final ChatMessageActionSheetAnchor anchor;
  final Widget preview;
  final List<String> reactionOptions;
  final String? selectedReaction;
  final bool copyEnabled;
  final bool editEnabled;
  final bool deleteEnabled;
  final bool isMine;
  final bool isBlocked;
  final ValueChanged<String> onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onBlock;
  final VoidCallback onMoreReactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routeAnimation = ModalRoute.of(context)?.animation;
    final animation = CurvedAnimation(
      parent: routeAnimation ?? const AlwaysStoppedAnimation<double>(1),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubicEmphasized,
    );
    final backdropAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutQuart),
      reverseCurve: const Interval(0.0, 1.0, curve: Curves.easeInOutCubic),
    );
    final railAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.12, 0.9, curve: Curves.easeOutQuart),
      reverseCurve: const Interval(0.0, 0.78, curve: Curves.easeInOutCubic),
    );
    final previewAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.18, 0.94, curve: Curves.easeOutQuart),
      reverseCurve: const Interval(0.0, 0.84, curve: Curves.easeInOutCubic),
    );
    final cardAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.24, 1.0, curve: Curves.easeOutQuart),
      reverseCurve: const Interval(0.0, 0.9, curve: Curves.easeInOutCubic),
    );

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        backdropAnimation,
        railAnimation,
        previewAnimation,
        cardAnimation,
      ]),
      builder: (context, _) {
        final backdropProgress = backdropAnimation.value.clamp(0.0, 1.0);
        final railProgress = railAnimation.value.clamp(0.0, 1.0);
        final previewProgress = previewAnimation.value.clamp(0.0, 1.0);
        final cardProgress = cardAnimation.value.clamp(0.0, 1.0);
        final backdropOpacity = 0.14 * backdropProgress;

        return Material(
          color: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const outerMargin = 12.0;
              const railHeightEstimate = 56.0;
              const railToPreviewGap = 10.0;
              const previewToActionsGap = 12.0;
              final size = constraints.biggest;
              final safeTop = anchor.safePadding.top + outerMargin;
              final safeBottom = anchor.safePadding.bottom + outerMargin;
              final previewWidth = anchor.messageRect.width.clamp(
                140.0,
                size.width - (outerMargin * 2),
              );
              final minimumRailWidth = (reactionOptions.length * 48) + 88.0;
              final railWidth = math
                  .min(
                    size.width - (outerMargin * 2),
                    math.max(previewWidth + 24, minimumRailWidth),
                  )
                  .toDouble();
              final actionCardWidth = math
                  .min(
                    size.width - (outerMargin * 2),
                    math.max(previewWidth, 220),
                  )
                  .toDouble();
              final previewLeft = _anchoredLeft(
                containerWidth: previewWidth,
                viewportWidth: size.width,
                outerMargin: outerMargin,
              );
              final railLeft = _anchoredLeft(
                containerWidth: railWidth,
                viewportWidth: size.width,
                outerMargin: outerMargin,
              );
              final actionCardLeft = _anchoredLeft(
                containerWidth: actionCardWidth,
                viewportWidth: size.width,
                outerMargin: outerMargin,
              );
              final actionCount =
                  2 +
                  (editEnabled ? 1 : 0) +
                  (deleteEnabled ? 1 : 0) +
                  (isMine ? 0 : 2);
              final estimatedActionHeight = 20 + (actionCount * 56);
              final estimatedTotalHeight =
                  railHeightEstimate +
                  railToPreviewGap +
                  anchor.messageRect.height +
                  previewToActionsGap +
                  estimatedActionHeight;
              final top =
                  (anchor.messageRect.top -
                          railHeightEstimate -
                          railToPreviewGap)
                      .clamp(
                        safeTop,
                        math.max(
                          safeTop,
                          size.height - safeBottom - estimatedTotalHeight,
                        ),
                      )
                      .toDouble();
              final previewTop = top + railHeightEstimate + railToPreviewGap;
              final actionTop =
                  previewTop + anchor.messageRect.height + previewToActionsGap;

              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      key: const ValueKey('chatMessageActionOverlayBackdrop'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: DecoratedBox(
                        key: const ValueKey('chatMessageActionOverlayScrim'),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: backdropOpacity,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: railLeft,
                    top: top - ((1 - railProgress) * 6),
                    width: railWidth,
                    child: Opacity(
                      opacity: railProgress,
                      child: _GlassCapsule(
                        key: const ValueKey(
                          'chatMessageActionSheetReactionRail',
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final emoji in reactionOptions)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: _ReactionChip(
                                    emoji: emoji,
                                    isSelected: selectedReaction == emoji,
                                    onTap: () => onReactionSelected(emoji),
                                  ),
                                ),
                              _MoreReactionsChip(
                                onTap: onMoreReactions,
                                label: l10n.chatMoreReactionsAction,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: previewLeft,
                    top: previewTop - ((1 - previewProgress) * 3),
                    width: previewWidth,
                    child: Opacity(
                      opacity: previewProgress,
                      child: IgnorePointer(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: anchor.messageRect.height,
                          ),
                          child: KeyedSubtree(
                            key: const ValueKey(
                              'chatMessageActionSheetPreview',
                            ),
                            child: preview,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: actionCardLeft,
                    top: actionTop + ((1 - cardProgress) * 6),
                    width: actionCardWidth,
                    child: Opacity(
                      opacity: cardProgress,
                      child: _GlassActionCard(
                        key: const ValueKey(
                          'chatMessageActionSheetOptionsCard',
                        ),
                        children: [
                          _ActionRow(
                            icon: Icons.reply_rounded,
                            label: l10n.chatReplyAction,
                            onTap: onReply,
                          ),
                          _ActionRow(
                            icon: Icons.content_copy_rounded,
                            label: l10n.chatCopyAction,
                            enabled: copyEnabled,
                            onTap: copyEnabled ? onCopy : null,
                          ),
                          if (editEnabled)
                            _ActionRow(
                              icon: Icons.edit_rounded,
                              label: l10n.chatEditAction,
                              onTap: onEdit,
                            ),
                          if (deleteEnabled)
                            _ActionRow(
                              icon: Icons.delete_outline_rounded,
                              label: l10n.chatDeleteAction,
                              onTap: onDelete,
                            ),
                          if (!isMine)
                            _ActionRow(
                              icon: Icons.report_gmailerrorred_outlined,
                              label: l10n.chatReportMessageTitle,
                              onTap: onReport,
                            ),
                          if (!isMine)
                            _ActionRow(
                              icon: Icons.block_rounded,
                              label: isBlocked
                                  ? l10n.chatUserAlreadyBlocked
                                  : l10n.chatBlockUser,
                              enabled: !isBlocked,
                              onTap: isBlocked ? null : onBlock,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _anchoredLeft({
    required double containerWidth,
    required double viewportWidth,
    required double outerMargin,
  }) {
    final rawLeft = switch (anchor.alignment) {
      ChatMessageActionSheetAlignment.left => anchor.messageRect.left,
      ChatMessageActionSheetAlignment.right =>
        anchor.messageRect.right - containerWidth,
    };
    return rawLeft.clamp(
      outerMargin,
      math.max(outerMargin, viewportWidth - containerWidth - outerMargin),
    );
  }
}

class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({
    super.key,
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: borderRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _GlassActionCard extends StatelessWidget {
  const _GlassActionCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                  )
                : null,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}

class _MoreReactionsChip extends StatelessWidget {
  const _MoreReactionsChip({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('chatMessageActionSheetMoreReactions'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64, minHeight: 40),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? AppTheme.textPrimary
        : AppTheme.textSecondary.withValues(alpha: 0.56);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
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
