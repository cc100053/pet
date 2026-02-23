import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TrackingConsentService {
  TrackingConsentService._();

  static final TrackingConsentService instance = TrackingConsentService._();

  Future<TrackingStatus>? _inFlightRequest;

  Future<bool> ensureTrackingAuthorization() async {
    final status = await requestAuthorizationIfNeeded();
    return status == TrackingStatus.authorized;
  }

  Future<TrackingStatus> requestAuthorizationIfNeeded() {
    final existing = _inFlightRequest;
    if (existing != null) {
      return existing;
    }
    final requestFuture = _requestAuthorizationIfNeeded();
    _inFlightRequest = requestFuture;
    return requestFuture.whenComplete(() {
      if (identical(_inFlightRequest, requestFuture)) {
        _inFlightRequest = null;
      }
    });
  }

  Future<TrackingStatus> _requestAuthorizationIfNeeded() async {
    if (kIsWeb || !Platform.isIOS) {
      return TrackingStatus.authorized;
    }

    var status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) {
      return status;
    }

    final isResumed = await _waitUntilResumed();
    if (!isResumed) {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    status = await AppTrackingTransparency.requestTrackingAuthorization();
    return status;
  }

  Future<bool> _waitUntilResumed() async {
    final binding = WidgetsBinding.instance;
    if (binding.lifecycleState == AppLifecycleState.resumed) {
      return true;
    }

    final completer = Completer<void>();
    final observer = _ResumedObserver(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    binding.addObserver(observer);
    try {
      if (binding.lifecycleState == AppLifecycleState.resumed) {
        return true;
      }
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      return binding.lifecycleState == AppLifecycleState.resumed;
    } finally {
      binding.removeObserver(observer);
    }
  }
}

class _ResumedObserver extends WidgetsBindingObserver {
  _ResumedObserver(this.onResumed);

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
