import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet/shared/utils/avatar_display_position.dart';

void main() {
  test('parseAvatarUrlWithAlignment parses base URL and alignment', () {
    final parsed = parseAvatarUrlWithAlignment(
      'https://example.com/a.webp#avatar_align=0.400,-0.250',
    );

    expect(parsed.imageUrl, 'https://example.com/a.webp');
    expect(parsed.alignment.x, closeTo(0.4, 0.0001));
    expect(parsed.alignment.y, closeTo(-0.25, 0.0001));
    expect(parsed.scale, 1);
    expect(parsed.scaleMode, AvatarScaleMode.legacyAbsolute);
  });

  test('buildAvatarUrlWithFraming omits fragment when centered', () {
    final output = buildAvatarUrlWithFraming(
      'https://example.com/a.webp#avatar_align=0.200,0.300',
      alignment: Alignment.center,
      scale: 1,
    );

    expect(output, 'https://example.com/a.webp');
  });

  test('parseAvatarUrlWithAlignment parses avatar_view scale', () {
    final parsed = parseAvatarUrlWithAlignment(
      'https://example.com/a.webp#avatar_view=-0.100,0.200,2.500',
    );
    expect(parsed.alignment.x, closeTo(-0.1, 0.0001));
    expect(parsed.alignment.y, closeTo(0.2, 0.0001));
    expect(parsed.scale, closeTo(2.5, 0.0001));
    expect(parsed.scaleMode, AvatarScaleMode.legacyAbsolute);
  });

  test('parseAvatarUrlWithAlignment parses avatar_view_v2 relative zoom', () {
    final parsed = parseAvatarUrlWithAlignment(
      'https://example.com/a.webp#avatar_view_v2=0.000,0.000,1.700',
    );
    expect(parsed.scale, closeTo(1.7, 0.0001));
    expect(parsed.scaleMode, AvatarScaleMode.relativeZoom);
  });
}
