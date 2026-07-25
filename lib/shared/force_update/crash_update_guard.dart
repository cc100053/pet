import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../services/crash/crash_reporting_service.dart';
import '../theme/app_theme.dart';

const String _crashRecoveryPetAsset = 'assets/pet/ghost/ghost_stay.gif';

class AppCrashSnapshot {
  const AppCrashSnapshot({
    required this.error,
    required this.stackTrace,
    required this.source,
  });

  final Object error;
  final StackTrace stackTrace;
  final String source;
}

class AppCrashSignal {
  AppCrashSignal._();

  static final AppCrashSignal instance = AppCrashSignal._();

  final ValueNotifier<AppCrashSnapshot?> _crash = ValueNotifier(null);
  AppCrashSnapshot? _pending;

  ValueListenable<AppCrashSnapshot?> get listenable => _crash;

  void report({
    required Object error,
    required StackTrace stackTrace,
    required String source,
  }) {
    if (!CrashReportingService.shouldRecordAsFatal(
      error,
      requestedFatal: true,
    )) {
      return;
    }
    // De-dupe against both the active crash and a deferred one still pending.
    if (_crash.value != null || _pending != null) {
      return;
    }
    final snapshot = AppCrashSnapshot(
      error: error,
      stackTrace: stackTrace,
      source: source,
    );
    // This is frequently invoked from ErrorWidget.builder / FlutterError.onError,
    // which run *during* a build/layout pass. Mutating the notifier there would
    // swap the live subtree for the recovery screen in the wrong build scope —
    // tearing down LayoutBuilder children mid-frame trips InheritedElement's
    // `_dependents.isEmpty` assertion. Defer the swap to a clean post-frame.
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle) {
      _crash.value = snapshot;
      return;
    }
    _pending = snapshot;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final next = _pending;
      _pending = null;
      if (next != null && _crash.value == null) {
        _crash.value = next;
      }
    });
  }

  void clear() {
    _pending = null;
    _crash.value = null;
  }

  @visibleForTesting
  void reset() {
    clear();
  }
}

class CrashUpdateGuard extends StatelessWidget {
  const CrashUpdateGuard({super.key, required this.child});

  final Widget child;

  void _acknowledgeCrash() {
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'crash_update_guard',
        lastAction: 'tap_crash_recovery_acknowledge',
      ),
    );
    AppCrashSignal.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppCrashSnapshot?>(
      valueListenable: AppCrashSignal.instance.listenable,
      builder: (context, crash, _) {
        if (crash == null) {
          return child;
        }
        final l10n = AppLocalizations.of(context)!;
        return _CrashRecoveryScreen(
          title: l10n.crashRecoveryTitle,
          message: l10n.crashRecoveryMessage,
          petCaption: l10n.crashRecoveryPetCaption,
          petSemanticLabel: l10n.crashRecoveryPetSemanticLabel,
          actionLabel: l10n.crashRecoveryAction,
          onAcknowledge: _acknowledgeCrash,
        );
      },
    );
  }
}

class _CrashRecoveryScreen extends StatelessWidget {
  const _CrashRecoveryScreen({
    required this.title,
    required this.message,
    required this.petCaption,
    required this.petSemanticLabel,
    required this.actionLabel,
    required this.onAcknowledge,
  });

  final String title;
  final String message;
  final String petCaption;
  final String petSemanticLabel;
  final String actionLabel;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 56
                      ? constraints.maxHeight - 56
                      : 0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE6E0D6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _CrashPetStage(
                              caption: petCaption,
                              semanticLabel: petSemanticLabel,
                            ),
                            const SizedBox(height: 22),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.55,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: onAcknowledge,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(actionLabel),
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
        ),
      ),
    );
  }
}

class _CrashPetStage extends StatelessWidget {
  const _CrashPetStage({required this.caption, required this.semanticLabel});

  final String caption;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9F8F1), Color(0xFFFFE4C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          children: [
            Semantics(
              image: true,
              label: semanticLabel,
              child: Image.asset(
                _crashRecoveryPetAsset,
                height: 112,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 112,
                    child: Icon(
                      Icons.pets_rounded,
                      size: 72,
                      color: AppTheme.primaryColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              caption,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
