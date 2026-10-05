import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/pet/pet_animated_image.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/whats_new/app_whats_new_catalog.dart';
import 'package:pet/shared/whats_new/whats_new_toast_body.dart';

void main() {
  testWidgets('4.0.0 renders icon rows with details on a 320pt phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final entry = AppWhatsNewCatalog.entryForVersion('4.0.0')!;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(40),
            child: WhatsNewToastBody(version: '4.0.0', entry: entry),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('ハロウィン家具 3点'), findsOneWidget);
    expect(find.text('かぼちゃランタンなど'), findsOneWidget);
    expect(find.byIcon(Icons.chair_rounded), findsOneWidget);
    expect(find.byIcon(Icons.palette_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });

  testWidgets('5.0.0 shows the turtle hero and both add-pet paths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final entry = AppWhatsNewCatalog.entryForVersion('5.0.0')!;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(40),
            child: WhatsNewToastBody(version: '5.0.0', entry: entry),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(PetAnimatedImage), findsOneWidget);
    expect(find.text('새 방 만들기'), findsOneWidget);
    expect(find.text('펫 티켓 사용하기'), findsOneWidget);
    expect(find.byIcon(Icons.add_home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.confirmation_number_rounded), findsOneWidget);
  });
}
