import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_game_status_bar.dart';

void main() {
  Widget buildHarness({
    required bool showHint,
    required VoidCallback onInventoryTap,
    required VoidCallback onDismissHint,
    int? coinReward,
    int coinRewardEventId = 0,
    String? coinRewardLabel,
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
          coinReward: coinReward,
          coinRewardEventId: coinRewardEventId,
          coinRewardLabel: coinRewardLabel,
          onPetTap: () {},
          onStoreTap: () {},
          onInventoryTap: onInventoryTap,
          inventoryLabel: 'Inventory',
          showInventoryGuidance: showHint,
          inventoryGuidanceTitle: 'Decorate room',
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

    expect(find.text('Decorate room'), findsOneWidget);
    expect(find.byTooltip('Inventory'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inventory-guidance-highlight')),
      findsOneWidget,
    );
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

    expect(find.text('Decorate room'), findsOneWidget);

    await tester.tap(find.byTooltip('Inventory'));
    await tester.pumpAndSettle();

    expect(find.text('Decorate room'), findsNothing);
  });

  testWidgets('room decor guidance auto dismisses after five seconds', (
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

    expect(find.text('Decorate room'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Decorate room'), findsNothing);
    expect(
      find.byKey(const ValueKey('inventory-guidance-highlight')),
      findsNothing,
    );
  });

  testWidgets('shows double reward label in the currency pill', (tester) async {
    await tester.pumpWidget(
      buildHarness(
        showHint: false,
        onInventoryTap: () {},
        onDismissHint: () {},
      ),
    );

    await tester.pumpWidget(
      buildHarness(
        showHint: false,
        onInventoryTap: () {},
        onDismissHint: () {},
        coinReward: 20,
        coinRewardEventId: 1,
        coinRewardLabel: 'x2 candy +20',
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('home-currency-reward-label')),
      findsOneWidget,
    );
    expect(find.text('x2 candy +20'), findsOneWidget);
  });
}
