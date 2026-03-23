import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/store/models/store_item.dart';
import 'package:pet/features/store/store_view.dart';
import 'package:pet/l10n/app_localizations.dart';

void main() {
  StoreItem buildBackgroundItem() {
    return StoreItem(
      id: 'bg-1',
      sku: 'background_test1',
      type: 'cosmetic',
      name: 'Moonlight Room',
      priceCoins: 200,
      priceDiamonds: 200,
      priceJpy: 120,
      description: 'A calm moonlit room backdrop.',
      iapProductId: null,
      iapType: null,
      rcEntitlementId: null,
      coinAmount: null,
      diamondAmount: null,
      iapCurrency: null,
      catalogCurrencyCode: 'JPY',
      category: 'background',
      emoji: null,
      backgroundKey: 'test1',
    );
  }

  testWidgets('shows the localized theme preview dialog', (tester) async {
    final item = buildBackgroundItem();
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () =>
                    showStoreThemePreviewDialog(context: context, item: item),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.storeThemePreviewTitle(item.localizedName(l10n))),
      findsOneWidget,
    );
    expect(find.text(l10n.commonClose), findsOneWidget);
  });
}
