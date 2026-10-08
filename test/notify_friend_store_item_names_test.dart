import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Purchase push notifications name the item via `localizedStoreItemNames` in
/// notify_friend/l10n.ts; a missing sku falls back to the raw sku string
/// ("furniture_cactus"). Every furniture and background sku the app can name
/// must be mapped in every push locale.
void main() {
  test(
    'every app-named furniture and background sku has a push name in all locales',
    () {
      final app = File(
        'lib/features/shop/shop_item_localization.dart',
      ).readAsStringSync();
      final l10n = File(
        'supabase/functions/notify_friend/l10n.ts',
      ).readAsStringSync();
      final table = l10n.substring(
        l10n.indexOf('const localizedStoreItemNames'),
        l10n.indexOf('function normalizeLocale'),
      );

      final skus = RegExp(
        r"case '((?:furniture|background)_[a-z0-9_]+)'",
      ).allMatches(app).map((m) => m.group(1)!).toSet();
      expect(skus, contains('furniture_pumpkin_lantern'));
      expect(skus, contains('background_ghost_sky'));

      for (final sku in skus) {
        expect(
          RegExp('\\b$sku:').allMatches(table).length,
          5,
          reason: '$sku must appear once in each of en/ja/ko/zh/zh-TW',
        );
      }
    },
  );
}
