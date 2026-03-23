import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/shop_view.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('success notice renders CTA and does not rely on snackbar', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      buildApp(
        ShopFloatingNoticeCard(
          notice: ShopNoticeData.success(
            key: const ValueKey('success-notice'),
            title: 'Purchased Sofa.',
            message: 'Return to your pet room to start decorating.',
            primaryAction: ShopNoticeAction(
              label: 'Return to room',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Purchased Sofa.'), findsNWidgets(2));
    expect(
      find.text('Return to your pet room to start decorating.'),
      findsOneWidget,
    );
    expect(find.text('Return to room'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Return to room'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('non-room success notice omits return-to-room CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        ShopFloatingNoticeCard(
          notice: ShopNoticeData.success(
            key: const ValueKey('plain-success-notice'),
            title: 'Purchased Candy Pack.',
          ),
        ),
      ),
    );

    expect(find.text('Purchased Candy Pack.'), findsNWidgets(2));
    expect(find.byType(FilledButton), findsNothing);
  });

  test('shop route result factories preserve decor hint intent', () {
    final normalReturn = ShopRouteResult.returnedRoom('room-a');
    final decorReturn = ShopRouteResult.roomDecor('room-b');

    expect(normalReturn.roomId, 'room-a');
    expect(normalReturn.showRoomDecorHint, isFalse);
    expect(decorReturn.roomId, 'room-b');
    expect(decorReturn.showRoomDecorHint, isTrue);
  });
}
