import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/user_avatar.dart';

void main() {
  testWidgets('UserAvatar renders preset avatar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UserAvatar(
              avatar: 'preset:0',
              fallbackText: 'Alice',
              size: 48,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
  });

  testWidgets('UserAvatar falls back to initial letter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UserAvatar(avatar: null, fallbackText: 'Bob', size: 48),
          ),
        ),
      ),
    );

    expect(find.text('B'), findsOneWidget);
  });
}
