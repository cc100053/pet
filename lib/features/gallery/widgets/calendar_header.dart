part of '../memory_calendar_view.dart';

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.label,
    required this.subtitle,
    required this.onMenuTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onMenuTap),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _CalendarColors.textMuted,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _CalendarColors.textStrong,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _CalendarColors.primarySoft,
            border: Border.all(color: _CalendarColors.outlineSoft),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: _CalendarColors.primary,
          ),
        ),
      ],
    );
  }
}
