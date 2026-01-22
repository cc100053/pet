import 'package:flutter/material.dart';

import '../../../shared/ui/juice_wrappers.dart';

class HomeActionButtons extends StatelessWidget {
  const HomeActionButtons({
    super.key,
    required this.petBusy,
    required this.onCleanPressed,
    required this.onCameraPressed,
    required this.onChatPressed,
  });

  final bool petBusy;
  final VoidCallback onCleanPressed;
  final VoidCallback onCameraPressed;
  final VoidCallback onChatPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          icon: Icons.cleaning_services_rounded,
          onTap: onCleanPressed,
          enabled: !petBusy,
        ),
        _ActionButton(
          icon: Icons.camera_alt_rounded,
          onTap: onCameraPressed,
          enabled: !petBusy,
        ),
        _ActionButton(
          icon: Icons.chat_bubble_rounded,
          onTap: onChatPressed,
          enabled: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: JuicyScaleButton(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF0D5C63)),
        ),
      ),
    );
  }
}
