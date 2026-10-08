import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/balanced_text.dart';
import '../../pet/pet_animated_image.dart';

/// The shareable invite: the pet as a polaroid with its code. Shown in the
/// invite dialog and captured as the shared image, so what you see is what
/// your friend gets.
class InvitePolaroidCard extends StatelessWidget {
  const InvitePolaroidCard({
    super.key,
    required this.petAsset,
    required this.caption,
    required this.code,
  });

  final String petAsset;
  final String caption;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.ink, width: 2.5),
          boxShadow: const [
            BoxShadow(color: AppTheme.softLine, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.kinako,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: PetAnimatedImage(
                sourceAsset: petAsset,
                width: 130,
                height: 130,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            BalancedText(
              caption,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.leafStrong, width: 2),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: AppTheme.leafDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the [RepaintBoundary] under [key] to a PNG for the share sheet.
/// Returns null if it is not laid out yet; callers fall back to text-only.
Future<XFile?> captureInviteCardImage(GlobalKey key) async {
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    return null;
  }
  final image = await boundary.toImage(pixelRatio: 3);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      return null;
    }
    return XFile.fromData(
      data.buffer.asUint8List(),
      mimeType: 'image/png',
      name: 'pettomo-invite.png',
    );
  } finally {
    image.dispose();
  }
}
