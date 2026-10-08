import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet/features/pet/pet_catalog.dart';
import 'package:pet/features/pet/pet_selection_page.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/app_ui_scale.dart';

const _prompt =
    "Hi! Nice room. Um… I don't have a name yet. What will you call me?";

// Pet animations loop forever, so pump bounded time instead of settling.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pump(
  WidgetTester tester,
  PetSelectionSubmitHandler onSubmit,
) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PetSelectionPage(
        initialSelectionId: PetCatalog.defaultPetId,
        confirmText: "That's you!",
        onSubmitSelection: onSubmit,
      ),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('pick → move in → pet asks its name → submit', (tester) async {
    PetSelectionResult? submitted;
    await _pump(tester, (selection) async {
      submitted = selection;
      return null;
    });

    // The name is asked in the second step, not on the picker.
    expect(find.text(_prompt), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Move in'));
    await _settle(tester);
    expect(find.text(_prompt), findsOneWidget);

    await tester.tap(find.text("That's you!"));
    await _settle(tester);
    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(submitted, isNull);

    await tester.enterText(find.byType(TextField), '  Mochi ');
    await tester.tap(find.text("That's you!"));
    await _settle(tester);
    expect(submitted?.petName, 'Mochi');
    expect(submitted?.pet.id, PetCatalog.defaultPetId);
  });

  testWidgets('back from naming returns to the picker', (tester) async {
    await _pump(tester, (_) async => null);
    await tester.tap(find.text('Move in'));
    await _settle(tester);
    expect(find.text(_prompt), findsOneWidget);

    await tester.tap(find.byTooltip('Back').last);
    await _settle(tester);
    expect(find.text(_prompt), findsNothing);
    expect(find.text('Move in'), findsOneWidget);
  });

  testWidgets('a failed create keeps the name and shows the error', (
    tester,
  ) async {
    await _pump(tester, (_) async => 'Could not create room');
    await tester.tap(find.text('Move in'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Mochi');
    await tester.tap(find.text("That's you!"));
    await _settle(tester);
    expect(find.text('Could not create room'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
  });

  testWidgets('naming step fits every locale on the smallest phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final failures = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      for (final keyboard in [0.0, 260.0]) {
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('$locale-$keyboard'),
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(kMaxUserTextScale),
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                ),
                child: child!,
              ),
              home: PetSelectionPage(
                initialSelectionId: PetCatalog.defaultPetId,
              ),
            ),
          ),
        );
        await _settle(tester);
        await tester.tap(find.byType(FilledButton));
        await _settle(tester);
        final error = tester.takeException();
        if (error != null) {
          failures.add('$locale keyboard=$keyboard: $error');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
