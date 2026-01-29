import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/theme/app_theme.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    super.key,
    required this.onHome,
    required this.onCalendar,
    required this.onCamera,
    required this.onStore,
    required this.onChat,
  });

  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onCamera;
  final VoidCallback onStore;
  final VoidCallback onChat;

  static const double _height = 68;
  static const double _cameraSize = 52;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
            iconAsset: 'assets/icon/streamline-sharp--pet-friendly-hotel-remix.svg',
            onTap: onHome,
          ),
          _NavIconButton(
            iconAsset: 'assets/icon/mage--calendar-2.svg',
            onTap: onCalendar,
          ),
          _CameraButton(onTap: onCamera),
          _NavIconButton(
            iconAsset: 'assets/icon/icon-park-outline--shopping-bag.svg',
            onTap: onStore,
          ),
          _NavIconButton(
            iconAsset: 'assets/icon/fluent--chat-12-regular.svg',
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({required this.iconAsset, required this.onTap});

  final String iconAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Center(
          child: SvgPicture.asset(
            iconAsset,
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: HomeBottomNavBar._cameraSize,
        height: HomeBottomNavBar._cameraSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
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
          margin: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
          ),
          child: SvgPicture.asset(
            'assets/icon/solar--camera-linear.svg',
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
