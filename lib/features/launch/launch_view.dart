import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';
import '../../shared/theme/app_theme.dart';

class LaunchView extends StatelessWidget {
  const LaunchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.backgroundColor,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 72,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'PicPet',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.launchTagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
