import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/home/widgets/home_responsive.dart';

void main() {
  group('HomeResponsiveSpec.fromWidth', () {
    test('uses compact tier for compact widths', () {
      final spec = HomeResponsiveSpec.fromWidth(360, isIosTabletDisplay: false);
      expect(spec.isCompact, isTrue);
    });

    test('uses regular tier for regular widths', () {
      final spec = HomeResponsiveSpec.fromWidth(390, isIosTabletDisplay: false);
      expect(spec.isRegular, isTrue);
    });

    test('uses expanded tier for expanded non-tablet widths', () {
      final spec = HomeResponsiveSpec.fromWidth(431, isIosTabletDisplay: false);
      expect(spec.isExpanded, isTrue);
    });

    test('normalizes tablet widths to expanded tier', () {
      final spec = HomeResponsiveSpec.fromWidth(
        1024,
        isIosTabletDisplay: false,
      );
      expect(spec.isExpanded, isTrue);
    });

    test('forces expanded tier for iPad compatibility viewport widths', () {
      final spec = HomeResponsiveSpec.fromWidth(320, isIosTabletDisplay: true);
      expect(spec.isExpanded, isTrue);
    });
  });
}
