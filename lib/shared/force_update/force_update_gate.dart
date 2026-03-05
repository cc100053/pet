import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/app_config/app_config_service.dart';
import '../../services/crash/crash_reporting_service.dart';
import '../ui/app_dialog.dart';
import 'force_update_debug_tool.dart';
import 'update_policy.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  final AppConfigService _configService = AppConfigService();
  StreamSubscription<ForceUpdateDebugPromptType>? _debugPromptSubscription;

  bool _checking = true;
  bool _hardUpdateRequired = false;
  bool _dialogShowing = false;
  String? _skippedSoftUpdateVersion;
  ForceUpdateConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _debugPromptSubscription = ForceUpdateDebugTool.instance.prompts.listen(
      _onDebugPromptRequested,
    );
    _checkForUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debugPromptSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'force_update_gate',
        lastAction: 'check_for_update',
      ),
    );
    if (mounted) {
      setState(() {
        _checking = true;
      });
    }

    try {
      final config = await _configService.fetchForceUpdateConfig();
      if (!mounted) {
        return;
      }
      if (config == null) {
        setState(() {
          _checking = false;
          _hardUpdateRequired = false;
          _config = null;
        });
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final requirement = AppUpdatePolicy.evaluate(
        currentVersion: currentVersion,
        minimumRequiredVersion: config.minimumRequiredVersion,
        latestAvailableVersion: config.latestAvailableVersion,
      );
      final requiresHardUpdate = requirement == AppUpdateRequirement.hard;

      setState(() {
        _checking = false;
        _hardUpdateRequired = requiresHardUpdate;
        _config = config;
      });

      if (requiresHardUpdate) {
        AnalyticsService.instance.logEvent(
          'force_update_required',
          parameters: {
            'min_version': config.minimumRequiredVersion,
            'latest_version': config.latestAvailableVersion,
            'current_version': currentVersion,
          },
        );
        _showHardUpdateDialog(config);
        return;
      }

      if (requirement == AppUpdateRequirement.soft &&
          _skippedSoftUpdateVersion != config.latestAvailableVersion) {
        AnalyticsService.instance.logEvent(
          'soft_update_available',
          parameters: {
            'latest_version': config.latestAvailableVersion,
            'current_version': currentVersion,
          },
        );
        _showSoftUpdateDialog(config);
      }
    } catch (error, stackTrace) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: stackTrace,
          source: 'force_update_check',
          fatal: false,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
        _hardUpdateRequired = false;
      });
    }
  }

  Future<void> _onDebugPromptRequested(ForceUpdateDebugPromptType type) async {
    if (!mounted) {
      return;
    }
    final debugConfig = ForceUpdateConfig(
      minimumRequiredVersion: _config?.minimumRequiredVersion ?? '999.0.0',
      latestAvailableVersion: _config?.latestAvailableVersion ?? '999.0.1',
      storeUrl: _config?.storeUrl ?? AppConfigService.iosAppStoreUrl,
    );
    if (type == ForceUpdateDebugPromptType.hard) {
      AnalyticsService.instance.logEvent('debug_hard_update_prompt_shown');
      unawaited(
        CrashReportingService.instance.setContext(
          feature: 'force_update_gate',
          lastAction: 'show_debug_hard_update_prompt',
        ),
      );
      await _showHardUpdateDialog(debugConfig);
      return;
    }
    AnalyticsService.instance.logEvent('debug_soft_update_prompt_shown');
    unawaited(
      CrashReportingService.instance.setContext(
        feature: 'force_update_gate',
        lastAction: 'show_debug_soft_update_prompt',
      ),
    );
    await _showSoftUpdateDialog(debugConfig);
  }

  Future<void> _showHardUpdateDialog(ForceUpdateConfig config) async {
    if (_dialogShowing) {
      return;
    }
    _dialogShowing = true;
    await showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AppDialog(
          tone: AppDialogTone.info,
          title: AppLocalizations.of(context)!.forceUpdateTitle,
          message:
              config.hardUpdateMessage ??
              AppLocalizations.of(context)!.forceUpdateMessage,
          actions: [
            AppDialogAction.primary(
              label: AppLocalizations.of(context)!.forceUpdateAction,
              onPressed: () {
                unawaited(
                  CrashReportingService.instance.setContext(
                    feature: 'force_update_gate',
                    lastAction: 'tap_hard_update',
                  ),
                );
                AnalyticsService.instance.logEvent(
                  'force_update_tap_update',
                  parameters: {
                    'min_version': config.minimumRequiredVersion,
                    'latest_version': config.latestAvailableVersion,
                  },
                );
                Navigator.of(context).pop();
                _launchStore(config.storeUrl);
              },
            ),
          ],
        ),
      ),
    );
    _dialogShowing = false;
  }

  Future<void> _showSoftUpdateDialog(ForceUpdateConfig config) async {
    if (_dialogShowing) {
      return;
    }
    _dialogShowing = true;
    await showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        tone: AppDialogTone.info,
        title: AppLocalizations.of(context)!.softUpdateTitle,
        message:
            config.softUpdateMessage ??
            AppLocalizations.of(context)!.softUpdateMessage,
        actions: [
          AppDialogAction.secondary(
            label: AppLocalizations.of(context)!.softUpdateLater,
            onPressed: () {
              _skippedSoftUpdateVersion = config.latestAvailableVersion;
              Navigator.of(context).pop();
              unawaited(
                CrashReportingService.instance.setContext(
                  feature: 'force_update_gate',
                  lastAction: 'tap_soft_update_later',
                ),
              );
              AnalyticsService.instance.logEvent(
                'soft_update_tap_later',
                parameters: {'latest_version': config.latestAvailableVersion},
              );
            },
          ),
          AppDialogAction.primary(
            label: AppLocalizations.of(context)!.softUpdateAction,
            onPressed: () {
              _skippedSoftUpdateVersion = config.latestAvailableVersion;
              Navigator.of(context).pop();
              unawaited(
                CrashReportingService.instance.setContext(
                  feature: 'force_update_gate',
                  lastAction: 'tap_soft_update',
                ),
              );
              AnalyticsService.instance.logEvent(
                'soft_update_tap_update',
                parameters: {'latest_version': config.latestAvailableVersion},
              );
              _launchStore(config.storeUrl);
            },
          ),
        ],
      ),
    );
    _dialogShowing = false;
  }

  Future<void> _launchStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.forceUpdateLinkError),
          ),
        );
      }
    } catch (error, stackTrace) {
      unawaited(
        CrashReportingService.instance.reportError(
          error: error,
          stackTrace: stackTrace,
          source: 'force_update_launch_store',
          fatal: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_hardUpdateRequired || _config == null) {
      return widget.child;
    }

    return ForceUpdateScreen(
      config: _config!,
      onUpdate: () => _launchStore(_config!.storeUrl),
    );
  }
}

class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.config,
    required this.onUpdate,
  });

  final ForceUpdateConfig config;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n.forceUpdateTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                config.hardUpdateMessage ?? l10n.forceUpdateMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onUpdate,
                child: Text(l10n.forceUpdateAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
