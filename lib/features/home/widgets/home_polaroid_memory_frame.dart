import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:pet/shared/ui/cached_network_image_view.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/user_avatar.dart';

class HomePolaroidMemoryFrame extends StatelessWidget {
  const HomePolaroidMemoryFrame({
    super.key,
    required this.imageUrl,
    required this.caption,
    required this.userLabel,
    required this.senderAvatar,
    required this.senderFallbackText,
    this.onTap,
  });

  final String imageUrl;
  final String caption;
  final String userLabel;
  final String? senderAvatar;
  final String? senderFallbackText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final showCaption = caption.trim().isNotEmpty;
    final showUserLabel = userLabel.trim().isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final innerPadding = 14.0;
        final avatarSize = 46.0;
        var photoSize = width - (innerPadding * 2);
        if (constraints.maxHeight.isFinite) {
          final reservedBelowPhoto = showCaption ? 80 : 60;
          final available =
              constraints.maxHeight - (innerPadding * 2) - reservedBelowPhoto;
          if (available.isFinite && available > 0) {
            photoSize = math.min(photoSize, available).toDouble();
          }
        }
        final double bottomHeight = constraints.maxHeight.isFinite
            ? math
                  .max(
                    0,
                    constraints.maxHeight - (innerPadding * 2) - photoSize,
                  )
                  .toDouble()
            : (showCaption ? 80.0 : 60.0);
        final double safeBottomHeight = math.max(0, bottomHeight - 8);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: EdgeInsets.all(innerPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black87, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: photoSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4EF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.isEmpty
                              ? const _Placeholder()
                              : CachedNetworkImageView(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      if (showCaption)
                        SizedBox(
                          height: safeBottomHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: math
                                    .min(36, safeBottomHeight)
                                    .toDouble(),
                              ),
                              if (safeBottomHeight > 8)
                                Flexible(
                                  child: Text(
                                    caption,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        )
                      else
                        SizedBox(height: safeBottomHeight),
                    ],
                  ),
                  Positioned(
                    top: photoSize - (avatarSize / 2) + 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black87,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: UserAvatar(
                                avatar: senderAvatar,
                                fallbackText: senderFallbackText,
                                size: avatarSize - 10,
                              ),
                            ),
                          ),
                          if (showUserLabel) ...[
                            const Gap(6),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: photoSize),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.black87,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  userLabel,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.photo,
        size: 34,
        color: Colors.black.withValues(alpha: 0.25),
      ),
    );
  }
}
