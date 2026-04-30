import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_selection_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  Widget buildView({
    required int unreadCount,
    String? currentAppVersion,
    String petType = 'ghost',
    String? petName = 'Mochi',
    Map<String, Map<String, String>> roomEquippedSkusBySlot = const {},
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RoomSelectionView(
          rooms: [
            {
              'id': 'room-1',
              'pet_name': petName,
              'pet_type': petType,
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
          roomEquippedSkusBySlot: roomEquippedSkusBySlot,
          selectedRoomId: 'room-1',
          userAvatarUrl: null,
          currentAppVersion: currentAppVersion,
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

  testWidgets('falls back unsupported room pets to ghost in room selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildView(
        unreadCount: 0,
        currentAppVersion: '1.0.9',
        petType: 'tiger',
        petName: null,
      ),
    );

    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Tiger'), findsNothing);
  });

  testWidgets('renders equipped pet item in room selection preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildView(
        unreadCount: 0,
        roomEquippedSkusBySlot: const {
          'room-1': {'head': 'equip_straw_hat'},
        },
      ),
    );

    expect(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-equip_straw_hat')),
      findsOneWidget,
    );
  });

  testWidgets('ignores unknown equipped pet item in room selection preview', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildView(
        unreadCount: 0,
        roomEquippedSkusBySlot: const {
          'room-1': {'head': 'equip_unknown'},
        },
      ),
    );

    expect(
      find.byKey(const ValueKey('pet-equipment-frontPet-head-equip_unknown')),
      findsNothing,
    );
  });
}
