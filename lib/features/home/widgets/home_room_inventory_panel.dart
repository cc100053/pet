import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pet/l10n/app_localizations.dart';

import '../../../shared/ui/juice_wrappers.dart';
import '../../pet/pet_animated_image.dart';
import '../../pet/pet_catalog.dart';
import '../../pet/pet_sockets.dart';
import '../room_backgrounds.dart';
import '../../shop/models/shop_item.dart';
import '../../shop/widgets/shop_item_visual.dart';
import 'pet_equipment_overlay.dart';

/// A pet that can be picked as the equipment dress-up target.
class RoomPetOption {
  const RoomPetOption({
    required this.petId,
    required this.petType,
    required this.isMain,
    this.name,
    this.equippedSkusBySlot = const <String, String>{},
  });

  final String petId;
  final String petType;
  final bool isMain;
  final String? name;
  final Map<String, String> equippedSkusBySlot;
}

class HomeRoomInventoryPanel extends StatefulWidget {
  const HomeRoomInventoryPanel({
    super.key,
    required this.petType,
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
    required this.equipmentItems,
    required this.equippedItemIdsBySlot,
    required this.equippedItemSkusBySlot,
    required this.equipmentLoading,
    required this.equipmentErrorText,
    required this.equipPets,
    required this.selectedEquipPetId,
    required this.onSelectEquipPet,
    required this.onClose,
    required this.onFurnitureTap,
    required this.onBackgroundApply,
    required this.onEquipItem,
    required this.onUnequipItem,
  });

  final String petType;
  final Map<String, ShopItem> furnitureCatalog;
  final Map<String, int> furnitureInventory;
  final String? selectedFurnitureItemId;
  final int Function(String itemId) availableFurnitureCount;
  final bool furnitureLoading;
  final String? furnitureErrorText;
  final List<ShopItem> backgroundItems;
  final String? activeBackgroundId;
  final bool backgroundLoading;
  final String? backgroundErrorText;
  final String? applyingBackgroundId;
  final List<ShopItem> equipmentItems;
  final Map<String, String> equippedItemIdsBySlot;
  final Map<String, String> equippedItemSkusBySlot;
  final bool equipmentLoading;
  final String? equipmentErrorText;
  final List<RoomPetOption> equipPets;
  final String? selectedEquipPetId;
  final ValueChanged<String> onSelectEquipPet;
  final VoidCallback onClose;
  final void Function(String itemId) onFurnitureTap;
  final void Function(String itemId) onBackgroundApply;
  final Future<void> Function(String itemId, String slot) onEquipItem;
  final Future<void> Function(String slot) onUnequipItem;

  @override
  State<HomeRoomInventoryPanel> createState() => _HomeRoomInventoryPanelState();
}

