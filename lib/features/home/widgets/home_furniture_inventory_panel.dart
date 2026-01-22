import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../store/store_view.dart';

class HomeFurnitureInventoryPanel extends StatelessWidget {
  const HomeFurnitureInventoryPanel({
    super.key,
    required this.furnitureCatalog,
    required this.furnitureInventory,
    required this.selectedItemId,
    required this.availableCount,
    required this.loading,
    required this.errorText,
    required this.onClose,
    required this.onItemTap,
  });

  final Map<String, StoreItem> furnitureCatalog;
  final Map<String, int> furnitureInventory;
  final String? selectedItemId;
  final int Function(String itemId) availableCount;
  final bool loading;
  final String? errorText;
  final VoidCallback onClose;
  final void Function(String itemId) onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final furnitureItems = furnitureCatalog.values
        .where((item) => (furnitureInventory[item.id] ?? 0) > 0)
        .toList(growable: false);

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  l10n.furnitureInventoryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                  tooltip: l10n.commonClose,
                ),
              ],
            ),
            if (loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else if (furnitureItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.furnitureInventoryEmpty,
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: furnitureItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = furnitureItems[index];
                    final available = availableCount(item.id);
                    final isSelected = selectedItemId == item.id;
                    return _FurnitureInventoryItem(
                      item: item,
                      available: available,
                      isSelected: isSelected,
                      onTap: () => onItemTap(item.id),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(
              l10n.furnitureInventoryHint,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _FurnitureInventoryItem extends StatelessWidget {
  const _FurnitureInventoryItem({
    required this.item,
    required this.available,
    required this.isSelected,
    required this.onTap,
  });

  final StoreItem item;
  final int available;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canSelect = available > 0;
    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        duration: 150.ms,
        width: 76,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFF2D6)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFB74D) : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji ?? '🪑', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'x$available',
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                color: canSelect ? Colors.black87 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
