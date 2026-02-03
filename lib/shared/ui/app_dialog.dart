import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
