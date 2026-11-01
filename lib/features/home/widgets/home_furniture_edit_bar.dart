import 'package:flutter/material.dart';

import '../home_furniture_math.dart';

/// One entry of the edit bar's layer menu; [onSelected] is null when that move
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
/// piece's actions. Kept to one 44pt row so it fits the nav bar's height.
class HomeFurnitureEditBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final selection = this.selection;
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
              else ...[
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
                _LayerMenuButton(
                  tooltip: selection.layerLabel,
                  actions: selection.layerActions,
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
                    onPressed: onDone,
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

class _LayerMenuButton extends StatelessWidget {
  const _LayerMenuButton({required this.tooltip, required this.actions});

  final String tooltip;
  final List<FurnitureLayerAction> actions;

  @override
  Widget build(BuildContext context) {
    final enabled = actions.any((action) => action.onSelected != null);
    return Expanded(
      child: Center(
        heightFactor: 1,
        child: SizedBox(
          width: 44,
          height: 44,
          child: PopupMenuButton<FurnitureLayerMove>(
            key: const Key('home_furniture_layer'),
            tooltip: tooltip,
            enabled: enabled,
            position: PopupMenuPosition.over,
            offset: const Offset(0, -8),
            onSelected: (move) => actions
                .firstWhere((action) => action.move == move)
                .onSelected
                ?.call(),
            itemBuilder: (context) => [
              for (final action in actions)
                PopupMenuItem(
                  key: Key('home_furniture_layer_${action.move.name}'),
                  value: action.move,
                  enabled: action.onSelected != null,
                  child: Text(action.label),
                ),
            ],
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: enabled ? Colors.black87 : Colors.black26,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.layers_outlined,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
