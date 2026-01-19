import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LaunchView extends StatelessWidget {
  const LaunchView({super.key});

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFFFB36B);
    const brandDark = Color(0xFFF59A5A);

    return Scaffold(
      body: Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE0B2), Color(0xFFFFB36B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: brand.withValues(alpha: 0.35),
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
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
            const SizedBox(height: 28),
            Text(
              'PicPet',
              style: GoogleFonts.fredoka(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: brandDark,
                letterSpacing: 0.6,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
            const SizedBox(height: 8),
            Text(
              'Share moments. Grow together.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7A6F66),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
