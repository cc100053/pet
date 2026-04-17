import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/app_config/app_config_service.dart';
import '../../services/crash/crash_reporting_service.dart';
import '../../shared/ui/app_dialog.dart';
import '../whats_new/app_whats_new_catalog.dart';
import '../whats_new/app_whats_new_entry.dart';
import '../whats_new/whats_new_dialog.dart';
import '../whats_new/whats_new_policy.dart';
import '../whats_new/whats_new_service.dart';
import 'force_update_debug_tool.dart';
import 'update_policy.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({
    super.key,
    required this.child,
    AppConfigService? configService,
    WhatsNewService? whatsNewService,
    Future<AppLaunchInfo> Function()? launchInfoLoader,
  }) : _configService = configService,
       _whatsNewService = whatsNewService,
       _launchInfoLoader = launchInfoLoader;

  final Widget child;
  final AppConfigService? _configService;
  final WhatsNewService? _whatsNewService;
  final Future<AppLaunchInfo> Function()? _launchInfoLoader;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  StreamSubscription<ForceUpdateDebugPromptType>? _debugPromptSubscription;
  late final AppConfigService _configService;
  late final WhatsNewService _whatsNewService;
  late final Future<AppLaunchInfo> Function() _launchInfoLoader;

  bool _checking = true;
  bool _hardUpdateRequired = false;
  bool _dialogShowing = false;
  String? _skippedSoftUpdateVersion;
  ForceUpdateConfig? _config;

  @override
  void initState() {
    super.initState();
    _configService = widget._configService ?? AppConfigService();
    _whatsNewService = widget._whatsNewService ?? WhatsNewService();
    _launchInfoLoader =
        widget._launchInfoLoader ??
        () async =>
            AppLaunchInfo.fromPackageInfo(await PackageInfo.fromPlatform());
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
      _setCrashContextSafe(
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
      final launchInfo = await _launchInfoLoader();
      final currentVersion = launchInfo.version;
      final whatsNewDecision = await _whatsNewService.prepareForLaunch(
        currentVersion: currentVersion,
        currentReleaseSignature: launchInfo.releaseSignature,
      );
      if (!mounted) {
        return;
      }
      if (config == null) {
        setState(() {
          _checking = false;
          _hardUpdateRequired = false;
          _config = null;
        });
        await _maybeShowWhatsNewDialog(whatsNewDecision);
        return;
      }

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
        unawaited(
          _logEventSafe(
            'force_update_required',
            parameters: {
              'min_version': config.minimumRequiredVersion,
              'latest_version': config.latestAvailableVersion,
              'current_version': currentVersion,
            },
          ),
        );
        _showHardUpdateDialog(config);
        return;
      }

      if (requirement == AppUpdateRequirement.soft &&
          _skippedSoftUpdateVersion != config.latestAvailableVersion) {
        unawaited(
          _logEventSafe(
            'soft_update_available',
            parameters: {
              'latest_version': config.latestAvailableVersion,
              'current_version': currentVersion,
            },
          ),
        );
        await _showSoftUpdateDialog(config);
        await _maybeShowWhatsNewDialog(whatsNewDecision);
        return;
      }

      await _maybeShowWhatsNewDialog(whatsNewDecision);
    } catch (error, stackTrace) {
      unawaited(
        _reportErrorSafe(
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
      unawaited(_logEventSafe('debug_hard_update_prompt_shown'));
      unawaited(
        _setCrashContextSafe(
          feature: 'force_update_gate',
          lastAction: 'show_debug_hard_update_prompt',
        ),
      );
      await _showHardUpdateDialog(debugConfig);
      return;
    }
    if (type == ForceUpdateDebugPromptType.whatsNew) {
      await _showDebugWhatsNewPrompt();
      return;
    }
    unawaited(_logEventSafe('debug_soft_update_prompt_shown'));
    unawaited(
      _setCrashContextSafe(
        feature: 'force_update_gate',
        lastAction: 'show_debug_soft_update_prompt',
      ),
    );
    await _showSoftUpdateDialog(debugConfig);
  }

  Future<void> _maybeShowWhatsNewDialog(WhatsNewDecision decision) async {
    if (!decision.shouldShow || decision.entry == null) {
      return;
    }
    await _showWhatsNewDialog(
      version: decision.currentVersion,
      releaseSignature: decision.currentReleaseSignature,
      entry: decision.entry!,
      markShown: true,
      shownEventName: 'whats_new_shown',
      dismissedEventName: 'whats_new_dismissed',
    );
  }

  Future<void> _showDebugWhatsNewPrompt() async {
    final launchInfo = await _launchInfoLoader();
    final entry = AppWhatsNewCatalog.entryForVersion(launchInfo.version);
    if (entry == null) {
      return;
    }
    await _showWhatsNewDialog(
      version: launchInfo.version,
      releaseSignature: launchInfo.releaseSignature,
      entry: entry,
      markShown: false,
      shownEventName: 'debug_whats_new_shown',
      dismissedEventName: 'debug_whats_new_dismissed',
    );
  }

  Future<void> _showWhatsNewDialog({
    required String version,
    required String releaseSignature,
    required AppWhatsNewEntry entry,
    required bool markShown,
    required String shownEventName,
    required String dismissedEventName,
  }) async {
    if (_dialogShowing) {
      return;
    }
    if (!mounted) {
      return;
    }
    _dialogShowing = true;
    try {
      unawaited(
        _logEventSafe(shownEventName, parameters: {'version': version}),
      );
      await showAppDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => WhatsNewDialog(version: version, entry: entry),
      );
      if (markShown) {
        await _whatsNewService.markShown(
          version: version,
          currentReleaseSignature: releaseSignature,
        );
      }
      unawaited(
        _logEventSafe(dismissedEventName, parameters: {'version': version}),
      );
    } finally {
      _dialogShowing = false;
    }
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
                  _setCrashContextSafe(
                    feature: 'force_update_gate',
                    lastAction: 'tap_hard_update',
                  ),
                );
                unawaited(
                  _logEventSafe(
                    'force_update_tap_update',
                    parameters: {
                      'min_version': config.minimumRequiredVersion,
                      'latest_version': config.latestAvailableVersion,
                    },
                  ),
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
    showJuiceToast(
      context: context,
      message: AppLocalizations.of(context)!.softUpdateTitle,
      body: Text(
        config.softUpdateMessage ??
            AppLocalizations.of(context)!.softUpdateMessage,
      ),
      position: JuicePosition.center,
      actionLabel: AppLocalizations.of(context)!.softUpdateAction,
      onActionPressed: () {
        _skippedSoftUpdateVersion = config.latestAvailableVersion;
        unawaited(
          _setCrashContextSafe(
            feature: 'force_update_gate',
            lastAction: 'tap_soft_update',
          ),
        );
        unawaited(
          _logEventSafe(
            'soft_update_tap_update',
            parameters: {'latest_version': config.latestAvailableVersion},
          ),
        );
        _launchStore(config.storeUrl);
      },
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
        showJuiceToast(
          context: context,
          message: AppLocalizations.of(context)!.forceUpdateLinkError,
          tone: AppDialogTone.danger,
          position: JuicePosition.center,
        );
      }
    } catch (error, stackTrace) {
      unawaited(
        _reportErrorSafe(
          error: error,
          stackTrace: stackTrace,
          source: 'force_update_launch_store',
          fatal: false,
        ),
      );
    }
  }

  Future<void> _logEventSafe(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    try {
      await AnalyticsService.instance.logEvent(name, parameters: parameters);
    } catch (_) {}
  }

  Future<void> _setCrashContextSafe({
    String? feature,
    String? lastAction,
  }) async {
    try {
      await CrashReportingService.instance.setContext(
        feature: feature,
        lastAction: lastAction,
      );
    } catch (_) {}
  }

  Future<void> _reportErrorSafe({
    required Object error,
    required StackTrace stackTrace,
    required String source,
    required bool fatal,
  }) async {
    try {
      await CrashReportingService.instance.reportError(
        error: error,
        stackTrace: stackTrace,
        source: source,
        fatal: fatal,
      );
    } catch (_) {}
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

class AppLaunchInfo {
  const AppLaunchInfo({required this.version, required this.releaseSignature});

  factory AppLaunchInfo.fromPackageInfo(PackageInfo packageInfo) {
    final version = packageInfo.version.trim();
    final buildNumber = packageInfo.buildNumber.trim();
    final releaseSignature = buildNumber.isEmpty
        ? version
        : '$version+$buildNumber';
    return AppLaunchInfo(version: version, releaseSignature: releaseSignature);
  }

  final String version;
  final String releaseSignature;
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
