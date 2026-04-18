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

  test('buildAvatarUrlWithFraming writes stable avatar_view_v2 zoom', () {
    final output = buildAvatarUrlWithFraming(
      'https://example.com/a.webp#avatar_align=0.200,0.300',
      alignment: const Alignment(-0.25, 0.5),
      scale: 2.25,
    );

    expect(
      output,
      'https://example.com/a.webp#avatar_view_v2=-0.250,0.500,2.250',
    );
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

  test('parseAvatarUrlWithAlignment ignores NaN avatar_view fragment', () {
    final parsed = parseAvatarUrlWithAlignment(
      'https://example.com/a.webp#avatar_view=NaN,0.200,2.500',
    );

    expect(parsed.imageUrl, 'https://example.com/a.webp');
    expect(parsed.alignment, Alignment.center);
    expect(parsed.scale, 1);
    expect(parsed.scaleMode, AvatarScaleMode.relativeZoom);
  });

  test(
    'parseAvatarUrlWithAlignment ignores infinite avatar_view_v2 fragment',
    () {
      final parsed = parseAvatarUrlWithAlignment(
        'https://example.com/a.webp#avatar_view_v2=0.000,Infinity,1.700',
      );

      expect(parsed.imageUrl, 'https://example.com/a.webp');
      expect(parsed.alignment, Alignment.center);
      expect(parsed.scale, 1);
      expect(parsed.scaleMode, AvatarScaleMode.relativeZoom);
    },
  );

  test(
    'parseAvatarUrlWithAlignment ignores infinite avatar_align fragment',
    () {
      final parsed = parseAvatarUrlWithAlignment(
        'https://example.com/a.webp#avatar_align=-Infinity,0.200',
      );

      expect(parsed.imageUrl, 'https://example.com/a.webp');
      expect(parsed.alignment, Alignment.center);
      expect(parsed.scale, 1);
      expect(parsed.scaleMode, AvatarScaleMode.relativeZoom);
    },
  );

  test('AvatarFramingTransform clamps wide images to horizontal pan only', () {
    final transform = AvatarFramingTransform.resolve(
      viewport: const Size.square(100),
      imageAspectRatio: 2,
      alignment: const Alignment(0.8, 0.8),
      scale: 1,
    );

    expect(transform.baseImageSize, const Size(100, 50));
    expect(transform.minFillScale, closeTo(2, 0.0001));
    expect(transform.maxPan.dx, closeTo(50, 0.0001));
    expect(transform.maxPan.dy, closeTo(0, 0.0001));
    expect(transform.alignment.x, closeTo(0.8, 0.0001));
    expect(transform.alignment.y, closeTo(0, 0.0001));
    expect(transform.offset.dx, closeTo(40, 0.0001));
    expect(transform.offset.dy, closeTo(0, 0.0001));
  });

  test('AvatarFramingTransform clamps tall images to vertical pan only', () {
    final transform = AvatarFramingTransform.resolve(
      viewport: const Size.square(100),
      imageAspectRatio: 0.5,
      alignment: const Alignment(0.8, -0.8),
      scale: 1,
    );

    expect(transform.baseImageSize, const Size(50, 100));
    expect(transform.minFillScale, closeTo(2, 0.0001));
    expect(transform.maxPan.dx, closeTo(0, 0.0001));
    expect(transform.maxPan.dy, closeTo(50, 0.0001));
    expect(transform.alignment.x, closeTo(0, 0.0001));
    expect(transform.alignment.y, closeTo(-0.8, 0.0001));
    expect(transform.offset.dx, closeTo(0, 0.0001));
    expect(transform.offset.dy, closeTo(-40, 0.0001));
  });

  test('AvatarFramingTransform clamps offset back to normalized bounds', () {
    final transform = AvatarFramingTransform.resolve(
      viewport: const Size.square(100),
      imageAspectRatio: 2,
      alignment: Alignment.center,
      scale: 2,
    );

    final alignment = transform.alignmentForOffset(const Offset(999, -999));

    expect(alignment.x, closeTo(1, 0.0001));
    expect(alignment.y, closeTo(-1, 0.0001));
  });

  test('AvatarFramingTransform normalizes invalid scale and aspect ratio', () {
    final transform = AvatarFramingTransform.resolve(
      viewport: Size.zero,
      imageAspectRatio: double.nan,
      alignment: const Alignment(2, -2),
      scale: double.infinity,
    );

    expect(transform.viewport, const Size(1, 1));
    expect(transform.imageAspectRatio, 1);
    expect(transform.relativeScale, avatarRelativeMaxScale);
    expect(transform.alignment.x, closeTo(1, 0.0001));
    expect(transform.alignment.y, closeTo(-1, 0.0001));
  });
}
