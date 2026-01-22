import 'package:flutter/material.dart';
import 'package:pet/l10n/app_localizations.dart';

class HomeInteractionTopBar extends StatelessWidget {
  const HomeInteractionTopBar({super.key, required this.onCalendarPressed});

  final VoidCallback onCalendarPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.black87,
            ),
            onPressed: onCalendarPressed,
            tooltip: l10n.calendarTitle,
          ),
        ],
      ),
    );
  }
}
