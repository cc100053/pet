import 'package:flutter/material.dart';

/// Furniture-mode inventory shown in place of the photo gallery, inside the
/// gallery's own slot, so it can never reach the room below.
class HomeFurnitureInventoryOverlay extends StatefulWidget {
  const HomeFurnitureInventoryOverlay({super.key, required this.panel});

  final Widget panel;

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: Alignment.topCenter,
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
          // Round-clip the scroll viewport so the panel keeps its rounded
          // bottom even when scrolled partway (otherwise the scroll view's
          // hard-edge clip squares off the bottom).
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) {
                _updateScrollable(notification.metrics.maxScrollExtent > 0);
                return false;
              },
              // The always-visible thumb only shows when scrollable, so a short
              // slot gets a clear "there is more below" hint while normal
              // screens stay clean.
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: _scrollable,
                thickness: 6,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  clipBehavior: Clip.none,
                  // Keeps item sizes intact; only scrolls when the gallery
                  // slot is shorter than the panel.
                  child: widget.panel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
