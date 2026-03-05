import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_config/app_config_service.dart';
import '../../services/crash/crash_reporting_service.dart';

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

  ValueListenable<AppCrashSnapshot?> get listenable => _crash;

  void report({
    required Object error,
    required StackTrace stackTrace,
    required String source,
  }) {
    if (_crash.value != null) {
      return;
    }
    _crash.value = AppCrashSnapshot(
      error: error,
      stackTrace: stackTrace,
      source: source,
    );
  }

  @visibleForTesting
  void reset() {
    _crash.value = null;
  }
}

class CrashUpdateGuard extends StatefulWidget {
  const CrashUpdateGuard({super.key, required this.child});

  final Widget child;

  @override
  State<CrashUpdateGuard> createState() => _CrashUpdateGuardState();
}

class _CrashUpdateGuardState extends State<CrashUpdateGuard> {
  final AppConfigService _configService = AppConfigService();
  String? _storeUrl;
  bool _launchingStore = false;

  @override
  void initState() {
    super.initState();
    _primeStoreUrl();
  }

  Future<void> _primeStoreUrl() async {
    try {
      final config = await _configService.fetchForceUpdateConfig();
      if (!mounted || config == null) {
        return;
      }
      setState(() {
        _storeUrl = config.storeUrl;
      });
    } catch (_) {
      // Best effort. We'll retry fetch on update button tap.
    }
  }

  Future<void> _launchStore() async {
    if (_launchingStore) {
      return;
    }
    setState(() {
      _launchingStore = true;
    });
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'crash_update_guard',
        lastAction: 'tap_update_from_crash_screen',
      ),
    );
    try {
      final fallbackConfig = await _configService.fetchForceUpdateConfig();
      final url =
          _storeUrl ??
          fallbackConfig?.storeUrl ??
          AppConfigService.iosAppStoreUrl;
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _showLinkError();
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showLinkError();
      }
    } catch (error, stackTrace) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: stackTrace,
          source: 'crash_update_guard_launch_store',
          fatal: false,
        ),
      );
      _showLinkError();
    } finally {
      if (mounted) {
        setState(() {
          _launchingStore = false;
        });
      }
    }
  }

  void _showLinkError() {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.forceUpdateLinkError)));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppCrashSnapshot?>(
      valueListenable: AppCrashSignal.instance.listenable,
      builder: (context, crash, _) {
        if (crash == null) {
          return widget.child;
        }
        final l10n = AppLocalizations.of(context)!;
        final title = l10n.forceUpdateTitle;
        final message = l10n.forceUpdateMessage;
        final action = l10n.forceUpdateAction;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.system_update_alt, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _launchingStore ? null : _launchStore,
                      child: Text(action),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
