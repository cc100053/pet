import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_ids.dart';
import 'admob_startup_service.dart';
import '../env.dart';

enum RewardedAdPlacement { doubleCoins }

enum RewardedAdAvailability { unavailable, loading, ready }

enum RewardedAdResultStatus { rewarded, dismissed, failed, unavailable }

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
  const RewardedAdContext({this.roomId, this.baseCoins, this.eventId});

  final String? roomId;
  final int? baseCoins;
  final String? eventId;
}

class RewardedAdRequest {
  const RewardedAdRequest({required this.placement, this.context});

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
    : this._(status: RewardedAdResultStatus.unavailable, errorMessage: message);

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

class RewardedAdsAdMobService implements RewardedAdsService {
  RewardedAdsAdMobService()
    : _state = ValueNotifier(
        RewardedAdState(
          availability: AdMobIds.isSupported
              ? RewardedAdAvailability.loading
              : RewardedAdAvailability.unavailable,
          message: AdMobIds.isSupported
              ? 'Loading rewarded ad...'
              : 'Rewarded ads are only enabled on iOS.',
        ),
      );

  final ValueNotifier<RewardedAdState> _state;
  RewardedAd? _rewardedAd;
  bool _initializing = false;
  bool _initialized = false;
  bool _loading = false;
  bool _showing = false;

  @override
  ValueListenable<RewardedAdState> get state => _state;

  @override
  Future<void> initialize({String? userId}) async {
    if (!AdMobIds.isSupported || _initialized || _initializing) {
      return;
    }
    _initializing = true;
    _setState(
      RewardedAdAvailability.loading,
      message: 'Loading rewarded ad...',
    );
    try {
      final startupResult = await AdMobStartupService.instance.initialize();
      if (!startupResult.initialized) {
        _setState(
          RewardedAdAvailability.unavailable,
          message: 'Rewarded ads are currently unavailable.',
        );
        return;
      }
      _initialized = true;
      await preload(RewardedAdPlacement.doubleCoins);
    } catch (error) {
      _setState(
        RewardedAdAvailability.unavailable,
        message: 'Rewarded ad failed to initialize: $error',
      );
    } finally {
      _initializing = false;
    }
  }

  @override
  Future<void> preload(RewardedAdPlacement placement) async {
    if (!AdMobIds.isSupported) {
      _setState(
        RewardedAdAvailability.unavailable,
        message: 'Rewarded ads are only enabled on iOS.',
      );
      return;
    }
    if (!_initialized) {
      _setState(
        RewardedAdAvailability.unavailable,
        message: 'Rewarded ads are still initializing.',
      );
      return;
    }
    if (_rewardedAd != null) {
      _setState(RewardedAdAvailability.ready);
      return;
    }
    if (_loading) {
      return;
    }
    _loading = true;
    _setState(
      RewardedAdAvailability.loading,
      message: 'Loading rewarded ad...',
    );

    await RewardedAd.load(
      adUnitId: AdMobIds.rewardedAdUnitId,
      request: AdMobStartupService.instance.createAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _setState(RewardedAdAvailability.ready);
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _rewardedAd = null;
          _setState(
            RewardedAdAvailability.unavailable,
            message: 'Rewarded ad unavailable: ${error.message}',
          );
        },
      ),
    );
  }

  @override
  Future<RewardedAdResult> show(RewardedAdRequest request) async {
    if (!AdMobIds.isSupported) {
      return const RewardedAdResult.unavailable(
        'Rewarded ads are only enabled on iOS.',
      );
    }
    if (!_initialized) {
      await initialize();
      if (!_initialized) {
        return const RewardedAdResult.unavailable(
          'Rewarded ads are currently unavailable.',
        );
      }
    }
    if (_showing) {
      return const RewardedAdResult.unavailable(
        'A rewarded ad is already open.',
      );
    }

    if (_rewardedAd == null) {
      await preload(request.placement);
      await _waitForLoadedAd();
    }
    final ad = _rewardedAd;
    if (ad == null) {
      return RewardedAdResult.unavailable(
        _state.value.message ?? 'Rewarded ad is not ready.',
      );
    }

    _showing = true;
    final completer = Completer<RewardedAdResult>();
    bool completed = false;
    bool rewarded = false;

    void completeOnce(RewardedAdResult value) {
      if (completed) {
        return;
      }
      completed = true;
      completer.complete(value);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _showing = false;
        if (!rewarded) {
          completeOnce(const RewardedAdResult.dismissed());
        }
        unawaited(preload(request.placement));
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _showing = false;
        completeOnce(RewardedAdResult.failed(error.message));
        unawaited(preload(request.placement));
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          rewarded = true;
          final rewardedAmount = reward.amount.floor();
          final rewardCoins = rewardedAmount > 0
              ? rewardedAmount
              : Env.adRewardCoins;
          completeOnce(
            RewardedAdResult.rewarded(
              RewardedAdReward(
                rewardCoins: rewardCoins,
                multiplierApplied: null,
                source: 'admob',
              ),
            ),
          );
        },
      );
      return await completer.future;
    } catch (error) {
      _showing = false;
      _rewardedAd = null;
      unawaited(preload(request.placement));
      return RewardedAdResult.failed('Failed to show rewarded ad: $error');
    }
  }

  Future<void> _waitForLoadedAd({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_rewardedAd != null || !_loading) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  @override
  Future<void> dispose() async {
    _rewardedAd?.dispose();
    _state.dispose();
  }

  void _setState(RewardedAdAvailability availability, {String? message}) {
    _state.value = RewardedAdState(
      availability: availability,
      message: message,
    );
  }
}

class RewardedAdsStubService implements RewardedAdsService {
  RewardedAdsStubService()
    : _state = ValueNotifier(
        RewardedAdState(
          availability: RewardedAdAvailability.unavailable,
          message: 'Rewarded ads are not available yet.',
        ),
      );

  final ValueNotifier<RewardedAdState> _state;

  @override
  ValueListenable<RewardedAdState> get state => _state;

  @override
  Future<void> initialize({String? userId}) async {}

  @override
  Future<void> preload(RewardedAdPlacement placement) async {}

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
  final service = AdMobIds.isSupported
      ? RewardedAdsAdMobService()
      : RewardedAdsStubService();
  ref.onDispose(service.dispose);
  return service;
});
