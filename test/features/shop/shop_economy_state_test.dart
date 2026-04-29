import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/shop/services/economy_purchase_adapter.dart';
import 'package:pet/features/shop/services/shop_economy_state.dart';

void main() {
  group('ShopEconomyState', () {
    test('applies coin balance and inventory quantity', () {
      final state = _state(coins: 200, inventory: {'item-a': 1});

      final change = state.applyPurchaseResult(
        itemId: 'item-a',
        isBackground: false,
        result: const EconomyPurchaseResult(
          remainingCoins: 120,
          inventoryQuantity: 2,
        ),
      );

      expect(change.state.coins, 120);
      expect(change.state.diamonds, 9);
      expect(change.state.inventory, {'item-a': 2});
      expect(change.shouldPlayCoinGainSfx, isFalse);
    });

    test('prefers room inventory quantity over buyer inventory quantity', () {
      final state = _state(inventory: {'chair-a': 1});

      final change = state.applyPurchaseResult(
        itemId: 'chair-a',
        isBackground: false,
        result: const EconomyPurchaseResult(
          remainingDiamonds: 4,
          inventoryQuantity: 2,
          roomInventoryQuantity: 5,
        ),
      );

      expect(change.state.diamonds, 4);
      expect(change.state.inventory['chair-a'], 5);
    });

    test('applies candy exchange reward feedback from diamond purchase', () {
      final state = _state(coins: 250, coinRewardEventId: 7);

      final change = state.applyPurchaseResult(
        itemId: 'diamond-candy-pack',
        isBackground: false,
        result: const EconomyPurchaseResult(
          remainingDiamonds: 6,
          coinBalance: 750,
          coinGain: 500,
        ),
      );

      expect(change.state.coins, 750);
      expect(change.state.diamonds, 6);
      expect(change.state.coinReward, 500);
      expect(change.state.coinRewardEventId, 8);
      expect(change.coinGainForFeedback, 500);
      expect(change.shouldPlayCoinGainSfx, isTrue);
    });

    test('does not advance reward event for zero or negative coin gain', () {
      final state = _state(coins: 250, coinReward: 100, coinRewardEventId: 7);

      final change = state.applyPurchaseResult(
        itemId: 'diamond-candy-pack',
        isBackground: false,
        result: const EconomyPurchaseResult(coinBalance: 250, coinGain: 0),
      );

      expect(change.state.coins, 250);
      expect(change.state.coinReward, 100);
      expect(change.state.coinRewardEventId, 7);
      expect(change.shouldPlayCoinGainSfx, isFalse);
    });

    test(
      'adds newly owned backgrounds and preserves already-owned responses',
      () {
        final state = _state(ownedBackgroundIds: {'background-old'});

        final added = state.applyPurchaseResult(
          itemId: 'background-new',
          isBackground: true,
          result: const EconomyPurchaseResult(backgroundAlreadyOwned: false),
        );
        final alreadyOwned = added.state.applyPurchaseResult(
          itemId: 'background-owned',
          isBackground: true,
          result: const EconomyPurchaseResult(backgroundAlreadyOwned: true),
        );

        expect(added.state.ownedBackgroundIds, {
          'background-old',
          'background-new',
        });
        expect(alreadyOwned.state.ownedBackgroundIds, {
          'background-old',
          'background-new',
        });
      },
    );

    test('does not mutate caller-owned maps and sets', () {
      final inventory = {'item-a': 1};
      final backgrounds = {'background-a'};
      final state = _state(
        inventory: inventory,
        ownedBackgroundIds: backgrounds,
      );

      state.applyPurchaseResult(
        itemId: 'item-a',
        isBackground: false,
        result: const EconomyPurchaseResult(inventoryQuantity: 2),
      );

      expect(inventory, {'item-a': 1});
      expect(backgrounds, {'background-a'});
    });
  });
}

ShopEconomyState _state({
  int coins = 100,
  int diamonds = 9,
  Map<String, int> inventory = const <String, int>{},
  Set<String> ownedBackgroundIds = const <String>{},
  int? coinReward,
  int coinRewardEventId = 0,
}) {
  return ShopEconomyState(
    coins: coins,
    diamonds: diamonds,
    inventory: inventory,
    ownedBackgroundIds: ownedBackgroundIds,
    coinReward: coinReward,
    coinRewardEventId: coinRewardEventId,
  );
}
