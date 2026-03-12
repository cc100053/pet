import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_selection_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  Widget buildView({
    required VoidCallback onCreateRoom,
    required VoidCallback onJoinRoom,
    bool highlightCreateRoomCta = false,
    bool highlightJoinRoomCta = false,
    Key? createRoomCtaKey,
    Key? joinRoomCtaKey,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RoomSelectionView(
          rooms: const [],
          onCreateRoom: onCreateRoom,
          onJoinRoom: onJoinRoom,
          onSelectRoom: (_) {},
          onLeaveRoom: (_) {},
          creatingRoom: false,
          joiningRoom: false,
          userAvatarById: const {},
          userNameById: const {},
          selectedRoomId: null,
          userAvatarUrl: null,
          highlightCreateRoomCta: highlightCreateRoomCta,
          createRoomCtaKey: createRoomCtaKey,
          highlightJoinRoomCta: highlightJoinRoomCta,
          joinRoomCtaKey: joinRoomCtaKey,
        ),
      ),
    );
  }

  testWidgets('highlighted room entry actions remain visible and tappable', (
    WidgetTester tester,
  ) async {
    final createKey = GlobalKey();
    final joinKey = GlobalKey();
    var createTapCount = 0;
    var joinTapCount = 0;

    await tester.pumpWidget(
      buildView(
        onCreateRoom: () => createTapCount++,
        onJoinRoom: () => joinTapCount++,
        highlightCreateRoomCta: true,
        highlightJoinRoomCta: true,
        createRoomCtaKey: createKey,
        joinRoomCtaKey: joinKey,
      ),
    );

    expect(find.byKey(createKey), findsOneWidget);
    expect(find.byKey(joinKey), findsOneWidget);

    final createContainer = tester.widget<AnimatedContainer>(
      find.byKey(createKey),
    );
    final joinContainer = tester.widget<AnimatedContainer>(find.byKey(joinKey));
    final createDecoration = createContainer.decoration! as BoxDecoration;
    final joinDecoration = joinContainer.decoration! as BoxDecoration;

    expect(createDecoration.border, isNotNull);
    expect(joinDecoration.border, isNotNull);

    await tester.tap(find.text('Create New Room'));
    await tester.pump();
    await tester.tap(find.text('Enter Invite Code'));
    await tester.pump();

    expect(createTapCount, 1);
    expect(joinTapCount, 1);
  });
}
