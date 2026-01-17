import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../env.dart';

class RevenueCatService {
  bool _configured = false;

  bool get isAvailable => _apiKey != null;

  String? get _apiKey {
    if (kIsWeb) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Env.revenueCatApiKeyIos;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Env.revenueCatApiKeyAndroid;
    }
    return null;
  }

  Future<bool> configure({String? appUserId}) async {
    if (!isAvailable) {
      return false;
    }

    if (_configured) {
      if (appUserId != null && appUserId.isNotEmpty) {
        await _logIn(appUserId);
      }
      return true;
    }

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final config = PurchasesConfiguration(_apiKey!);
    await Purchases.configure(config);

    if (appUserId != null && appUserId.isNotEmpty) {
      await _logIn(appUserId);
    }

    _configured = true;
    return true;
  }

  Future<Offerings?> getOfferings() async {
    if (!isAvailable) {
      return null;
    }
    return Purchases.getOfferings();
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!isAvailable) {
      return null;
    }
    return Purchases.getCustomerInfo();
  }

  Future<PurchaseResult?> purchasePackage(Package package) async {
    if (!isAvailable) {
      return null;
    }
    final result = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return result;
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!isAvailable) {
      return null;
    }
    return Purchases.restorePurchases();
  }

  Future<void> _logIn(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
    } catch (_) {
      // Ignore log-in failures to avoid blocking purchases.
    }
  }
}
