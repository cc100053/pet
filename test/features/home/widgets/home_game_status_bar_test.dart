import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_game_status_bar.dart';

void main() {
  Widget buildHarness({
    required bool showHint,
    required VoidCallback onInventoryTap,
    required VoidCallback onDismissHint,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: HomeGameStatusBar(
          petAvatar: const ColoredBox(color: Colors.blue),
          expProgress: 0.4,
          level: 3,
          petName: 'Mochi',
          healthValue: 0.7,
          coins: 120,
          diamonds: 8,
          onPetTap: () {},
          onStoreTap: () {},
          onInventoryTap: onInventoryTap,
          inventoryLabel: 'Inventory',
          showInventoryGuidance: showHint,
          inventoryGuidanceTitle: 'Decorate your room',
          inventoryGuidanceBody:
              'Tap Inventory to enter room edit mode, then place furniture or apply a background.',
          onInventoryGuidanceDismiss: onDismissHint,
        ),
      ),
    );
  }

  testWidgets('shows room decor guidance near inventory action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(showHint: true, onInventoryTap: () {}, onDismissHint: () {}),
    );

    expect(find.text('Decorate your room'), findsOneWidget);
    expect(
      find.text(
        'Tap Inventory to enter room edit mode, then place furniture or apply a background.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Inventory'), findsOneWidget);
  });

  testWidgets('opening inventory dismisses the room decor guidance', (
    tester,
  ) async {
    var showHint = true;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return buildHarness(
            showHint: showHint,
            onInventoryTap: () {
              setState(() {
                showHint = false;
              });
            },
            onDismissHint: () {
              setState(() {
                showHint = false;
              });
            },
          );
        },
      ),
    );

    expect(find.text('Decorate your room'), findsOneWidget);

    await tester.tap(find.byTooltip('Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Decorate your room'), findsNothing);
  });
}
