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
    );

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: _buildConfigService(
            minimumRequiredVersion: '1.0.6',
            latestAvailableVersion: '1.0.6',
          ),
          whatsNewService: WhatsNewService(settingsStore: settings),
          versionLoader: () async => '1.0.5',
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update required'), findsAtLeastNWidgets(1));
    expect(find.text("What's new"), findsNothing);
    expect(settings.lastShownWhatsNewVersion, isNull);
  });

  testWidgets('soft update resolves before What\'s New is shown', (
    tester,
  ) async {
    final settings = _FakeWhatsNewSettingsStore(
      lastLaunchedAppVersion: '1.0.4',
    );

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: _buildConfigService(
            minimumRequiredVersion: '1.0.0',
            latestAvailableVersion: '1.0.6',
          ),
          whatsNewService: WhatsNewService(settingsStore: settings),
          versionLoader: () async => '1.0.5',
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text("What's new"), findsNothing);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('Version 1.0.5'), findsOneWidget);
    expect(settings.lastShownWhatsNewVersion, isNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsNothing);
    expect(settings.lastShownWhatsNewVersion, '1.0.5');
  });

  testWidgets('dismissed What\'s New does not repeat on later launches', (
    tester,
  ) async {
    final settings = _FakeWhatsNewSettingsStore(
      lastLaunchedAppVersion: '1.0.4',
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
          versionLoader: () async => '1.0.5',
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(settings.lastShownWhatsNewVersion, '1.0.5');

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: configService,
          whatsNewService: whatsNewService,
          versionLoader: () async => '1.0.5',
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsNothing);
  });

  testWidgets('debug prompt shows What\'s New even when already marked shown', (
    tester,
  ) async {
    final settings = _FakeWhatsNewSettingsStore(lastLaunchedAppVersion: '1.0.5')
      ..lastShownWhatsNewVersion = '1.0.5';

    await tester.pumpWidget(
      _buildApp(
        ForceUpdateGate(
          configService: _buildConfigService(
            minimumRequiredVersion: '1.0.0',
            latestAvailableVersion: '1.0.5',
          ),
          whatsNewService: WhatsNewService(settingsStore: settings),
          versionLoader: () async => '1.0.5',
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsNothing);

    ForceUpdateDebugTool.instance.showWhatsNewPrompt();
    await tester.pumpAndSettle();

    expect(find.text("What's new"), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(settings.lastShownWhatsNewVersion, '1.0.5');
  });
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
  _FakeWhatsNewSettingsStore({this.lastLaunchedAppVersion});

  @override
  String? lastLaunchedAppVersion;

  @override
  String? lastShownWhatsNewVersion;

  @override
  Future<void> setLastLaunchedAppVersion(String? version) async {
    lastLaunchedAppVersion = version;
  }

  @override
  Future<void> setLastShownWhatsNewVersion(String? version) async {
    lastShownWhatsNewVersion = version;
  }
}