class _HomeRoomInventoryPanelState extends State<HomeRoomInventoryPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedEquipmentSlot = PetEquipmentSlot.head;
  String? _previewEquipmentItemId;
  bool _equipmentSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didUpdateWidget(covariant HomeRoomInventoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previewEquipmentItemId == null) {
      return;
    }
    final exists = widget.equipmentItems.any(
      (item) => item.id == _previewEquipmentItemId,
    );
    if (!exists) {
      _previewEquipmentItemId = null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _selectedEquipPetType() {
    for (final pet in widget.equipPets) {
      if (pet.petId == widget.selectedEquipPetId) {
        return pet.petType;
      }
    }
    return widget.petType;
  }

  List<ShopItem> _equipmentItemsForSelectedSlot() {
    return widget.equipmentItems
        .where((item) => item.equipmentSlot == _selectedEquipmentSlot)
        .toList(growable: false);
  }

  String? _equippedItemIdForSelectedSlot() {
    return widget.equippedItemIdsBySlot[_selectedEquipmentSlot];
  }

  Map<String, String> _previewSkusBySlot() {
    final preview = Map<String, String>.from(widget.equippedItemSkusBySlot);
    if (_previewEquipmentItemId == null) {
      return preview;
    }
    for (final item in widget.equipmentItems) {
      if (item.id == _previewEquipmentItemId) {
        preview[_selectedEquipmentSlot] = item.sku;
        break;
      }
    }
    return preview;
  }

  Future<void> _handleEquipPressed() async {
    final itemId = _previewEquipmentItemId;
    if (itemId == null || _equipmentSubmitting) {
      return;
    }
    setState(() => _equipmentSubmitting = true);
    try {
      await widget.onEquipItem(itemId, _selectedEquipmentSlot);
      if (!mounted) {
        return;
      }
      setState(() {
        _previewEquipmentItemId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _equipmentSubmitting = false);
      } else {
        _equipmentSubmitting = false;
      }
    }
  }

  Future<void> _handleUnequipPressed() async {
    if (_equipmentSubmitting) {
      return;
    }
    setState(() => _equipmentSubmitting = true);
    try {
      await widget.onUnequipItem(_selectedEquipmentSlot);
      if (!mounted) {
        return;
      }
      setState(() {
        _previewEquipmentItemId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _equipmentSubmitting = false);
      } else {
        _equipmentSubmitting = false;
      }
    }
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
                Tab(text: l10n.inventoryTabEquipment),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              // The equipment tab grows when the persistent pet selector shows;
              // the furniture/background grids simply reveal more rows.
              height: widget.equipPets.length >= 2 ? 348 : 246,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FurnitureTab(
                    items: furnitureItems,
                    totalCount: (itemId) =>
                        widget.furnitureInventory[itemId] ?? 0,
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
                  _EquipmentTab(
                    petType: _selectedEquipPetType(),
                    equipPets: widget.equipPets,
                    selectedEquipPetId: widget.selectedEquipPetId,
                    onSelectEquipPet: (petId) {
                      if (petId == widget.selectedEquipPetId) {
                        return;
                      }
                      setState(() => _previewEquipmentItemId = null);
                      widget.onSelectEquipPet(petId);
                    },
                    previewSkusBySlot: _previewSkusBySlot(),
                    selectedSlot: _selectedEquipmentSlot,
                    onSelectSlot: (slot) {
                      setState(() {
                        _selectedEquipmentSlot = slot;
                        _previewEquipmentItemId = null;
                      });
                    },
                    items: _equipmentItemsForSelectedSlot(),
                    equippedItemId: _equippedItemIdForSelectedSlot(),
                    previewItemId: _previewEquipmentItemId,
                    loading: widget.equipmentLoading,
                    errorText: widget.equipmentErrorText,
                    submitting: _equipmentSubmitting,
                    onItemTap: (itemId) {
                      setState(() {
                        _previewEquipmentItemId = itemId;
                      });
                    },
                    onEquip: () => unawaited(_handleEquipPressed()),
                    onUnequip: () => unawaited(_handleUnequipPressed()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final hint = switch (_tabController.index) {
                  0 => l10n.furnitureInventoryHint,
                  1 => l10n.backgroundInventoryHint,
                  _ => l10n.equipmentInventoryHint,
                };
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
    required this.totalCount,
    required this.selectedItemId,
    required this.availableCount,
    required this.loading,
    required this.errorText,
    required this.onItemTap,
  });

  final List<ShopItem> items;
  final int Function(String itemId) totalCount;
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

    final selectedItem = items.cast<ShopItem?>().firstWhere(
      (item) => item?.id == selectedItemId,
      orElse: () => items.first,
    )!;

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 88,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final total = totalCount(item.id);
              final available = availableCount(item.id);
              final isSelected = selectedItemId == item.id;
              return _FurnitureInventoryItem(
                item: item,
                total: total,
                available: available,
                isSelected: isSelected,
                onTap: () => onItemTap(item.id),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _FurnitureSelectionSummary(
          item: selectedItem,
          total: totalCount(selectedItem.id),
          available: availableCount(selectedItem.id),
          selected: selectedItem.id == selectedItemId,
          onTap: () => onItemTap(selectedItem.id),
        ),
      ],
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

  final List<ShopItem> items;
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

class _EquipmentTab extends StatelessWidget {
  const _EquipmentTab({
    required this.petType,
    required this.equipPets,
    required this.selectedEquipPetId,
    required this.onSelectEquipPet,
    required this.previewSkusBySlot,
    required this.selectedSlot,
    required this.onSelectSlot,
    required this.items,
    required this.equippedItemId,
    required this.previewItemId,
    required this.loading,
    required this.errorText,
    required this.submitting,
    required this.onItemTap,
    required this.onEquip,
    required this.onUnequip,
  });

  final String petType;
  final List<RoomPetOption> equipPets;
  final String? selectedEquipPetId;
  final ValueChanged<String> onSelectEquipPet;
  final Map<String, String> previewSkusBySlot;
  final String selectedSlot;
  final ValueChanged<String> onSelectSlot;
  final List<ShopItem> items;
  final String? equippedItemId;
  final String? previewItemId;
  final bool loading;
  final String? errorText;
  final bool submitting;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasEquipped = previewSkusBySlot.containsKey(selectedSlot);
    final canEquip =
        previewItemId != null &&
        previewItemId != equippedItemId &&
        !submitting &&
        !loading;
    final canUnequip = hasEquipped && !submitting && !loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (equipPets.length >= 2) ...[
          _EquipPetSelector(
            pets: equipPets,
            selectedPetId: selectedEquipPetId,
            enabled: !submitting,
            onSelect: onSelectEquipPet,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _EquipmentPetPreview(
                petType: petType,
                equippedSkusBySlot: previewSkusBySlot,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in PetEquipmentSlot.values)
                        _EquipmentSlotChip(
                          label: _slotLabel(slot, l10n),
                          selected: slot == selectedSlot,
                          onTap: () => onSelectSlot(slot),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: _EquipmentItemStrip(
                      items: items,
                      equippedItemId: equippedItemId,
                      previewItemId: previewItemId,
                      loading: loading,
                      errorText: errorText,
                      onItemTap: onItemTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _EquipmentActionButton(
                label: l10n.equipmentUnequipCta,
                enabled: canUnequip,
                accent: const Color(0xFFFFE2E2),
                borderColor: const Color(0xFFE57373),
                onTap: onUnequip,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EquipmentActionButton(
                label: l10n.equipmentEquipCta,
                enabled: canEquip,
                accent: const Color(0xFFFFF1C9),
                borderColor: const Color(0xFFFFB74D),
                onTap: onEquip,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _slotLabel(String slot, AppLocalizations l10n) {
    switch (slot) {
      case PetEquipmentSlot.head:
        return l10n.equipmentSlotHead;
      case PetEquipmentSlot.face:
        return l10n.equipmentSlotFace;
      case PetEquipmentSlot.body:
        return l10n.equipmentSlotBody;
      case PetEquipmentSlot.back:
        return l10n.equipmentSlotBack;
    }
    return slot;
  }
}

class _EquipPetSelector extends StatelessWidget {
  const _EquipPetSelector({
    required this.pets,
    required this.selectedPetId,
    required this.enabled,
    required this.onSelect,
  });

  final List<RoomPetOption> pets;
  final String? selectedPetId;
  final bool enabled;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.equipTargetPickerTitle,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _EquipPetChip(
                pet: pet,
                selected: pet.petId == selectedPetId,
                onTap: enabled ? () => onSelect(pet.petId) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EquipPetChip extends StatelessWidget {
  const _EquipPetChip({
    required this.pet,
    required this.selected,
    required this.onTap,
  });

  final RoomPetOption pet;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final definition = PetCatalog.byId(pet.petType);
    final label = (pet.name?.trim().isNotEmpty ?? false)
        ? pet.name!.trim()
        : definition.name(l10n);
    return JuicyScaleButton(
      onTap: onTap ?? () {},
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1C9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFB74D) : Colors.black26,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ChipPetAvatar(
                  petType: pet.petType,
                  stayAsset: definition.stayAsset,
                  equippedSkusBySlot: pet.equippedSkusBySlot,
                ),
                if (pet.isMain)
                  const Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipPetAvatar extends StatelessWidget {
  const _ChipPetAvatar({
    required this.petType,
    required this.stayAsset,
    required this.equippedSkusBySlot,
  });

  final String petType;
  final String stayAsset;
  final Map<String, String> equippedSkusBySlot;

  @override
  Widget build(BuildContext context) {
    const avatarSize = Size(38, 38);
    return SizedBox(
      width: avatarSize.width,
      height: avatarSize.height,
      child: PetAnimationFrameBuilder(
        sourceAsset: stayAsset,
        builder: (context, petAsset, animationProgress, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              PetEquipmentOverlay(
                petId: petType,
                equippedSkusBySlot: equippedSkusBySlot,
                petSize: avatarSize,
                layer: PetEquipmentOverlayLayer.behindPet,
                animationProgress: animationProgress,
              ),
              Image.asset(
                petAsset,
                width: avatarSize.width,
                height: avatarSize.height,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
              PetEquipmentOverlay(
                petId: petType,
                equippedSkusBySlot: equippedSkusBySlot,
                petSize: avatarSize,
                layer: PetEquipmentOverlayLayer.frontPet,
                animationProgress: animationProgress,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EquipmentPetPreview extends StatelessWidget {
  const _EquipmentPetPreview({
    required this.petType,
    required this.equippedSkusBySlot,
  });

  final String petType;
  final Map<String, String> equippedSkusBySlot;

  @override
  Widget build(BuildContext context) {
    final pet = PetCatalog.byId(petType);
    const previewSize = Size(84, 84);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF7EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black87, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: previewSize.width,
          height: previewSize.height,
          child: PetAnimationFrameBuilder(
            sourceAsset: pet.stayAsset,
            builder: (context, petAsset, animationProgress, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  PetEquipmentOverlay(
                    petId: petType,
                    equippedSkusBySlot: equippedSkusBySlot,
                    petSize: previewSize,
                    layer: PetEquipmentOverlayLayer.behindPet,
                    animationProgress: animationProgress,
                  ),
                  Image.asset(
                    petAsset,
                    width: previewSize.width,
                    height: previewSize.height,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                  PetEquipmentOverlay(
                    petId: petType,
                    equippedSkusBySlot: equippedSkusBySlot,
                    petSize: previewSize,
                    layer: PetEquipmentOverlayLayer.frontPet,
                    animationProgress: animationProgress,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EquipmentSlotChip extends StatelessWidget {
  const _EquipmentSlotChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JuicyScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0C9) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFB74D) : Colors.black12,
            width: selected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _EquipmentItemStrip extends StatelessWidget {
  const _EquipmentItemStrip({
    required this.items,
    required this.equippedItemId,
    required this.previewItemId,
    required this.loading,
    required this.errorText,
    required this.onItemTap,
  });

  final List<ShopItem> items;
  final String? equippedItemId;
  final String? previewItemId;
  final bool loading;
  final String? errorText;
  final ValueChanged<String> onItemTap;

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
        child: Text(
          l10n.equipmentNoneOwned,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _EquipmentInventoryItem(
          item: item,
          isEquipped: item.id == equippedItemId,
          isPreviewed: item.id == previewItemId,
          onTap: () => onItemTap(item.id),
        );
      },
    );
  }
}

class _EquipmentInventoryItem extends StatelessWidget {
  const _EquipmentInventoryItem({
    required this.item,
    required this.isEquipped,
    required this.isPreviewed,
    required this.onTap,
  });

  final ShopItem item;
  final bool isEquipped;
  final bool isPreviewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return JuicyScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 150.ms,
        width: 86,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isPreviewed
              ? const Color(0xFFFFF2D6)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isEquipped
                ? const Color(0xFF5ABCA5)
                : (isPreviewed ? const Color(0xFFFFB74D) : Colors.black12),
            width: isEquipped || isPreviewed ? 1.8 : 1,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                ShopCatalogItemVisual(
                  item: item,
                  size: 36,
                  fallbackEmoji: item.emoji ?? '👒',
                ),
                if (isEquipped)
                  const Positioned(
                    top: -4,
                    right: -8,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Color(0xFF5ABCA5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.localizedName(l10n),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentActionButton extends StatelessWidget {
  const _EquipmentActionButton({
    required this.label,
    required this.enabled,
    required this.accent,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Color accent;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JuicyScaleButton(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FurnitureInventoryItem extends StatelessWidget {
  const _FurnitureInventoryItem({
    required this.item,
    required this.total,
    required this.available,
    required this.isSelected,
    required this.onTap,
  });

  final ShopItem item;
  final int total;
  final int available;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final canSelect = available > 0;
    return JuicyScaleButton(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        key: Key('furniture_inventory_item_${item.id}'),
        duration: 150.ms,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFF2D6)
              : (canSelect
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB74D)
                : (canSelect ? Colors.black12 : Colors.black26),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Opacity(
                opacity: canSelect ? 1 : 0.45,
                child: ShopFurnitureVisual(item: item, size: 38),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 26, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: canSelect
                      ? const Color(0xFF5ABCA5)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  'x$total',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: canSelect ? Colors.white : Colors.black45,
                  ),
                ),
              ),
            ),
            if (isSelected)
              const Positioned(
                left: -2,
                bottom: -2,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFFFFB74D),
                ),
              ),
            if (!canSelect)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.block_rounded,
                      size: 18,
                      color: Colors.black38,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FurnitureSelectionSummary extends StatelessWidget {
  const _FurnitureSelectionSummary({
    required this.item,
    required this.total,
    required this.available,
    required this.selected,
    required this.onTap,
  });

  final ShopItem item;
  final int total;
  final int available;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPlace = available > 0;
    return JuicyScaleButton(
      onTap: canPlace ? onTap : null,
      child: AnimatedContainer(
        duration: 150.ms,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF7EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFFB74D) : Colors.black12,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ShopFurnitureVisual(item: item, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.localizedName(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${l10n.storeOwnedCount(total)}  ·  ${l10n.furnitureAvailableCount(available)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                      color: canPlace ? Colors.black54 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              canPlace ? Icons.add_circle_rounded : Icons.block_rounded,
              color: canPlace ? const Color(0xFF5ABCA5) : Colors.black38,
              size: 22,
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

  final ShopItem item;
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
