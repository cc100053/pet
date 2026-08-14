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

/// A phone-shaped viewport: the default 800x600 test surface is too short for
/// the 換相框 sheet, which puts 完成 off-screen and makes taps miss.
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  Widget buildView({
    Map<String, RoomFrameStyle> roomFrameStyleByRoom = const {},
    Future<void> Function(String roomId, RoomFrameStyle style)?
    onEquipRoomFrame,
    int? petLevel = 4,
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
              'pet_name': 'Mochi',
              'pet_type': 'ghost',
              'pet_health': 0.8,
              'pet_level': petLevel,
              'unread_count': 0,
              'latest_caption': 'fed today',
            },
          ],
          roomFrameStyleByRoom: roomFrameStyleByRoom,
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
    usePhoneViewport(tester);
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
    // The original card is offered alongside the four new casings.
    expect(swatchOf(RoomFrameStyle.original), findsOneWidget);
    expect(
      find.text('Owned'),
      findsNWidgets(RoomFrameSkins.displayOrder.length - 1),
    );

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

  testWidgets('the original card can be picked back', (tester) async {
    usePhoneViewport(tester);
    final equipped = <RoomFrameStyle>[];
    await tester.pumpWidget(
      buildView(
        roomFrameStyleByRoom: const {'room-1': RoomFrameStyle.goldLeaf},
        onEquipRoomFrame: (_, style) async => equipped.add(style),
      ),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    await tester.tap(swatchOf(RoomFrameStyle.original));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);

    expect(equipped, [RoomFrameStyle.original]);
  });

  testWidgets('every casing is pickable while the ladder sits at Lv 1', (
    tester,
  ) async {
    usePhoneViewport(tester);
    // A room whose pet summary has not loaded yet must not read as locked.
    await tester.pumpWidget(
      buildView(petLevel: null, onEquipRoomFrame: (_, _) async {}),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    for (final style in RoomFrameSkins.displayOrder) {
      expect(swatchOf(style), findsOneWidget);
    }
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

    test('the original card is the default casing', () {
      // Existing rooms have no stored casing, so the default must be the card
      // they already had.
      expect(RoomFrameSkins.defaultStyle, RoomFrameStyle.original);
      expect(RoomFrameSkins.resolve(null).style, RoomFrameStyle.original);
      expect(RoomFrameSkins.displayOrder.first, RoomFrameStyle.original);
      expect(
        RoomFrameSkins.byStyle.keys.toSet(),
        RoomFrameStyle.values.toSet(),
      );
    });

    test('the whole ladder currently unlocks at Lv 1', () {
      for (final style in RoomFrameStyle.values) {
        expect(RoomFrameSkins.unlockLevel(style), 1, reason: '$style');
        expect(RoomFrameSkins.isUnlocked(style, 1), isTrue);
        // An unknown level is treated as 1 rather than as locked.
        expect(RoomFrameSkins.isUnlocked(style, null), isTrue);
      }
      expect(RoomFrameSkins.unlockedFor(1), RoomFrameStyle.values.toSet());
    });

    test('the level gate compares against the required level', () {
      for (final style in RoomFrameStyle.values) {
        final required = RoomFrameSkins.unlockLevel(style);
        expect(RoomFrameSkins.isUnlocked(style, required - 1), isFalse);
        expect(RoomFrameSkins.isUnlocked(style, required), isTrue);
        expect(RoomFrameSkins.isUnlocked(style, required + 5), isTrue);
      }
      expect(RoomFrameSkins.unlockedFor(0), isEmpty);
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
