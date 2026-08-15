import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_selection_view.dart';
import 'package:pet/features/home/widgets/room_frame_card.dart';
import 'package:pet/features/home/widgets/room_frame_long_press_hint.dart';
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

/// WCAG 2.1 relative luminance of one sRGB channel.
double _channelLuminance(int value) {
  final c = value / 255;
  return c <= 0.03928
      ? c / 12.92
      : math.pow((c + 0.055) / 1.055, 2.4) as double;
}

double _relativeLuminance(Color color) {
  return 0.2126 * _channelLuminance((color.r * 255).round()) +
      0.7152 * _channelLuminance((color.g * 255).round()) +
      0.0722 * _channelLuminance((color.b * 255).round());
}

/// WCAG 2.1 contrast ratio. Both colours must be fully opaque.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  Widget buildView({
    Map<String, RoomFrameStyle> roomFrameStyleByRoom = const {},
    Future<void> Function(String roomId, RoomFrameStyle style)?
    onEquipRoomFrame,
    // Lv 8 clears the whole unlock ladder, so tests that are not about gating
    // see every casing as pickable.
    int? petLevel = 8,
    bool showFrameHint = false,
    VoidCallback? onFrameHintSeen,
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
          showFrameHint: showFrameHint,
          onFrameHintSeen: onFrameHintSeen,
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
    // The original card is offered alongside the four new casings, and every
    // swatch names its casing rather than repeating an ownership word.
    expect(swatchOf(RoomFrameStyle.original), findsOneWidget);
    expect(find.text('Owned'), findsNothing);
    expect(find.text('In use'), findsNothing);
    for (final style in RoomFrameSkins.displayOrder) {
      expect(
        find.descendant(of: swatchOf(style), matching: find.byType(Text)),
        findsOneWidget,
        reason: '$style swatch carries its name and nothing else',
      );
    }
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Gold Leaf'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);

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

  group('long-press hint', () {
    testWidgets('is only drawn when the device is still owed it', (
      tester,
    ) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(buildView(onEquipRoomFrame: (_, _) async {}));
      await settle(tester);
      expect(find.byType(RoomFrameLongPressHint), findsNothing);

      await tester.pumpWidget(
        buildView(onEquipRoomFrame: (_, _) async {}, showFrameHint: true),
      );
      await settle(tester);
      expect(find.byType(RoomFrameLongPressHint), findsOneWidget);
      expect(
        find.text('Long-press a card to change its frame'),
        findsOneWidget,
      );
    });

    testWidgets('is not drawn when there is no picker to teach', (
      tester,
    ) async {
      usePhoneViewport(tester);
      // No equip handler means long press opens room options, not 換相框.
      await tester.pumpWidget(buildView(showFrameHint: true));
      await settle(tester);

      expect(find.byType(RoomFrameLongPressHint), findsNothing);
    });

    testWidgets('is spent by a tap', (tester) async {
      usePhoneViewport(tester);
      var seen = 0;
      await tester.pumpWidget(
        buildView(
          onEquipRoomFrame: (_, _) async {},
          showFrameHint: true,
          onFrameHintSeen: () => seen++,
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(RoomFrameLongPressHint));
      await settle(tester);
      expect(seen, 1);

      // The stay ending afterwards must not report it a second time.
      await tester.pump(RoomFrameLongPressHint.visibleFor);
      expect(seen, 1);
    });

    testWidgets('is spent by its own stay ending', (tester) async {
      usePhoneViewport(tester);
      var seen = 0;
      await tester.pumpWidget(
        buildView(
          onEquipRoomFrame: (_, _) async {},
          showFrameHint: true,
          onFrameHintSeen: () => seen++,
        ),
      );
      await settle(tester);
      expect(seen, 0);

      await tester.pump(RoomFrameLongPressHint.visibleFor);
      await settle(tester);
      expect(seen, 1);
    });

    testWidgets('is spent by a player who already knows the gesture', (
      tester,
    ) async {
      usePhoneViewport(tester);
      var seen = 0;
      await tester.pumpWidget(
        buildView(
          onEquipRoomFrame: (_, _) async {},
          showFrameHint: true,
          onFrameHintSeen: () => seen++,
        ),
      );
      await settle(tester);

      await tester.longPress(find.byType(RoomFrameCard));
      await settle(tester);

      expect(seen, 1);
      expect(find.text('Change Frame'), findsOneWidget);
    });
  });

  testWidgets('a level-1 room sees the gated casings locked', (tester) async {
    usePhoneViewport(tester);
    final equipped = <RoomFrameStyle>[];
    await tester.pumpWidget(
      buildView(
        petLevel: 1,
        onEquipRoomFrame: (_, style) async {
          equipped.add(style);
        },
      ),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    // Every casing is still shown — the ladder is a goal, not a hidden menu.
    for (final style in RoomFrameSkins.displayOrder) {
      expect(swatchOf(style), findsOneWidget);
    }
    // 軟木板 / 金葉 / 夜光 are gated; the default and 拍立得 are not.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
    // Each locked swatch names the level it needs.
    expect(find.text('Lv 3'), findsOneWidget);
    expect(find.text('Lv 5'), findsOneWidget);
    expect(find.text('Lv 8'), findsOneWidget);

    // A locked miniature is drained and dimmed, so it reads as locked before
    // the label is read — and only the locked ones are.
    for (final style in RoomFrameSkins.displayOrder) {
      final drained = find.descendant(
        of: swatchOf(style),
        matching: find.byType(ColorFiltered),
      );
      final isGated = RoomFrameSkins.unlockLevel(style) > 1;
      expect(
        drained,
        isGated ? findsOneWidget : findsNothing,
        reason: '$style at Lv 1',
      );
    }

    // Tapping a locked swatch explains the gate and commits nothing.
    await tester.tap(swatchOf(RoomFrameStyle.nightGlow));
    await settle(tester);
    expect(find.textContaining('unlocks at room Lv 8'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(equipped, isEmpty);

    // Let the juice snackbar's auto-dismiss timer expire before the test ends.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('an unloaded pet summary does not hand out a gated casing', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      buildView(petLevel: null, onEquipRoomFrame: (_, _) async {}),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    // An unknown level reads as level 1 rather than as "everything unlocked".
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
  });

  testWidgets('the equipped casing stays pickable below its unlock level', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final equipped = <RoomFrameStyle>[];
    await tester.pumpWidget(
      buildView(
        petLevel: 1,
        roomFrameStyleByRoom: const {'room-1': RoomFrameStyle.nightGlow},
        onEquipRoomFrame: (_, style) async => equipped.add(style),
      ),
    );

    await tester.longPress(find.byType(RoomFrameCard));
    await settle(tester);

    // Lv 8 casing on a Lv 1 room: grandfathered, so only the other two gated
    // casings read as locked and the room can still re-select what it wears.
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));

    await tester.tap(swatchOf(RoomFrameStyle.original));
    await settle(tester);
    await tester.tap(swatchOf(RoomFrameStyle.nightGlow));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);

    // Re-selecting what it already wears is a no-op, not a lock.
    expect(equipped, isEmpty);
    final card = tester.widget<RoomFrameCard>(find.byType(RoomFrameCard));
    expect(card.skin.style, RoomFrameStyle.nightGlow);
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

    test('the ladder is the calibrated one', () {
      // Cut against the live level distribution; see RoomFrameSkins' docs for
      // the derivation. Locked in as a test because lowering a rung is free
      // but raising one retracts a casing a room already equipped.
      expect(RoomFrameSkins.unlockLevel(RoomFrameStyle.original), 1);
      expect(RoomFrameSkins.unlockLevel(RoomFrameStyle.polaroidClassic), 1);
      expect(RoomFrameSkins.unlockLevel(RoomFrameStyle.corkboard), 3);
      expect(RoomFrameSkins.unlockLevel(RoomFrameStyle.goldLeaf), 5);
      expect(RoomFrameSkins.unlockLevel(RoomFrameStyle.nightGlow), 8);
    });

    test('a level-1 room can still pick the default and one alternative', () {
      // 換相框 must never open as a menu of locks.
      expect(RoomFrameSkins.unlockedFor(1), {
        RoomFrameStyle.original,
        RoomFrameStyle.polaroidClassic,
      });
      expect(
        RoomFrameSkins.unlockedFor(1),
        contains(RoomFrameSkins.defaultStyle),
      );
      // An unknown level reads as 1, so a failed summary load cannot hand out
      // a gated casing.
      expect(RoomFrameSkins.unlockedFor(null), RoomFrameSkins.unlockedFor(1));
    });

    test('the ladder opens up monotonically', () {
      var previous = RoomFrameSkins.unlockedFor(1);
      for (var level = 2; level <= 12; level++) {
        final unlocked = RoomFrameSkins.unlockedFor(level);
        expect(
          unlocked.containsAll(previous),
          isTrue,
          reason: 'Lv $level must not take a casing back',
        );
        previous = unlocked;
      }
      expect(previous, RoomFrameStyle.values.toSet());
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

    test('every casing keeps the Lv chip readable', () {
      // The chip is 9.5pt bold — normal-sized text, so WCAG AA asks 4.5:1.
      // Measured against the chip's own fill (levelColor at 18% over the mat),
      // not against the mat, because that is what sits behind the glyphs.
      for (final skin in RoomFrameSkins.byStyle.values) {
        final chip = Color.alphaBlend(
          skin.levelColor.withValues(alpha: 0.18),
          skin.innerCardColor,
        );
        expect(
          _contrastRatio(skin.levelInk, chip),
          greaterThanOrEqualTo(4.5),
          reason: '${skin.style} Lv chip',
        );
      }
    });

    test('the Lv ink falls back to the accent only when that is readable', () {
      // nightGlow is the one casing whose accent already carries the contrast,
      // so it is the only one allowed to leave levelTextColor unset.
      for (final skin in RoomFrameSkins.byStyle.values) {
        if (skin.style == RoomFrameStyle.nightGlow) {
          expect(skin.levelTextColor, isNull);
          expect(skin.levelInk, skin.levelColor);
        } else {
          expect(skin.levelTextColor, isNotNull, reason: '${skin.style}');
        }
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
