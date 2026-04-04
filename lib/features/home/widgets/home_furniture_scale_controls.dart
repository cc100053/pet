import 'package:flutter/material.dart';

class HomeFurnitureScaleControls extends StatelessWidget {
  const HomeFurnitureScaleControls({
    super.key,
    required this.label,
    required this.scale,
    required this.minScale,
    required this.maxScale,
    required this.step,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  final String label;
  final double scale;
  final double minScale;
  final double maxScale;
  final double step;
  final String decreaseLabel;
  final String increaseLabel;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divisions = ((maxScale - minScale) / step).round();
    final scalePercent = (scale * 100).round();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          key: const Key('home_furniture_scale_controls'),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black87, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _ScaleActionButton(
                key: const Key('home_furniture_scale_decrease'),
                icon: Icons.remove_rounded,
                tooltip: decreaseLabel,
                onPressed: onDecrease,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '$scalePercent%',
                          key: const Key('home_furniture_scale_value'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 18,
                        ),
                      ),
                      child: Slider(
                        key: const Key('home_furniture_scale_slider'),
                        value: scale.clamp(minScale, maxScale),
                        min: minScale,
                        max: maxScale,
                        divisions: divisions,
                        onChanged: onChanged,
                        onChangeStart: onChangeStart,
                        onChangeEnd: onChangeEnd,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ScaleActionButton(
                key: const Key('home_furniture_scale_increase'),
                icon: Icons.add_rounded,
                tooltip: increaseLabel,
                onPressed: onIncrease,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaleActionButton extends StatelessWidget {
  const _ScaleActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.black87,
            disabledBackgroundColor: Colors.black26,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}
