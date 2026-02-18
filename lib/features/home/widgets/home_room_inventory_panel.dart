import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../room_backgrounds.dart';
import '../../store/models/store_item.dart';

class HomeRoomInventoryPanel extends StatefulWidget {
  const HomeRoomInventoryPanel({
    super.key,
    required this.furnitureCatalog,
    required this.furnitureInventory,
    required this.selectedFurnitureItemId,
    required this.availableFurnitureCount,
    required this.furnitureLoading,
    required this.furnitureErrorText,
    required this.backgroundItems,
    required this.activeBackgroundId,
    required this.backgroundLoading,
    required this.backgroundErrorText,
    required this.applyingBackgroundId,
    required this.onClose,
    required this.onFurnitureTap,
    required this.onBackgroundApply,
  });

  final Map<String, StoreItem> furnitureCatalog;
  final Map<String, int> furnitureInventory;
  final String? selectedFurnitureItemId;
  final int Function(String itemId) availableFurnitureCount;
  final bool furnitureLoading;
  final String? furnitureErrorText;
  final List<StoreItem> backgroundItems;
  final String? activeBackgroundId;
  final bool backgroundLoading;
  final String? backgroundErrorText;
  final String? applyingBackgroundId;
  final VoidCallback onClose;
  final void Function(String itemId) onFurnitureTap;
  final void Function(String itemId) onBackgroundApply;

  @override
  State<HomeRoomInventoryPanel> createState() => _HomeRoomInventoryPanelState();
}

class _HomeRoomInventoryPanelState extends State<HomeRoomInventoryPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final furnitureItems = widget.furnitureCatalog.values
        .where((item) => (widget.furnitureInventory[item.id] ?? 0) > 0)
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
                  l10n.roomInventoryTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClose,
                  tooltip: l10n.commonClose,
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.black87,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black45,
              tabs: [
                Tab(text: l10n.inventoryTabFurniture),
                Tab(text: l10n.backgroundGalleryTab),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 122,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FurnitureTab(
                    items: furnitureItems,
                    selectedItemId: widget.selectedFurnitureItemId,
                    availableCount: widget.availableFurnitureCount,
                    loading: widget.furnitureLoading,
                    errorText: widget.furnitureErrorText,
                    onItemTap: widget.onFurnitureTap,
                  ),
                  _BackgroundTab(
                    items: widget.backgroundItems,
                    activeBackgroundId: widget.activeBackgroundId,
                    applyingBackgroundId: widget.applyingBackgroundId,
                    loading: widget.backgroundLoading,
                    errorText: widget.backgroundErrorText,
                    onApply: widget.onBackgroundApply,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final isFurnitureTab = _tabController.index == 0;
                final hint = isFurnitureTab
                    ? l10n.furnitureInventoryHint
                    : l10n.backgroundInventoryHint;
                return Text(
                  hint,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FurnitureTab extends StatelessWidget {
  const _FurnitureTab({
    required this.items,
    required this.selectedItemId,
    required this.availableCount,
    required this.loading,
    required this.errorText,
    required this.onItemTap,
  });

  final List<StoreItem> items;
  final String? selectedItemId;
  final int Function(String itemId) availableCount;
  final bool loading;
  final String? errorText;
  final void Function(String itemId) onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (errorText != null) {
      return Center(
        child: Text(
          errorText!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(l10n.furnitureInventoryEmpty, textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final available = availableCount(item.id);
        final isSelected = selectedItemId == item.id;
        return _FurnitureInventoryItem(
          item: item,
          available: available,
          isSelected: isSelected,
          onTap: () => onItemTap(item.id),
        );
      },
    );
  }
}

class _BackgroundTab extends StatelessWidget {
  const _BackgroundTab({
    required this.items,
    required this.activeBackgroundId,
    required this.applyingBackgroundId,
    required this.loading,
    required this.errorText,
    required this.onApply,
  });

  final List<StoreItem> items;
  final String? activeBackgroundId;
  final String? applyingBackgroundId;
  final bool loading;
  final String? errorText;
  final void Function(String itemId) onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (errorText != null) {
      return Center(
        child: Text(
          errorText!,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(l10n.backgroundInventoryEmpty, textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        final isActive = item.id == activeBackgroundId;
        final isApplying = item.id == applyingBackgroundId;
        final definition = RoomBackgrounds.resolve(item.backgroundKey);
        return _BackgroundInventoryItem(
          item: item,
          definition: definition,
          isActive: isActive,
          isApplying: isApplying,
          onTap: isActive ? null : () => onApply(item.id),
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
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
              item.localizedName(l10n),
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

class _BackgroundInventoryItem extends StatelessWidget {
  const _BackgroundInventoryItem({
    required this.item,
    required this.definition,
    required this.isActive,
    required this.isApplying,
    required this.onTap,
  });

  final StoreItem item;
  final RoomBackgroundDefinition definition;
  final bool isActive;
  final bool isApplying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: isApplying ? null : onTap,
      child: AnimatedContainer(
        duration: 150.ms,
        width: 128,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFF5ABCA5) : Colors.black12,
            width: isActive ? 1.6 : 1,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(decoration: definition.previewDecoration),
                    if (isActive)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF5ABCA5),
                          size: 18,
                        ),
                      ),
                    if (isApplying)
                      Container(
                        color: Colors.white.withValues(alpha: 0.55),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.localizedName(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF5ABCA5)
                    : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isActive ? l10n.backgroundAppliedLabel : l10n.backgroundApply,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
