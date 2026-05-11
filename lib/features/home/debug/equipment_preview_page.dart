import 'package:flutter/material.dart';

import '../../pet/equipment_catalog.dart';
import '../../pet/pet_animated_image.dart';
import '../../pet/pet_sockets.dart';
import '../widgets/pet_equipment_overlay.dart';

class EquipmentPreviewPage extends StatefulWidget {
  const EquipmentPreviewPage({super.key});

  @override
  State<EquipmentPreviewPage> createState() => _EquipmentPreviewPageState();
}

class _EquipmentPreviewPageState extends State<EquipmentPreviewPage> {
  String _petId = 'ghost';
  _AnimState _animState = _AnimState.idle;
  final Map<String, String?> _equippedBySlot = {
    PetEquipmentSlot.head: null,
    PetEquipmentSlot.body: null,
    PetEquipmentSlot.back: null,
  };

  // ── static data ──────────────────────────────────────────

  static const _pets = ['ghost', 'cat', 'fish', 'tiger'];

  static const _petAnimations = {
    'ghost': {
      _AnimState.idle: 'assets/pet/ghost/ghost_stay.gif',
      _AnimState.walk: 'assets/pet/ghost/ghost_walking.gif',
      _AnimState.sleep: 'assets/pet/ghost/ghost_sleep.gif',
    },
    'cat': {
      _AnimState.idle: 'assets/pet/cat/cat_stay.gif',
      _AnimState.walk: 'assets/pet/cat/cat_moving.gif',
      _AnimState.sleep: 'assets/pet/cat/cat_sleep.gif',
    },
    'fish': {
      _AnimState.idle: 'assets/pet/fish/fish_stay.gif',
      _AnimState.walk: 'assets/pet/fish/fish_moving.gif',
      _AnimState.sleep: 'assets/pet/fish/fish_sleep.gif',
    },
    'tiger': {
      _AnimState.idle: 'assets/pet/tiger/tiger_stay.gif',
      _AnimState.walk: 'assets/pet/tiger/tiger_moving.gif',
      _AnimState.sleep: 'assets/pet/tiger/tiger_sleep.gif',
    },
  };

  // Equipment available per slot, derived from EquipmentCatalog
  static Map<String, List<EquipmentDefinition>> get _equipmentBySlot {
    final map = <String, List<EquipmentDefinition>>{};
    for (final slot in PetEquipmentSlot.values) {
      map[slot] = EquipmentCatalog.forSlot(slot);
    }
    return map;
  }

  // ── derived state ─────────────────────────────────────────

  bool get _isWalking => _animState == _AnimState.walk;
  bool get _isSleeping => _animState == _AnimState.sleep;

  String get _sourceAsset => _petAnimations[_petId]![_animState]!;

  Map<String, String> get _equippedSkusBySlot {
    final result = <String, String>{};
    for (final entry in _equippedBySlot.entries) {
      if (entry.value != null) result[entry.key] = entry.value!;
    }
    return result;
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear all equipment',
            onPressed: () => setState(() {
              for (final slot in _equippedBySlot.keys) {
                _equippedBySlot[slot] = null;
              }
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
          const Divider(height: 1),
          _buildControls(),
        ],
      ),
    );
  }

  // ── preview ───────────────────────────────────────────────

  Widget _buildPreview() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = (constraints.maxWidth * 0.7).clamp(180.0, 360.0);
            final petSize = Size.square(side);
            return SizedBox.fromSize(
              size: petSize,
              child: PetAnimationFrameBuilder(
                sourceAsset: _sourceAsset,
                builder: (context, asset, progress, _) {
                  return Stack(
                    children: [
                      PetEquipmentOverlay(
                        petId: _petId,
                        equippedSkusBySlot: _equippedSkusBySlot,
                        petSize: petSize,
                        layer: PetEquipmentOverlayLayer.behindPet,
                        animationProgress: progress,
                        isWalking: _isWalking,
                        isSleeping: _isSleeping,
                      ),
                      Image.asset(
                        asset,
                        width: side,
                        height: side,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                      PetEquipmentOverlay(
                        petId: _petId,
                        equippedSkusBySlot: _equippedSkusBySlot,
                        petSize: petSize,
                        layer: PetEquipmentOverlayLayer.frontPet,
                        animationProgress: progress,
                        isWalking: _isWalking,
                        isSleeping: _isSleeping,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // ── controls panel ────────────────────────────────────────

  Widget _buildControls() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Pet'),
          const SizedBox(height: 6),
          _buildPetSelector(),
          const SizedBox(height: 12),
          _buildSectionLabel('Animation'),
          const SizedBox(height: 6),
          _buildAnimStateSelector(),
          const SizedBox(height: 12),
          _buildSectionLabel('Equipment'),
          const SizedBox(height: 6),
          ..._buildEquipmentRows(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildPetSelector() {
    return Wrap(
      spacing: 8,
      children: _pets.map((pet) {
        final selected = _petId == pet;
        return ChoiceChip(
          label: Text(_petLabel(pet)),
          selected: selected,
          onSelected: (_) => setState(() {
            _petId = pet;
            // Clear slots whose hidden state may differ per pet
          }),
        );
      }).toList(),
    );
  }

  Widget _buildAnimStateSelector() {
    return SegmentedButton<_AnimState>(
      segments: const [
        ButtonSegment(value: _AnimState.idle, label: Text('Idle')),
        ButtonSegment(value: _AnimState.walk, label: Text('Walk')),
        ButtonSegment(value: _AnimState.sleep, label: Text('Sleep')),
      ],
      selected: {_animState},
      onSelectionChanged: (s) => setState(() => _animState = s.first),
    );
  }

  List<Widget> _buildEquipmentRows() {
    final equipmentBySlot = _equipmentBySlot;
    final rows = <Widget>[];

    for (final slot in PetEquipmentSlot.values) {
      final items = equipmentBySlot[slot] ?? [];
      rows.add(_buildSlotRow(slot, items));
      rows.add(const SizedBox(height: 8));
    }
    return rows;
  }

  Widget _buildSlotRow(String slot, List<EquipmentDefinition> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            _slotLabel(slot),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('None'),
                selected: _equippedBySlot[slot] == null,
                onSelected: (_) => setState(() => _equippedBySlot[slot] = null),
                visualDensity: VisualDensity.compact,
              ),
              ...items.map(
                (def) => ChoiceChip(
                  label: Text(_skuLabel(def.sku)),
                  selected: _equippedBySlot[slot] == def.sku,
                  onSelected: (_) =>
                      setState(() => _equippedBySlot[slot] = def.sku),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── labels ────────────────────────────────────────────────

  String _petLabel(String petId) => switch (petId) {
    'ghost' => '👻 Ghost',
    'cat' => '🐱 Cat',
    'fish' => '🐠 Fish',
    'tiger' => '🐯 Tiger',
    _ => petId,
  };

  String _slotLabel(String slot) => switch (slot) {
    PetEquipmentSlot.head => 'Head',
    PetEquipmentSlot.face => 'Face',
    PetEquipmentSlot.body => 'Body',
    PetEquipmentSlot.back => 'Back',
    _ => slot,
  };

  String _skuLabel(String sku) => switch (sku) {
    'equip_straw_hat' => 'Straw Hat',
    'equip_crown' => 'Crown',
    'equip_sunglasses' => 'Sunglasses',
    'equip_ribbon' => 'Ribbon',
    _ => sku.replaceFirst('equip_', ''),
  };
}

enum _AnimState { idle, walk, sleep }
