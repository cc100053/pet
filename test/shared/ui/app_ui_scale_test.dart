import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/ui/app_ui_scale.dart';

void main() {
  group('appUiScale', () {
    test('returns compact scale for compact widths', () {
      expect(appUiScale(360, isIosTabletDisplay: false), 0.76);
    });

    test('returns regular scale for regular widths', () {
      expect(appUiScale(390, isIosTabletDisplay: false), 0.9);
      expect(appUiScale(430, isIosTabletDisplay: false), 0.9);
    });

    test('returns expanded scale for expanded non-tablet widths', () {
      expect(appUiScale(431, isIosTabletDisplay: false), 1.0);
    });

    test('normalizes tablet widths to expanded scale', () {
      expect(appUiScale(1024, isIosTabletDisplay: false), 1.0);
    });

    test('forces full scale for iPad compatibility viewport widths', () {
      expect(appUiScale(320, isIosTabletDisplay: true), 1.0);
      expect(appUiScale(390, isIosTabletDisplay: true), 1.0);
    });

    test('falls back safely for invalid widths', () {
      expect(appUiScale(double.nan, isIosTabletDisplay: false), 1.0);
      expect(appUiScale(0, isIosTabletDisplay: false), 1.0);
    });
  });
}
