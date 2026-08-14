import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_selection_view.dart';
import 'package:pet/features/home/widgets/room_frame_card.dart';
import 'package:pet/features/home/widgets/room_frame_skins.dart';
import 'package:pet/l10n/app_localizations.dart';

/// The pet sprite animates forever, so `pumpAndSettle` never returns on any
/// surface that shows a room card. Pump enough frames for a route transition
/// instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}

Finder swatchOf(RoomFrameStyle style) =>
    find.byKey(Key('room_frame_swatch_${style.storageKey}'));

void main() {
  const ownedStyles = <RoomFrameStyle>{
    RoomFrameStyle.polaroidClassic,
    RoomFrameStyle.corkboard,
    RoomFrameStyle.goldLeaf,
  };

  Widget buildView({
    Map<String, RoomFrameStyle> roomFrameStyleByRoom = const {},
    Future<void> Function(String roomId, RoomFrameStyle style)?
    onEquipRoomFrame,
  }) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RoomSelectionView(
          rooms: const [
            {
              'id': 'room-1',
              'pet_name': 'Mochi',
              'pet_type': 'ghost',
              'pet_health': 0.8,
              'pet_level': 4,
              'unread_count': 0,
              'latest_caption': 'fed today',
            },
          ],
          roomFrameStyleByRoom: roomFrameStyleByRoom,
          ownedFrameStyles: ownedStyles,
          onEquipRoomFrame: onEquipRoomFrame,
          onCreateRoom: () {},
          onJoinRoom: () {},
          onSelectRoom: (_) {},
          onLeaveRoom: (_) {},
          creatingRoom: false,
          joiningRoom: false,
          selectedRoomId: 'room-1',
        ),
      ),
    );
  }

  testWidgets('room card wears the equipped casing', (tester) async {
    await tester.pumpWidget(
      buildView(
        roomFrameStyleByRoom: const {'room-1': RoomFrameStyle.nightGlow},
      ),
    );

    final card = tester.widget<RoomFrameCard>(find.byType(RoomFrameCard));
    expect(card.skin.style, RoomFrameStyle.nightGlow);
  });

  testWidgets('room card falls back to the default casing', (tester) async {
    await tester.pumpWidget(buildView());

    final card = tester.widget<RoomFrameCard>(find.byType(RoomFrameCard));
    expect(card.skin.style, RoomFrameSkins.defaultStyle);
  });

  testWidgets('long press opens the frame picker and commits the pick', (
    tester,
  ) async {
    final equipped = <(String, RoomFrameStyle)>[];
    await tester.pumpWidget(
      buildView(
        roomFrameStyleByRoom: const {'room-1': RoomFrameStyle.polaroidClassic},
        onEquipRoomFrame: (roomId, style) async {
          equipped.add((roomId, style));
        },
      ),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    expect(find.text('Change Frame'), findsOneWidget);
    // The equipped casing is highlighted, named, and previewed on open.
    expect(find.text('Polaroid · Classic'), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    expect(find.text('Owned'), findsNWidgets(2));

    await tester.tap(swatchOf(RoomFrameStyle.goldLeaf));
    await settle(tester);

    // Highlighting updates the preview's name without committing anything yet.
    expect(find.text('Collector · Gold Leaf'), findsOneWidget);
    expect(equipped, isEmpty);

    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(equipped, [('room-1', RoomFrameStyle.goldLeaf)]);
    expect(find.text('Change Frame'), findsNothing);
  });

  testWidgets('a locked casing cannot be highlighted or equipped', (
    tester,
  ) async {
    final equipped = <RoomFrameStyle>[];
    await tester.pumpWidget(
      buildView(
        roomFrameStyleByRoom: const {'room-1': RoomFrameStyle.polaroidClassic},
        onEquipRoomFrame: (_, style) async => equipped.add(style),
      ),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    // 夜光 is priced, so it shows its candy cost instead of an owned label.
    expect(find.text('300'), findsOneWidget);

    await tester.tap(swatchOf(RoomFrameStyle.nightGlow));
    await tester.pump();

    expect(
      find.text("You don't own Collector · Night Glow yet."),
      findsOneWidget,
    );
    expect(find.text('Polaroid · Classic'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(equipped, isEmpty);

    // Let the juice snackbar's auto-dismiss timer drain.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('long press falls back to room options with no equip handler', (
    tester,
  ) async {
    await tester.pumpWidget(buildView());

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    expect(find.text('Room options'), findsOneWidget);
    expect(find.text('Change Frame'), findsNothing);
  });

  group('geometry', () {
    test('every casing reserves a height that fits its own card', () {
      for (final skin in RoomFrameSkins.byStyle.values) {
        final geometry = RoomFrameGeometry.resolve(
          availableWidth: 170,
          skin: skin,
          scale: 1,
        );
        expect(
          geometry.totalHeight,
          greaterThan(geometry.cardHeight),
          reason: '${skin.style} must reserve room for its overhangs',
        );
        // Invariant 1: the photo zone keeps the shared ratio in every casing.
        expect(
          geometry.photoWidth / geometry.photoHeight,
          closeTo(RoomFrameSkins.photoAspectRatio, 0.001),
        );
      }
    });

    test('storage keys round-trip', () {
      for (final style in RoomFrameStyle.values) {
        expect(RoomFrameStyle.fromStorageKey(style.storageKey), style);
      }
      expect(RoomFrameStyle.fromStorageKey('nope'), isNull);
      expect(RoomFrameStyle.fromStorageKey(null), isNull);
    });
  });
}
