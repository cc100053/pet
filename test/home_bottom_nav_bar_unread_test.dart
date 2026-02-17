import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_bottom_nav_bar.dart';

void main() {
  Widget buildNav({required bool chatHasUnread}) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: HomeBottomNavBar(
            onHome: () {},
            onCalendar: () {},
            onCamera: () {},
            onStore: () {},
            onChat: () {},
            chatHasUnread: chatHasUnread,
          ),
        ),
      ),
    );
  }

  testWidgets('shows unread indicator on chat icon when unread exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildNav(chatHasUnread: true));

    expect(find.byKey(const Key('home_chat_unread_indicator')), findsOneWidget);
  });

  testWidgets('hides unread indicator on chat icon when no unread', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildNav(chatHasUnread: false));

    expect(find.byKey(const Key('home_chat_unread_indicator')), findsNothing);
  });
}
