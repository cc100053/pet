import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/services/app_config/app_config_service.dart';
import 'package:pet/shared/force_update/force_update_gate.dart';
import 'package:pet/shared/whats_new/whats_new_service.dart';
import 'package:pet/shared/whats_new/whats_new_toast_body.dart';

/// Config service that always reports no force/soft update so the gate goes
/// straight to the What's New evaluation path.
class _NoForceUpdateConfigService extends AppConfigService {
  @override
  Future<ForceUpdateConfig?> fetchForceUpdateConfig() async => null;
}

/// In-memory What's New settings store. Mirrors the production persistence
/// contract without touching Hive/Supabase.
class _FakeWhatsNewStore implements WhatsNewSettingsStore {
  _FakeWhatsNewStore({
    this.lastLaunchedAppVersion,
    this.lastLaunchedAppReleaseSignature,
  });

  @override
  String? lastLaunchedAppVersion;
  @override
  String? lastLaunchedAppReleaseSignature;
  @override
  String? lastShownWhatsNewVersion;
  @override
  final bool hadExistingInstallBeforeVersionTracking = false;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows the What\'s New sheet only once when the app resumes mid-display',
    (tester) async {
      // Upgraded from 2.0.0 -> 2.0.1 (which has a catalog entry); never shown.
      final store = _FakeWhatsNewStore(
        lastLaunchedAppVersion: '2.0.0',
        lastLaunchedAppReleaseSignature: '2.0.0+2',
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ForceUpdateGate(
            configService: _NoForceUpdateConfigService(),
            whatsNewService: WhatsNewService(settingsStore: store),
            launchInfoLoader: () async => const AppLaunchInfo(
              version: '2.0.1',
              releaseSignature: '2.0.1+3',
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      // Let _checkForUpdate resolve and the toast animate in.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(WhatsNewToastBody), findsOneWidget);

      // Simulate backgrounding + resuming while the sheet is still open, which
      // happens when an ATT/push permission prompt appears right after a fresh
      // update. The lifecycle observer re-triggers the update check.
      const lifecyclePath = <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ];
      for (final state in lifecyclePath) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Without the re-entrancy / session guards this would surface a second,
      // stacked sheet.
      expect(find.byType(WhatsNewToastBody), findsOneWidget);
    },
  );
}
