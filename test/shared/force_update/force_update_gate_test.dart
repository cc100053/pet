import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/app_config/app_config_service.dart';
import 'package:pet/services/app_config/app_store_lookup_service.dart';
import 'package:pet/shared/force_update/force_update_debug_tool.dart';
import 'package:pet/shared/force_update/force_update_gate.dart';
import 'package:pet/shared/whats_new/whats_new_service.dart';

void main() {
  testWidgets('hard update blocks the What\'s New dialog', (tester) async {
    final settings = _FakeWhatsNewSettingsStore(
      lastLaunchedAppVersion: '1.0.4',
      lastLaunchedAppReleaseSignature: '1.0.4+9',
    );

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: _buildConfigService(
            minimumRequiredVersion: '1.0.6',
            latestAvailableVersion: '1.0.6',
          ),
          whatsNewService: WhatsNewService(settingsStore: settings),
          launchInfoLoader: () async => const AppLaunchInfo(
            version: '1.0.5',
            releaseSignature: '1.0.5+1',
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsAtLeastNWidgets(1));
    expect(find.text('Version update'), findsNothing);
    expect(settings.lastShownWhatsNewVersion, isNull);
  });

  testWidgets('soft update resolves before What\'s New is shown', (
    tester,
  ) async {
    final settings = _FakeWhatsNewSettingsStore(
      lastLaunchedAppVersion: '1.0.4',
      lastLaunchedAppReleaseSignature: '1.0.4+9',
    );

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: _buildConfigService(
            minimumRequiredVersion: '1.0.0',
            latestAvailableVersion: '1.0.6',
          ),
          whatsNewService: WhatsNewService(settingsStore: settings),
          launchInfoLoader: () async => const AppLaunchInfo(
            version: '1.0.5',
            releaseSignature: '1.0.5+1',
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Version update'), findsNothing);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Version update'), findsAtLeastNWidgets(1));
    expect(find.text('Version 1.0.5'), findsOneWidget);
    final versionCardTopLeft = tester.getTopLeft(find.text('Version 1.0.5'));
    final titleTopLeft = tester.getTopLeft(find.text('Version update').first);
    expect(versionCardTopLeft.dx, lessThan(titleTopLeft.dx));
    expect(settings.lastShownWhatsNewVersion, isNull);
    expect(settings.lastLaunchedAppVersion, '1.0.4');
    expect(settings.lastLaunchedAppReleaseSignature, '1.0.4+9');

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Version update'), findsNothing);
    expect(settings.lastShownWhatsNewVersion, '1.0.5');
    expect(settings.lastLaunchedAppVersion, '1.0.5');
    expect(settings.lastLaunchedAppReleaseSignature, '1.0.5+1');
  });

  testWidgets('dismissed What\'s New does not repeat on later launches', (
    tester,
  ) async {
    final settings = _FakeWhatsNewSettingsStore(
      lastLaunchedAppVersion: '1.0.4',
      lastLaunchedAppReleaseSignature: '1.0.4+9',
    );
    final configService = _buildConfigService(
      minimumRequiredVersion: '1.0.0',
      latestAvailableVersion: '1.0.5',
    );
    final whatsNewService = WhatsNewService(settingsStore: settings);

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: configService,
          whatsNewService: whatsNewService,
          launchInfoLoader: () async => const AppLaunchInfo(
            version: '1.0.5',
            releaseSignature: '1.0.5+1',
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version update'), findsAtLeastNWidgets(1));

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(settings.lastShownWhatsNewVersion, '1.0.5');

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: configService,
          whatsNewService: whatsNewService,
          launchInfoLoader: () async => const AppLaunchInfo(
            version: '1.0.5',
            releaseSignature: '1.0.5+1',
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version update'), findsNothing);
  });

  testWidgets('debug prompt shows What\'s New even when already marked shown', (
    tester,
  ) async {
    final settings = _FakeWhatsNewSettingsStore(
      lastLaunchedAppVersion: '1.0.5',
      lastLaunchedAppReleaseSignature: '1.0.5+1',
    )..lastShownWhatsNewVersion = '1.0.5';

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: _buildConfigService(
            minimumRequiredVersion: '1.0.0',
            latestAvailableVersion: '1.0.5',
          ),
          whatsNewService: WhatsNewService(settingsStore: settings),
          launchInfoLoader: () async => const AppLaunchInfo(
            version: '1.0.5',
            releaseSignature: '1.0.5+1',
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Version update'), findsNothing);

    ForceUpdateDebugTool.instance.showWhatsNewPrompt();
    await tester.pumpAndSettle();

    expect(find.text('Version update'), findsAtLeastNWidgets(1));

    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(settings.lastShownWhatsNewVersion, '1.0.5');
  });

  testWidgets(
    'same-version build upgrade shows What\'s New when not shown before',
    (tester) async {
      final settings = _FakeWhatsNewSettingsStore(
        lastLaunchedAppVersion: '1.0.5',
        lastLaunchedAppReleaseSignature: '1.0.5+1',
      );

      await tester.pumpWidget(
        _buildApp(
          ForceUpdateGate(
            configService: _buildConfigService(
              minimumRequiredVersion: '1.0.0',
              latestAvailableVersion: '1.0.5',
            ),
            whatsNewService: WhatsNewService(settingsStore: settings),
            launchInfoLoader: () async => const AppLaunchInfo(
              version: '1.0.5',
              releaseSignature: '1.0.5+2',
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version update'), findsAtLeastNWidgets(1));
      expect(settings.lastLaunchedAppReleaseSignature, '1.0.5+1');

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(settings.lastShownWhatsNewVersion, '1.0.5');
      expect(settings.lastLaunchedAppReleaseSignature, '1.0.5+2');
    },
  );

  testWidgets(
    'legacy install without recorded version still shows first tracked What\'s New',
    (tester) async {
      final settings = _FakeWhatsNewSettingsStore(
        hadExistingInstallBeforeVersionTracking: true,
      );

      await tester.pumpWidget(
        _buildApp(
          ForceUpdateGate(
            configService: _buildConfigService(
              minimumRequiredVersion: '1.0.0',
              latestAvailableVersion: '1.0.5',
            ),
            whatsNewService: WhatsNewService(settingsStore: settings),
            launchInfoLoader: () async => const AppLaunchInfo(
              version: '1.0.5',
              releaseSignature: '1.0.5+1',
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version update'), findsAtLeastNWidgets(1));
      expect(settings.lastLaunchedAppVersion, isNull);

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(settings.lastShownWhatsNewVersion, '1.0.5');
      expect(settings.lastLaunchedAppVersion, '1.0.5');
      expect(settings.lastLaunchedAppReleaseSignature, '1.0.5+1');
    },
  );
}

Widget _buildApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

AppConfigService _buildConfigService({
  required String minimumRequiredVersion,
  required String latestAvailableVersion,
}) {
  final values = <String, dynamic>{
    'minimum_required_version': minimumRequiredVersion,
    'latest_available_version': latestAvailableVersion,
    'store_url': 'https://apps.apple.com/app/id6757725650',
  };
  return AppConfigService(
    configValueLoader: (key) async => values[key],
    appStoreVersionLookupService: _FakeAppStoreVersionLookupService(),
  );
}

class _FakeAppStoreVersionLookupService extends AppStoreVersionLookupService {
  _FakeAppStoreVersionLookupService() : super(fallbackStoreUrl: '');

  @override
  Future<AppStoreVersionLookupResult?> fetchLatestVersion() async => null;
}

class _FakeWhatsNewSettingsStore implements WhatsNewSettingsStore {
  _FakeWhatsNewSettingsStore({
    this.lastLaunchedAppVersion,
    this.lastLaunchedAppReleaseSignature,
    this.hadExistingInstallBeforeVersionTracking = false,
  });

  @override
  String? lastLaunchedAppVersion;

  @override
  String? lastLaunchedAppReleaseSignature;

  @override
  String? lastShownWhatsNewVersion;

  @override
  final bool hadExistingInstallBeforeVersionTracking;

  @override
  Future<void> setLastLaunchedAppVersion(String? version) async {
    lastLaunchedAppVersion = version;
  }

  @override
  Future<void> setLastLaunchedAppReleaseSignature(String? signature) async {
    lastLaunchedAppReleaseSignature = signature;
  }

  @override
  Future<void> setLastShownWhatsNewVersion(String? version) async {
    lastShownWhatsNewVersion = version;
  }
}
