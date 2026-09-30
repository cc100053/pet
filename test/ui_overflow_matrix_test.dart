// Layout overflow sweep for the Mori UI surfaces: every supported locale ×
// phone widths (SE 1st gen → Pro Max) × default and max user text scale.
// Text scaling mirrors MaterialApp.builder in lib/app/app.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/room_selection_view.dart';
import 'package:pet/features/home/widgets/home_bottom_nav_bar.dart';
import 'package:pet/features/home/widgets/home_game_status_bar.dart';
import 'package:pet/features/shop/models/shop_item.dart';
import 'package:pet/features/shop/shop_view.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/app_ui_scale.dart';
import 'package:pet/shared/ui/balanced_text.dart';

const _phones = <Size>[
  Size(320, 568), // iPhone SE 1st gen
  Size(375, 667), // iPhone SE 2/3, mini-class widths
  Size(402, 874), // iPhone 17/18 Pro
  Size(440, 956), // Pro Max
];
const _userTextScales = <double>[1.0, kMaxUserTextScale];

ShopItem _item({
  required String id,
  String category = 'furniture',
  String type = 'consumable',
  int? priceCoins,
  int? priceDiamonds,
  String? iapProductId,
  String? iapType,
}) {
  return ShopItem(
    id: id,
    sku: id,
    type: type,
    name: 'Fluffy Deluxe Sofa',
    priceCoins: priceCoins,
    priceDiamonds: priceDiamonds,
    priceJpy: iapProductId == null ? null : 300,
    description: null,
    iapProductId: iapProductId,
    iapType: iapType,
    rcEntitlementId: iapProductId,
    coinAmount: null,
    diamondAmount: null,
    iapCurrency: null,
    catalogCurrencyCode: 'JPY',
    category: category,
    emoji: '🎁',
    backgroundKey: null,
  );
}

Widget _app(Locale locale, Size phone, double userScale, WidgetBuilder body) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) {
      final scale = appUiScale(phone.width, isIosTabletDisplay: false);
      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(userScale * scale)),
        child: child!,
      );
    },
    home: Scaffold(body: Builder(builder: body)),
  );
}

Future<void> _sweep(
  WidgetTester tester,
  String surface,
  WidgetBuilder body,
) async {
  final failures = <String>[];
  final details = <FlutterErrorDetails>[];
  final reportError = FlutterError.onError;
  FlutterError.onError = (d) {
    details.add(d);
    reportError?.call(d);
  };
  for (final locale in AppLocalizations.supportedLocales) {
    for (final phone in _phones) {
      for (final userScale in _userTextScales) {
        tester.view.physicalSize = phone;
        tester.view.devicePixelRatio = 1;
        // Fresh tree per case: a RenderFlex reports its overflow only once.
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('$locale-$phone-$userScale'),
            child: _app(locale, phone, userScale, body),
          ),
        );
        // Pet sprites animate forever: pump bounded time, never settle.
        await tester.pump(const Duration(milliseconds: 400));
        if (tester.takeException() != null) {
          final where = details
              .map((d) => d.toString().split('\n'))
              .expand((lines) => lines)
              .where((line) => line.contains('file:///'))
              .map((line) => line.trim().split('/lib/').last)
              .toSet()
              .join(', ');
          failures.add(
            '$surface  $locale  ${phone.width.toInt()}w  '
            'text×$userScale: $where',
          );
        }
        details.clear();
      }
    }
  }
  FlutterError.onError = reportError;
  addTearDown(tester.view.reset);
  expect(failures, isEmpty, reason: failures.join('\n'));
}

