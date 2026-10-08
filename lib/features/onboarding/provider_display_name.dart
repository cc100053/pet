import 'package:flutter/widgets.dart' show StringCharacters;

/// Name offered by the sign-in provider, to prefill the profile step.
/// Prefers `given_name` (Google, and Apple via `SignInView`), then full name.
/// Empty when the provider shared none.
String providerDisplayName(Map<String, dynamic>? metadata, int maxLength) {
  for (final key in const ['given_name', 'full_name', 'name']) {
    final value = metadata?[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value.characters.take(maxLength).toString();
    }
  }
  return '';
}
