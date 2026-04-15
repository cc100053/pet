import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ads/admob_ids.dart';
import '../../services/ads/admob_startup_service.dart';

class AdMobBannerSlot extends StatefulWidget {
  const AdMobBannerSlot({super.key});

  @override
  State<AdMobBannerSlot> createState() => _AdMobBannerSlotState();
}

class _AdMobBannerSlotState extends State<AdMobBannerSlot> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBanner());
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdMobIds.isBannerViewSupported || !_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    final ad = _bannerAd!;
    return SafeArea(
      top: false,
      child: Container(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        color: Colors.white,
        alignment: Alignment.center,
        child: AdWidget(ad: ad),
      ),
    );
  }

  Future<void> _loadBanner() async {
    if (!AdMobIds.isBannerViewSupported) {
      return;
    }

    final startupResult = await AdMobStartupService.instance.initialize();
    if (!startupResult.initialized || !mounted) {
      return;
    }

    final bannerAd = BannerAd(
      adUnitId: AdMobIds.bannerAdUnitId,
      size: AdSize.banner,
      request: AdMobStartupService.instance.createAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _loaded = false;
            _bannerAd = null;
          });
        },
      ),
    );
    bannerAd.load();
  }
}