void main() {
  // Phrase-aware wrapping makes longer unbreakable runs; check they still fit.
  setUpAll(() => PhraseBreaks.load());

  testWidgets('room selection fits every locale and phone', (tester) async {
    await _sweep(
      tester,
      'RoomSelectionView',
      (context) => RoomSelectionView(
        rooms: [
          for (final id in ['a', 'b', 'c'])
            {
              'id': 'room-$id',
              'pet_name': 'Mochimochi-$id',
              'pet_type': 'ghost',
              'pet_health': 0.8,
              'unread_count': 99,
            },
        ],
        onCreateRoom: () {},
        onJoinRoom: () {},
        onSelectRoom: (_) {},
        onLeaveRoom: (_) {},
        creatingRoom: false,
        joiningRoom: false,
        selectedRoomId: 'room-a',
      ),
    );
  });

  testWidgets('home status bar and dock fit every locale and phone', (
    tester,
  ) async {
    await _sweep(tester, 'Home HUD', (context) {
      final l10n = AppLocalizations.of(context)!;
      return Column(
        children: [
          HomeGameStatusBar(
            petAvatar: const ColoredBox(color: Colors.blue),
            expProgress: 0.4,
            level: 14,
            petName: 'Mochimochi',
            healthValue: 0.7,
            coins: 99999,
            diamonds: 9999,
            onPetTap: () {},
            onStoreTap: () {},
            onInviteTap: () {},
            inviteLabel: l10n.roomInviteCta,
            onInventoryTap: () {},
            inventoryLabel: l10n.roomInventoryCta,
          ),
          const Spacer(),
          HomeBottomNavBar(
            onHome: () {},
            onCalendar: () {},
            onCamera: () {},
            onStore: () {},
            onChat: () {},
            chatHasUnread: true,
          ),
        ],
      );
    });
  });

  testWidgets('shop Pro banner fits every locale and phone', (tester) async {
    await _sweep(
      tester,
      'ShopFeaturedBanner',
      (context) => SingleChildScrollView(
        child: ShopFeaturedBanner(
          items: [
            _item(
              id: 'sub',
              category: 'subscription',
              type: 'subscription',
              iapProductId: 'Petmonthly',
              iapType: 'subscription',
            ),
          ],
          onPurchase: (_) {},
          findPackage: (_) => null,
          findStoreProduct: (_) => null,
          isProUser: false,
          activeEntitlements: const {},
          iapConfigured: true,
          isPurchasing: false,
          scrollController: ScrollController(),
        ),
      ),
    );
  });

  testWidgets('shop item cards fit every locale and phone', (tester) async {
    final items = [
      _item(id: 'coin', priceCoins: 99999),
      _item(id: 'diamond', priceDiamonds: 9999, category: 'utility'),
    ];
    await _sweep(tester, 'ShopGridItemCard', (context) {
      // Mirrors the shop grid: 16pt side padding, 2 columns, 12pt gap, 1.1.
      final width = (MediaQuery.sizeOf(context).width - 32 - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final item in items)
            for (final owned in [0, 3])
              SizedBox(
                width: width,
                height: width / 1.1,
                child: ShopGridItemCard(
                  item: item,
                  isOwned: owned > 0,
                  ownedQuantity: owned,
                  maxOwnedQuantity: 5,
                  isIap: false,
                  priceString: '',
                  canAffordCoins: true,
                  canAffordDiamonds: true,
                  canBuyIap: false,
                  hasDepartedPets: false,
                  onOpenThemePreview: () {},
                  onBuyIap: () {},
                  onBuyCoins: () {},
                  onBuyDiamonds: () {},
                  onHandleLetter: () {},
                  onUsePetTicket: () {},
                ),
              ),
        ],
      );
    });
  });

  testWidgets('shop room delivery tag and picker fit every locale and phone', (
    tester,
  ) async {
    const rooms = [
      ShopRoomTarget(
        roomId: 'a',
        petName: 'Mochimochi Dango Pudding',
        petAssetPath: 'assets/pet/cat/cat_stay.gif',
      ),
      ShopRoomTarget(
        roomId: 'b',
        petName: 'Kuro',
        petAssetPath: 'assets/pet/ghost/ghost_stay.gif',
      ),
    ];
    await _sweep(tester, 'ShopDeliveryTag', (context) {
      // Compact tag mirrors the new-items popup body: centered juice toast
      // (24pt margins, 16pt padding) minus the leading gap and close button.
      final popupBodyWidth = MediaQuery.sizeOf(context).width - 48 - 32 - 62;
      return SingleChildScrollView(
        child: Column(
          children: [
            ShopDeliveryTag(target: rooms.first, onSwitch: () {}),
            SizedBox(
              width: popupBodyWidth,
              child: ShopDeliveryTag(
                target: rooms.first,
                compact: true,
                onSwitch: () {},
              ),
            ),
            const ShopRoomPickerSheet(
              title: 'Which room is it for?',
              rooms: rooms,
              selectedRoomId: 'a',
            ),
          ],
        ),
      );
    });
  });
}
