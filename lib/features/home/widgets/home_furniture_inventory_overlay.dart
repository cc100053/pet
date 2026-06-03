import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeFurnitureInventoryOverlay extends StatefulWidget {
  const HomeFurnitureInventoryOverlay({
    super.key,
    required this.visible,
    required this.panel,
  });

  final bool visible;
  final Widget panel;

  /// Fraction of the screen height the panel may occupy from the top. The rest
  /// is left for the room floor + bottom nav so furniture stays reachable while
  /// the inventory is open. The panel and its items keep their natural size; it
  /// simply scrolls internally if it can't fully fit above the reserved area.
  static const double _maxScreenFraction = 0.6;

  @override
  State<HomeFurnitureInventoryOverlay> createState() =>
      _HomeFurnitureInventoryOverlayState();
}

class _HomeFurnitureInventoryOverlayState
    extends State<HomeFurnitureInventoryOverlay> {
  final ScrollController _scrollController = ScrollController();

  /// True once layout reports the panel is taller than its cap, i.e. there is
  /// hidden content below. Drives the always-visible scrollbar hint, so it only
  /// appears on short windows where the panel actually scrolls.
  bool _scrollable = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollable(bool value) {
    if (value == _scrollable) {
      return;
    }
    // Metrics arrive during layout; defer the rebuild to the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && value != _scrollable) {
        setState(() => _scrollable = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.sizeOf(context).height;
            final softCap =
                screenHeight * HomeFurnitureInventoryOverlay._maxScreenFraction;
            // Never let the panel reach the room: cap it to a fraction of the
            // screen, bounded by whatever vertical space is actually available.
            final maxPanelHeight = constraints.maxHeight.isFinite
                ? math.min(constraints.maxHeight, softCap)
                : softCap;
            return IgnorePointer(
              ignoring: !widget.visible,
              child: AnimatedSlide(
                offset: widget.visible ? Offset.zero : const Offset(0, -1.1),
                duration: 220.ms,
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: widget.visible ? 1 : 0,
                  duration: 160.ms,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxPanelHeight),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      // Round-clip the scroll viewport so the panel keeps its
                      // rounded bottom even when scrolled partway (otherwise the
                      // scroll view's hard-edge clip squares off the bottom).
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: NotificationListener<ScrollMetricsNotification>(
                          onNotification: (notification) {
                            _updateScrollable(
                              notification.metrics.maxScrollExtent > 0,
                            );
                            return false;
                          },
                          // The always-visible thumb only shows when scrollable,
                          // so a short window gets a clear "there is more below"
                          // hint while normal screens stay clean.
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: _scrollable,
                            thickness: 6,
                            radius: const Radius.circular(8),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              clipBehavior: Clip.none,
                              // Keeps item sizes intact; only scrolls when space
                              // is tight (e.g. a short simulator window).
                              child: widget.panel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
