import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/shop_view.dart';

void main() {
  Widget buildChip({required int amount, int? reward, int eventId = 0}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ShopCurrencyChip(
            amount: amount,
            coinReward: reward,
            coinRewardEventId: eventId,
            icon: const SizedBox(width: 24, height: 24),
          ),
        ),
      ),
    );
  }

  testWidgets('shows candy reward feedback when reward event changes', (
    tester,
  ) async {
    await tester.pumpWidget(buildChip(amount: 120));

    await tester.pumpWidget(buildChip(amount: 620, reward: 500, eventId: 1));
    await tester.pump();

    expect(find.text('620'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shop-currency-reward-label')),
      findsOneWidget,
    );
    expect(find.text('+500'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('620'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(const ValueKey('shop-currency-reward-label')),
      findsNothing,
    );
  });
}
