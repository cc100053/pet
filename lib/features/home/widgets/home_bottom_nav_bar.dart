import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/theme/app_theme.dart';
import 'home_responsive.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.onHome,
    required this.onCalendar,
    required this.onCamera,
    required this.onStore,
    required this.onChat,
    this.cameraEnabled = true,
    this.chatHasUnread = false,
  });

  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onCamera;
  final VoidCallback onStore;
  final VoidCallback onChat;
  final bool cameraEnabled;
  final bool chatHasUnread;

  static const double _height = 68;
  static const double _cameraSize = 60;

  @override
  Widget build(BuildContext context) {
    final scale = homeUiScale(MediaQuery.sizeOf(context).width);
    final height = _height * scale;
    final cameraSize = _cameraSize * scale;
    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: 20 * scale),
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIconButton(
            iconAsset: 'assets/icon/streamline-sharp--pet-friendly-hotel.svg',
            onTap: onHome,
            scale: scale,
          ),
          _NavIconButton(
            iconAsset: 'assets/icon/mage--calendar-2.svg',
            onTap: onCalendar,
            scale: scale,
          ),
          _CameraButton(
            onTap: onCamera,
            enabled: cameraEnabled,
            scale: scale,
            size: cameraSize,
          ),
          _NavIconButton(
            iconAsset: 'assets/icon/icon-park-outline--shopping-bag.svg',
            onTap: onStore,
            scale: scale,
          ),
          _NavIconButton(
            iconAsset: 'assets/icon/fluent--chat-12-regular.svg',
            onTap: onChat,
            scale: scale,
            showIndicator: chatHasUnread,
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.iconAsset,
    required this.onTap,
    required this.scale,
    this.showIndicator = false,
  });

  final String iconAsset;
  final VoidCallback onTap;
  final double scale;
  final bool showIndicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52 * scale,
      height: 52 * scale,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: Colors.black.withValues(alpha: 0.12),
          highlightColor: Colors.black.withValues(alpha: 0.08),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: 32 * scale,
                  height: 32 * scale,
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              if (showIndicator)
                Positioned(
                  top: 10 * scale,
                  right: 9 * scale,
                  child: Container(
                    key: const Key('home_chat_unread_indicator'),
                    width: 10 * scale,
                    height: 10 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.onTap,
    required this.enabled,
    required this.scale,
    required this.size,
  });

  final VoidCallback onTap;
  final bool enabled;
  final double scale;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        splashColor: Colors.black.withValues(alpha: 0.12),
        highlightColor: Colors.black.withValues(alpha: 0.08),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
            border: Border.all(color: Colors.black87, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(6 * scale),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: enabled ? 1 : 0.5),
            ),
            child: SvgPicture.asset(
              'assets/icon/solar--camera-linear.svg',
              width: 32 * scale,
              height: 32 * scale,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
