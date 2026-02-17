import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_selection_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  Widget buildView({required int unreadCount}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RoomSelectionView(
          rooms: [
            {
              'id': 'room-1',
              'pet_name': 'Mochi',
              'pet_type': 'ghost',
              'pet_health': 0.8,
              'unread_count': unreadCount,
            },
          ],
          onCreateRoom: () {},
          onJoinRoom: () {},
          onSelectRoom: (_) {},
          onLeaveRoom: (_) {},
          creatingRoom: false,
          joiningRoom: false,
          userAvatarById: const {},
          userNameById: const {},
          selectedRoomId: 'room-1',
          userAvatarUrl: null,
        ),
      ),
    );
  }

  testWidgets('shows room unread indicator when room has unread', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildView(unreadCount: 3));

    expect(
      find.byKey(const Key('room_unread_indicator_room-1')),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('hides room unread indicator when room has no unread', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildView(unreadCount: 0));

    expect(find.byKey(const Key('room_unread_indicator_room-1')), findsNothing);
  });
}
