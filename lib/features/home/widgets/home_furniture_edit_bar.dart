import 'package:flutter/material.dart';

import '../home_furniture_math.dart';

/// One entry of the edit bar's layer row; [onSelected] is null when that move
/// would change nothing (no overlapping piece in that direction).
class FurnitureLayerAction {
  const FurnitureLayerAction({
    required this.move,
    required this.label,
    required this.onSelected,
  });

  final FurnitureLayerMove move;
  final String label;
  final VoidCallback? onSelected;
}

/// Furniture-mode controls that sit in the bottom nav bar's slot. With nothing
/// selected it shows [hint] and Done; with a piece selected it shows that
/// piece's actions. The layer button swaps the row for the layer moves in
/// place, so nothing covers the room and moves can be repeated. Kept to one
/// 44pt row so it fits the nav bar's height.
class HomeFurnitureEditBar extends StatefulWidget {
  const HomeFurnitureEditBar({
    super.key,
    required this.hint,
    required this.doneLabel,
    required this.onDone,
    this.selection,
  });

  final String hint;
  final String doneLabel;
  final VoidCallback onDone;

  /// Actions for the selected piece; null when nothing is selected.
  final HomeFurnitureSelectionActions? selection;

  @override
  State<HomeFurnitureEditBar> createState() => _HomeFurnitureEditBarState();
}

class _HomeFurnitureEditBarState extends State<HomeFurnitureEditBar> {
  bool _layerMode = false;

  @override
  void didUpdateWidget(HomeFurnitureEditBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selection == null) _layerMode = false;
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    final hint = widget.hint;
    final doneLabel = widget.doneLabel;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          key: const Key('home_furniture_edit_bar'),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black87, width: 1.6),
          ),
          child: Row(
            children: [
              if (selection == null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
              else if (_layerMode) ...[
                _EditBarButton(
                  key: const Key('home_furniture_layer_close'),
                  icon: Icons.arrow_back_rounded,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => setState(() => _layerMode = false),
                ),
                for (final action in selection.layerActions)
                  _EditBarButton(
                    key: Key('home_furniture_layer_${action.move.name}'),
                    icon: _layerIcon(action.move),
                    tooltip: action.label,
                    onPressed: action.onSelected,
                  ),
              ] else ...[
                _EditBarButton(
                  key: const Key('home_furniture_scale_decrease'),
                  icon: Icons.remove_rounded,
                  tooltip: selection.decreaseLabel,
                  onPressed: selection.onDecrease,
                ),
                _EditBarButton(
                  key: const Key('home_furniture_scale_increase'),
                  icon: Icons.add_rounded,
                  tooltip: selection.increaseLabel,
                  onPressed: selection.onIncrease,
                ),
                _EditBarButton(
                  key: const Key('home_furniture_flip'),
                  icon: Icons.flip_rounded,
                  tooltip: selection.flipLabel,
                  onPressed: selection.onFlip,
                ),
                _EditBarButton(
                  key: const Key('home_furniture_layer'),
                  icon: Icons.layers_outlined,
                  tooltip: selection.layerLabel,
                  onPressed:
                      selection.layerActions.any((a) => a.onSelected != null)
                      ? () => setState(() => _layerMode = true)
                      : null,
                ),
                _EditBarButton(
                  key: const Key('home_furniture_store'),
                  icon: Icons.inventory_2_outlined,
                  tooltip: selection.storeLabel,
                  onPressed: selection.onStore,
                ),
              ],
              const SizedBox(width: 8),
              // With a selection the row is full, so Done collapses to its
              // icon (labelled by tooltip) to keep every button 44pt wide.
              Tooltip(
                message: doneLabel,
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    key: const Key('home_furniture_done'),
                    onPressed: widget.onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF0A53A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.symmetric(
                        horizontal: selection == null ? 14 : 0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: selection == null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, size: 20),
                              const SizedBox(width: 4),
                              Text(doneLabel),
                            ],
                          )
                        : const Icon(Icons.check_rounded, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeFurnitureSelectionActions {
  const HomeFurnitureSelectionActions({
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.flipLabel,
    required this.layerLabel,
    required this.storeLabel,
    required this.onDecrease,
    required this.onIncrease,
    required this.onFlip,
    required this.onStore,
    required this.layerActions,
  });

  final String decreaseLabel;
  final String increaseLabel;
  final String flipLabel;
  final String layerLabel;
  final String storeLabel;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onFlip;
  final VoidCallback? onStore;
  final List<FurnitureLayerAction> layerActions;
}

ButtonStyle _iconButtonStyle() => FilledButton.styleFrom(
  padding: EdgeInsets.zero,
  backgroundColor: Colors.black87,
  disabledBackgroundColor: Colors.black26,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

class _EditBarButton extends StatelessWidget {
  const _EditBarButton({
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
    return Expanded(
      child: Center(
        heightFactor: 1,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: onPressed,
              style: _iconButtonStyle(),
              child: Icon(icon, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _layerIcon(FurnitureLayerMove move) => switch (move) {
  FurnitureLayerMove.front => Icons.vertical_align_top_rounded,
  FurnitureLayerMove.forward => Icons.arrow_upward_rounded,
  FurnitureLayerMove.backward => Icons.arrow_downward_rounded,
  FurnitureLayerMove.back => Icons.vertical_align_bottom_rounded,
};
