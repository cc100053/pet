import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics/analytics_service.dart';
import '../../services/app_config/app_config_service.dart';

class ForceUpdateGate extends StatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends State<ForceUpdateGate>
    with WidgetsBindingObserver {
  final AppConfigService _configService = AppConfigService();
  StreamSubscription<AuthState>? _authSubscription;

  bool _checking = true;
  bool _updateRequired = false;
  bool _dialogShowing = false;
  ForceUpdateConfig? _config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _checkForUpdate();
    });
    _checkForUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (mounted) {
        setState(() {
          _checking = false;
          _updateRequired = false;
          _config = null;
        });
      }
      return;
    }

    setState(() {
      _checking = true;
    });

    try {
      final config = await _configService.fetchForceUpdateConfig();
      if (!mounted) {
        return;
      }
      if (config == null) {
        setState(() {
          _checking = false;
          _updateRequired = false;
          _config = null;
        });
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final requiresUpdate =
          _isVersionLower(currentVersion, config.minVersion);

      setState(() {
        _checking = false;
        _updateRequired = requiresUpdate;
        _config = config;
      });

      if (requiresUpdate) {
        AnalyticsService.instance.logEvent('force_update_required', parameters: {
          'min_version': config.minVersion,
          'current_version': currentVersion,
        });
        _showForceUpdateDialog(config);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _checking = false;
      });
    }
  }

  bool _isVersionLower(String current, String minimum) {
    final currentParts = _parseVersion(current);
    final minParts = _parseVersion(minimum);
    final maxLength =
        currentParts.length > minParts.length ? currentParts.length : minParts.length;
    for (var i = 0; i < maxLength; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final minValue = i < minParts.length ? minParts[i] : 0;
      if (currentValue < minValue) {
        return true;
      }
      if (currentValue > minValue) {
        return false;
      }
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    final sanitized = version.split('+').first;
    return sanitized
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  Future<void> _showForceUpdateDialog(ForceUpdateConfig config) async {
    if (_dialogShowing) {
      return;
    }
    _dialogShowing = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update required'),
        content: Text(
          config.message ??
              'A newer version is required to continue. Please update now.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchStore(config.storeUrl);
            },
            child: const Text('Update now'),
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
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open store link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_updateRequired || _config == null) {
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
                'Update required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                config.message ??
                    'A newer version is required to continue. Please update now.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onUpdate,
                child: const Text('Update now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
