import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/widgets/shop_legal_links_row.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> launchedUrls = <String>[];

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;

  @override
  Future<bool> closeWebView() async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late UrlLauncherPlatform originalLauncher;
  late _FakeUrlLauncherPlatform fakeLauncher;

  setUp(() {
    originalLauncher = UrlLauncherPlatform.instance;
    fakeLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
  });

  testWidgets('renders legal links and launches expected URLs', (tester) async {
    const privacyLabel = 'Privacy Policy';
    const termsLabel = 'Terms of Use';
    const separatorLabel = '|';
    final privacyUri = Uri.parse('https://example.com/privacy');
    final termsUri = Uri.parse(
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopLegalLinksRow(
            privacyPolicyUri: privacyUri,
            termsOfUseUri: termsUri,
            privacyPolicyLabel: privacyLabel,
            termsOfUseLabel: termsLabel,
            separatorLabel: separatorLabel,
          ),
        ),
      ),
    );

    expect(find.text(privacyLabel), findsOneWidget);
    expect(find.text(termsLabel), findsOneWidget);
    expect(find.text(separatorLabel), findsOneWidget);

    await tester.tap(find.text(privacyLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(termsLabel));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launchedUrls.length, 2);
    expect(fakeLauncher.launchedUrls[0], privacyUri.toString());
    expect(fakeLauncher.launchedUrls[1], termsUri.toString());
  });
}
