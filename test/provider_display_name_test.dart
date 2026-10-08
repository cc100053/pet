import 'package:flutter_test/flutter_test.dart';
import 'package:pet/features/onboarding/provider_display_name.dart';

void main() {
  test('prefers given_name, then full_name, then name', () {
    expect(
      providerDisplayName({
        'given_name': ' Sam ',
        'full_name': 'Sam Lee',
        'name': 'x',
      }, 20),
      'Sam',
    );
    expect(
      providerDisplayName({'full_name': 'Sam Lee', 'name': 'x'}, 20),
      'Sam Lee',
    );
    expect(providerDisplayName({'name': '山田花子'}, 20), '山田花子');
  });

  test('empty when the provider shared no name', () {
    expect(providerDisplayName(null, 20), '');
    expect(providerDisplayName({'given_name': '  ', 'email': 'a@b.c'}, 20), '');
  });

  test('truncates by user-perceived characters', () {
    expect(
      providerDisplayName({'name': 'Mochi👨‍👩‍👧Mochi'}, 6),
      'Mochi👨‍👩‍👧',
    );
  });
}
