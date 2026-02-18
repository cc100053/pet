import 'package:flutter/material.dart';

class HomeLoadingView extends StatefulWidget {
  const HomeLoadingView({super.key, this.message, this.showProgress = false});

  final String? message;
  final bool showProgress;

  @override
  State<HomeLoadingView> createState() => _HomeLoadingViewState();
}

class _HomeLoadingViewState extends State<HomeLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotOpacity(int index) {
    final value = (_controller.value + (index * 0.2)) % 1.0;
    final distance = (value - 0.5).abs();
    return (1.0 - (distance * 1.9)).clamp(0.25, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: const Color(0xFFFDF4E7),
        child: Stack(
          children: [
            Positioned(
              top: -110,
              left: -70,
              child: _GlowBlob(
                size: 260,
                color: const Color(0xFFFFC98A).withValues(alpha: 0.4),
              ),
            ),
            Positioned(
              bottom: -130,
              right: -90,
              child: _GlowBlob(
                size: 320,
                color: const Color(0xFFEFB8FF).withValues(alpha: 0.2),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final t = _controller.value;
                        final scale = 1.0 + (0.04 * (0.5 - (t - 0.5).abs()));
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: 184,
                        height: 184,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.92),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFAF54,
                              ).withValues(alpha: 0.26),
                              blurRadius: 34,
                              spreadRadius: 4,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Image(
                          image: AssetImage('assets/app/LaunchLogo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (widget.showProgress) ...[
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.message ?? '',
                              style: const TextStyle(
                                color: Color(0xFF57412E),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(3, (index) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      margin: EdgeInsets.only(
                                        right: index == 2 ? 0 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEE9D3D,
                                        ).withValues(alpha: _dotOpacity(index)),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.15), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
