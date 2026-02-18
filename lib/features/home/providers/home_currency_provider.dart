import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeCurrencySnapshot {
  const HomeCurrencySnapshot({
    required this.coins,
    required this.diamonds,
    required this.coinReward,
    required this.coinRewardEventId,
  });

  final int coins;
  final int diamonds;
  final int? coinReward;
  final int coinRewardEventId;
}

class HomeCurrencyNotifier extends Notifier<HomeCurrencySnapshot> {
  @override
  HomeCurrencySnapshot build() {
    return const HomeCurrencySnapshot(
      coins: 0,
      diamonds: 0,
      coinReward: null,
      coinRewardEventId: 0,
    );
  }

  void setSnapshot({
    required int coins,
    required int diamonds,
    required int? coinReward,
    required int coinRewardEventId,
  }) {
    state = HomeCurrencySnapshot(
      coins: coins,
      diamonds: diamonds,
      coinReward: coinReward,
      coinRewardEventId: coinRewardEventId,
    );
  }
}

final homeCurrencyProvider =
    NotifierProvider<HomeCurrencyNotifier, HomeCurrencySnapshot>(
      HomeCurrencyNotifier.new,
    );
