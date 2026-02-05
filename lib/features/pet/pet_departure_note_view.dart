import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet/l10n/app_localizations.dart';
import 'package:pet/shared/ui/status_bar_style.dart';

class PetDepartureNoteView extends StatelessWidget {
  const PetDepartureNoteView({
    super.key,
    required this.heroTag,
    required this.noteText,
  });

  final String heroTag;
  final String noteText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppStatusBarStyles.dark,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        body: SafeArea(
          child: Center(
            child: Hero(
              tag: heroTag,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.all(20),
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
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: l10n.commonClose,
                        ),
                      ),
                      Center(
                        child: Text(
                          noteText,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: const Color(0xFF4A3B2A),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
