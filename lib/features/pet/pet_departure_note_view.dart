import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/status_bar_style.dart';

class PetDepartureNoteView extends StatelessWidget {
  const PetDepartureNoteView({
    super.key,
    required this.heroTag,
    required this.noteText,
    this.onReturnPressed,
  });

  final String heroTag;
  final String noteText;
  final VoidCallback? onReturnPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.dark,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.4),
        body: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * 0.7;
                final height = constraints.maxHeight * 0.55;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: width,
                        height: height,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE8D8B5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: IconButton(
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: l10n.commonClose,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      noteText,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: const Color(0xFF4A3B2A),
                                            fontWeight: FontWeight.w600,
                                            height: 1.3,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                height: 20,
                                color: Color(0xFFE8D8B5),
                              ),
                              Text(
                                l10n.petDepartureGuideTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: const Color(0xFF4A3B2A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.petDepartureGuideMessage,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF4A3B2A),
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: onReturnPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A3B2A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(l10n.petDepartureGuideGoStore),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
