part of '../memory_calendar_view.dart';

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _CalendarColors.textStrong,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
      ],
    );
  }
}
