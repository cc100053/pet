import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RewardedAdPlacement {
  doubleCoins,
}

enum RewardedAdAvailability {
  unavailable,
  loading,
  ready,
}

enum RewardedAdResultStatus {
  rewarded,
  dismissed,
  failed,
  unavailable,
}

class RewardedAdState {
  RewardedAdState({
    required this.availability,
    this.message,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc();

  final RewardedAdAvailability availability;
  final String? message;
  final DateTime updatedAt;

  bool get isReady => availability == RewardedAdAvailability.ready;
}

class RewardedAdContext {
  const RewardedAdContext({
    this.roomId,
    this.baseCoins,
    this.eventId,
  });

  final String? roomId;
  // baseCoins is the pre-reward amount so later multipliers stay deterministic.
  final int? baseCoins;
  final String? eventId;
}

class RewardedAdRequest {
  const RewardedAdRequest({
    required this.placement,
    this.context,
  });

  final RewardedAdPlacement placement;
  final RewardedAdContext? context;
}

class RewardedAdReward {
  const RewardedAdReward({
    required this.rewardCoins,
    this.multiplierApplied,
    this.source,
  });

  final int rewardCoins;
  final double? multiplierApplied;
  final String? source;
}

class RewardedAdResult {
  const RewardedAdResult._({
    required this.status,
    this.reward,
    this.errorMessage,
  });

  const RewardedAdResult.rewarded(RewardedAdReward reward)
      : this._(status: RewardedAdResultStatus.rewarded, reward: reward);

  const RewardedAdResult.dismissed()
      : this._(status: RewardedAdResultStatus.dismissed);

  const RewardedAdResult.failed(String message)
      : this._(status: RewardedAdResultStatus.failed, errorMessage: message);

  const RewardedAdResult.unavailable(String message)
      : this._(
          status: RewardedAdResultStatus.unavailable,
          errorMessage: message,
        );

  final RewardedAdResultStatus status;
  final RewardedAdReward? reward;
  final String? errorMessage;

  bool get isRewarded => status == RewardedAdResultStatus.rewarded;
}

abstract class RewardedAdsService {
  ValueListenable<RewardedAdState> get state;

  Future<void> initialize({String? userId});

  Future<void> preload(RewardedAdPlacement placement);

  Future<RewardedAdResult> show(RewardedAdRequest request);

  Future<void> dispose();
}

class RewardedAdsStubService implements RewardedAdsService {
  RewardedAdsStubService()
      : _state = ValueNotifier(
          RewardedAdState(
            availability: RewardedAdAvailability.unavailable,
            message: 'Rewarded ads not configured.',
          ),
        );

  final ValueNotifier<RewardedAdState> _state;

  @override
  ValueListenable<RewardedAdState> get state => _state;

  @override
  Future<void> initialize({String? userId}) async {
    // Intentionally a no-op for the stub implementation.
  }

  @override
  Future<void> preload(RewardedAdPlacement placement) async {
    // Intentionally a no-op for the stub implementation.
  }

  @override
  Future<RewardedAdResult> show(RewardedAdRequest request) async {
    return const RewardedAdResult.unavailable(
      'Rewarded ads are not available yet.',
    );
  }

  @override
  Future<void> dispose() async {
    _state.dispose();
  }
}

final rewardedAdsServiceProvider = Provider<RewardedAdsService>((ref) {
  final service = RewardedAdsStubService();
  ref.onDispose(service.dispose);
  return service;
});
