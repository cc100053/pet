import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Warm paper with a faint graph-paper grid, the "Mori" screen backdrop.
class MoriPaperBackground extends StatelessWidget {
  const MoriPaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.paper),
      child: CustomPaint(painter: const _GridPainter(), child: child),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  static const double _step = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.wood.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Small decorative kana label (e.g. おへやえらび) shown above a heading.
///
/// Japanese locale only: other locales get nothing, so the kana never stands
/// in for translated copy. Kiwi Maru is bundled as a kana-only subset, so any
/// glyph outside it falls back to M PLUS Rounded rather than tofu.
class KanaEyebrow extends StatelessWidget {
  const KanaEyebrow(this.text, {super.key, this.color = AppTheme.leafDeep});

  final String text;
  final Color color;

  static const String fontFamily = 'KiwiMaruKana';

  @override
  Widget build(BuildContext context) {
    if (Localizations.localeOf(context).languageCode != 'ja') {
      return const SizedBox.shrink();
    }
    final fallback = GoogleFonts.mPlusRounded1c().fontFamily;
    return Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: [?fallback],
        fontSize: 10,
        letterSpacing: 2,
        height: 1.2,
        color: color,
      ),
    );
  }
}
