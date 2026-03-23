import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/store/models/store_item.dart';
import 'package:pet/features/store/store_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  StoreItem buildSubscriptionItem() {
    return StoreItem(
      id: 'sub-1',
      sku: 'subscription_premium_monthly',
      type: 'subscription',
      name: 'Pro Monthly Membership',
      priceCoins: null,
      priceDiamonds: null,
      priceJpy: 300,
      description: 'Monthly Pro plan.',
      iapProductId: 'Petmonthly',
      iapType: 'subscription',
      rcEntitlementId: 'Petmonthly',
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: 'JPY',
      category: 'subscription',
      emoji: '⭐',
      backgroundKey: null,
    );
  }

  MaterialApp buildApp({required Locale locale, required Widget child}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows active localized owned state and blocks repurchase', (
    tester,
  ) async {
    final item = buildSubscriptionItem();
    var purchaseCount = 0;

    await tester.pumpWidget(
      buildApp(
        locale: const Locale('en'),
        child: StoreFeaturedBanner(
          items: [item],
          onPurchase: (_) => purchaseCount++,
          findPackage: (_) => null,
          findStoreProduct: (_) => null,
          activeEntitlements: const {'Petmonthly'},
          iapConfigured: true,
          isPurchasing: false,
        ),
      ),
    );

    expect(find.text('Premium'), findsWidgets);
    expect(find.text('Pro Monthly Membership'), findsWidgets);
    expect(find.text('Active'), findsOneWidget);
    expect(
      find.text('1 month • Auto-renews monthly. Cancel anytime.'),
      findsOneWidget,
    );
    expect(find.text('Owned'), findsOneWidget);

    await tester.tap(find.text('Owned'));
    await tester.pump();

    expect(purchaseCount, 0);
  });

  testWidgets('uses localized premium tag without stripping the title', (
    tester,
  ) async {
    final item = buildSubscriptionItem();

    await tester.pumpWidget(
      buildApp(
        locale: const Locale('ja'),
        child: StoreFeaturedBanner(
          items: [item],
          onPurchase: (_) {},
          findPackage: (_) => null,
          findStoreProduct: (_) => null,
          activeEntitlements: const {},
          iapConfigured: true,
          isPurchasing: false,
        ),
      ),
    );

    expect(find.text('プレミアム'), findsWidgets);
    expect(find.text('Pro 月額メンバーシップ'), findsWidgets);
    expect(find.text('Premium'), findsNothing);
  });
}
