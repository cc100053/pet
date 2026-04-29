import 'economy_purchase_adapter.dart';

class ShopEconomyState {
  ShopEconomyState({
    required this.coins,
    required this.diamonds,
    required Map<String, int> inventory,
    required Set<String> ownedBackgroundIds,
    this.coinReward,
    required this.coinRewardEventId,
  }) : inventory = Map.unmodifiable(inventory),
       ownedBackgroundIds = Set.unmodifiable(ownedBackgroundIds);

  final int coins;
  final int diamonds;
  final Map<String, int> inventory;
  final Set<String> ownedBackgroundIds;
  final int? coinReward;
  final int coinRewardEventId;

  ShopEconomyStatePurchaseChange applyPurchaseResult({
    required String itemId,
    required bool isBackground,
    required EconomyPurchaseResult result,
  }) {
    var nextCoins = coins;
    var nextDiamonds = diamonds;
    var nextCoinReward = coinReward;
    var nextCoinRewardEventId = coinRewardEventId;
    int? coinGainForFeedback;

    final remainingCoins = result.remainingCoins;
    if (remainingCoins != null) {
      nextCoins = remainingCoins;
    }
    final remainingDiamonds = result.remainingDiamonds;
    if (remainingDiamonds != null) {
      nextDiamonds = remainingDiamonds;
    }

    final nextInventory = Map<String, int>.of(inventory);
    final inventoryQuantity = result.resolvedInventoryQuantity;
    if (inventoryQuantity != null) {
      nextInventory[itemId] = inventoryQuantity;
    }

    final coinBalance = result.coinBalance;
    if (coinBalance != null) {
      nextCoins = coinBalance;
      final coinGain = result.coinGain;
      if (coinGain != null && coinGain > 0) {
        nextCoinReward = coinGain;
        nextCoinRewardEventId += 1;
        coinGainForFeedback = coinGain;
      }
    }

    final nextOwnedBackgroundIds = Set<String>.of(ownedBackgroundIds);
    if (isBackground && !result.backgroundAlreadyOwned) {
      nextOwnedBackgroundIds.add(itemId);
    }

    return ShopEconomyStatePurchaseChange(
      state: ShopEconomyState(
        coins: nextCoins,
        diamonds: nextDiamonds,
        inventory: nextInventory,
        ownedBackgroundIds: nextOwnedBackgroundIds,
        coinReward: nextCoinReward,
        coinRewardEventId: nextCoinRewardEventId,
      ),
      coinGainForFeedback: coinGainForFeedback,
    );
  }
}

class ShopEconomyStatePurchaseChange {
  const ShopEconomyStatePurchaseChange({
    required this.state,
    required this.coinGainForFeedback,
  });

  final ShopEconomyState state;
  final int? coinGainForFeedback;

  bool get shouldPlayCoinGainSfx => coinGainForFeedback != null;
}
