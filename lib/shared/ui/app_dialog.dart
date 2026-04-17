import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'juice_wrappers.dart';

enum AppDialogTone {
  info,
  success,
  warning,
  danger,
}

enum AppDialogActionStyle {
  primary,
  secondary,
  destructive,
  ghost,
}

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.style = AppDialogActionStyle.primary,
  });

  const AppDialogAction.primary({
    required this.label,
    required this.onPressed,
  }) : style = AppDialogActionStyle.primary;

  const AppDialogAction.secondary({
    required this.label,
    required this.onPressed,
  }) : style = AppDialogActionStyle.secondary;

  const AppDialogAction.destructive({
    required this.label,
    required this.onPressed,
  }) : style = AppDialogActionStyle.destructive;

  const AppDialogAction.ghost({
    required this.label,
    required this.onPressed,
  }) : style = AppDialogActionStyle.ghost;

  final String label;
  final VoidCallback? onPressed;
  final AppDialogActionStyle style;
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: builder,
  );
}

enum JuicePosition {
  top,
  center,
  bottom,
}

/// A soft, game-style floating UI component that can appear at different positions.
void showJuiceToast({
  required BuildContext context,
  String? message,
  Widget? body,
  AppDialogTone tone = AppDialogTone.info,
  JuicePosition position = JuicePosition.bottom,
  String? actionLabel,
  VoidCallback? onActionPressed,
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context);
  final toneStyle = _toneStyle(theme, tone);
  final accent = toneStyle.accent;

  showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'JuiceToast',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );

      final alignment = switch (position) {
        JuicePosition.top => Alignment.topCenter,
        JuicePosition.center => Alignment.center,
        JuicePosition.bottom => Alignment.bottomCenter,
      };

      final padding = switch (position) {
        JuicePosition.top => const EdgeInsets.fromLTRB(24, 60, 24, 0),
        JuicePosition.center => const EdgeInsets.symmetric(horizontal: 24),
        JuicePosition.bottom => const EdgeInsets.fromLTRB(24, 0, 24, 60),
      };

      final slideTween = switch (position) {
        JuicePosition.top => Tween<Offset>(
            begin: const Offset(0, -1.5),
            end: Offset.zero,
          ),
        JuicePosition.center => Tween<Offset>(
            begin: const Offset(0, 0.05), // Slight nudge
            end: Offset.zero,
          ),
        JuicePosition.bottom => Tween<Offset>(
            begin: const Offset(0, 1.5),
            end: Offset.zero,
          ),
      };

      Widget content = Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Colored bottom shadow/accent
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                bottom: -8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              // Main card
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFFFF7EA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Circular Icon Area with Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    accent.withValues(alpha: 0.22),
                                    accent.withValues(alpha: 0.38),
                                  ],
                                ),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  toneStyle.icon,
                                  color: accent,
                                  size: 28,
                                ),
                              ),
                            ),
                            // Top-left Badge
                            Positioned(
                              top: -4,
                              left: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.priority_high,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(4),
                              if (message != null)
                                Text(
                                  message,
                                  style: GoogleFonts.mPlusRounded1c(
                                    color: accent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                              if (body != null) ...[
                                if (message != null) const Gap(12),
                                body,
                              ],
                            ],
                          ),
                        ),
                        // Close button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: accent.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (actionLabel != null) ...[
                      const Gap(16),
                      JuicyScaleButton(
                        onTap: () {
                          Navigator.of(context).pop();
                          onActionPressed?.call();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600), // Pop Yellow
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                offset: const Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              actionLabel,
                              style: GoogleFonts.mPlusRounded1c(
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      return Align(
        alignment: alignment,
        child: Padding(
          padding: padding,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slideTween.animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
                child: content,
              ),
            ),
          ),
        ),
      );
    },
  );
}
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.body,
    this.actions = const <AppDialogAction>[],
    this.tone = AppDialogTone.info,
    this.leading,
  });

  final String title;
  final String? message;
  final Widget? body;
  final List<AppDialogAction> actions;
  final AppDialogTone tone;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toneStyle = _toneStyle(theme, tone);
    final accent = toneStyle.accent;
    final accentSoft = accent.withValues(alpha: 0.12);
    final outline = theme.colorScheme.outlineVariant.withValues(alpha: 0.45);
    final cardColor = theme.colorScheme.surface.withValues(alpha: 0.92);

    final icon = leading ??
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: accentSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(toneStyle.icon, color: accent),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: outline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.white, 0.35)!,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (message != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      message!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (body != null) ...[
                          const SizedBox(height: 16),
                          body!,
                        ],
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _DialogActions(actions: actions, accent: accent),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.actions, required this.accent});

  final List<AppDialogAction> actions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return switch (action.style) {
            AppDialogActionStyle.primary => FilledButton(
                onPressed: action.onPressed,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: Text(action.label),
              ),
            AppDialogActionStyle.destructive => FilledButton(
                onPressed: action.onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                child: Text(action.label),
              ),
            AppDialogActionStyle.secondary => OutlinedButton(
                onPressed: action.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                child: Text(action.label),
              ),
            AppDialogActionStyle.ghost => TextButton(
                onPressed: action.onPressed,
                child: Text(action.label),
              ),
          };
        }).toList(),
      ),
    );
  }
}

class _ToneStyle {
  const _ToneStyle({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;
}

_ToneStyle _toneStyle(ThemeData theme, AppDialogTone tone) {
  return switch (tone) {
    AppDialogTone.info => _ToneStyle(
        icon: Icons.stars_rounded,
        accent: AppTheme.primaryColor,
      ),
    AppDialogTone.success => _ToneStyle(
        icon: Icons.check_circle_rounded,
        accent: AppTheme.successColor,
      ),
    AppDialogTone.warning => _ToneStyle(
        icon: Icons.warning_rounded,
        accent: AppTheme.secondaryColor,
      ),
    AppDialogTone.danger => _ToneStyle(
        icon: Icons.error_rounded,
        accent: theme.colorScheme.error,
      ),
  };
}
