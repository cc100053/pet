import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ads/rewarded_ads_service.dart';

class RewardedAdButton extends ConsumerStatefulWidget {
  const RewardedAdButton({
    super.key,
    required this.request,
    required this.onResult,
    this.readyLabel = 'Watch ad',
    this.loadingLabel = 'Loading ad...',
    this.unavailableLabel = 'Ad unavailable',
  });

  final RewardedAdRequest request;
  final ValueChanged<RewardedAdResult> onResult;
  final String readyLabel;
  final String loadingLabel;
  final String unavailableLabel;

  @override
  ConsumerState<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends ConsumerState<RewardedAdButton> {
  bool _showing = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(rewardedAdsServiceProvider);

    return ValueListenableBuilder<RewardedAdState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        final isReady = state.availability == RewardedAdAvailability.ready;
        final isLoading =
            _showing || state.availability == RewardedAdAvailability.loading;
        final label = isLoading
            ? widget.loadingLabel
            : (isReady ? widget.readyLabel : widget.unavailableLabel);

        return FilledButton(
          onPressed: isReady && !_showing ? () => _show(service) : null,
          child: Text(label),
        );
      },
    );
  }

  Future<void> _show(RewardedAdsService service) async {
    setState(() {
      _showing = true;
    });

    final result = await service.show(widget.request);
    if (!mounted) {
      return;
    }

    setState(() {
      _showing = false;
    });

    widget.onResult(result);
  }
}
