import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/ui/app_dialog.dart';
import '../../../shared/ui/juice_wrappers.dart';
import '../../pet/equipment_catalog.dart';
import '../../pet/pet_animation_frames.dart';
import '../../pet/pet_catalog.dart';
import '../../pet/pet_sockets.dart';
import '../widgets/pet_equipment_layout.dart';

enum DressUpFitAnimationState { idle, walk, sleep }

class DressUpFitDraft {
  const DressUpFitDraft({
    required this.petId,
    required this.equipmentSku,
    required this.slot,
    required this.state,
    required this.facingRight,
    required this.socket,
    required this.anchor,
    required this.sizeRatio,
    required this.overrideOffset,
    required this.overrideScale,
  });

  final String petId;
  final String equipmentSku;
  final String slot;
  final DressUpFitAnimationState state;
  final bool facingRight;
  final PetSocket socket;
  final EquipmentAnchor anchor;
  final EquipmentSize sizeRatio;
  final Offset overrideOffset;
  final double overrideScale;

  DressUpFitDraft copyWith({
    String? petId,
    String? equipmentSku,
    String? slot,
    DressUpFitAnimationState? state,
    bool? facingRight,
    PetSocket? socket,
    EquipmentAnchor? anchor,
    EquipmentSize? sizeRatio,
    Offset? overrideOffset,
    double? overrideScale,
  }) {
    return DressUpFitDraft(
      petId: petId ?? this.petId,
      equipmentSku: equipmentSku ?? this.equipmentSku,
      slot: slot ?? this.slot,
      state: state ?? this.state,
      facingRight: facingRight ?? this.facingRight,
      socket: socket ?? this.socket,
      anchor: anchor ?? this.anchor,
      sizeRatio: sizeRatio ?? this.sizeRatio,
      overrideOffset: overrideOffset ?? this.overrideOffset,
      overrideScale: overrideScale ?? this.overrideScale,
    );
  }
}

class DressUpFitToolPage extends StatefulWidget {
  const DressUpFitToolPage({super.key});

  @override
  State<DressUpFitToolPage> createState() => _DressUpFitToolPageState();
}

class _DressUpFitToolPageState extends State<DressUpFitToolPage>
    with SingleTickerProviderStateMixin {
  static const Size _petSize = Size.square(220);
  static const double _controlStep = 0.01;
  static const Duration _ghostIdleMotionDuration = Duration(
    milliseconds: PetAnimationFrames.ghostIdleTotalDurationMs,
  );

  late DressUpFitDraft _draft;
  late final AnimationController _idleMotionController;
  bool _equipmentInFront = true;

  @override
  void initState() {
    super.initState();
    _idleMotionController = AnimationController(
      vsync: this,
      duration: _ghostIdleMotionDuration,
    )..repeat();
    final equipment = EquipmentCatalog.items.first;
    final petId = PetCatalog.pets.first.id;
    _draft = _buildDraft(
      petId: petId,
      equipment: equipment,
      slot: equipment.slot,
      state: DressUpFitAnimationState.idle,
      facingRight: true,
    );
  }

  @override
  void dispose() {
    _idleMotionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.mPlusRounded1cTextTheme(
      Theme.of(context).textTheme,
    );

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7EA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF7EA),
          elevation: 0,
          foregroundColor: Colors.black,
          title: const Text(
            'Dress-up Fit Tool',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final preview = _ToolCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Preview only. Copy generated config into code.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Gap(16),
                    Center(child: _buildPreview()),
                    const Gap(16),
                    _buildPreviewLegend(),
                  ],
                ),
              );
              final controls = _ToolCard(child: _buildControls());

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 340, child: preview),
                          const Gap(16),
                          Expanded(child: controls),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [preview, const Gap(16), controls],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final equipment = _selectedEquipment;
    final pet = PetCatalog.byId(_draft.petId);
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: AnimatedBuilder(
            animation: _idleMotionController,
            builder: (context, _) {
              final socketConfig = PetSocketCatalog.forPet(_draft.petId);
              final motionOffset =
                  socketConfig?.resolveMotion(
                    slot: _draft.slot,
                    animationProgress: _idleMotionController.value,
                    isWalking: _draft.state == DressUpFitAnimationState.walk,
                    isSleeping: _draft.state == DressUpFitAnimationState.sleep,
                  ) ??
                  Offset.zero;
              final placement = resolveEquipmentPlacement(
                petSize: _petSize,
                socket: _draft.socket,
                anchor: _draft.anchor,
                sizeRatio: _draft.sizeRatio,
                normalizedOffset: _draft.overrideOffset + motionOffset,
                scale: _draft.overrideScale,
              );
              final equipmentLayer = _buildEquipmentLayer(equipment, placement);
              final petLayer = Image.asset(
                _assetForState(pet, _draft.state),
                width: _petSize.width,
                height: _petSize.height,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: pet.accent.withValues(alpha: 0.2),
                  child: const SizedBox.expand(),
                ),
              );

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(
                  _draft.facingRight ? 1.0 : -1.0,
                  1.0,
                  1.0,
                ),
                child: SizedBox(
                  width: _petSize.width,
                  height: _petSize.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _FitGridPainter()),
                      ),
                      if (!_equipmentInFront) equipmentLayer,
                      Positioned.fill(child: petLayer),
                      if (_equipmentInFront) equipmentLayer,
                      Positioned(
                        left: placement.socketOffset.dx - 6,
                        top: placement.socketOffset.dy - 6,
                        child: const _Marker(
                          key: Key('dress_up_fit_socket_marker'),
                          color: Color(0xFFFF6B6B),
                          label: 'S',
                        ),
                      ),
                      Positioned(
                        left:
                            placement.topLeft.dx +
                            placement.anchorOffset.dx -
                            6,
                        top:
                            placement.topLeft.dy +
                            placement.anchorOffset.dy -
                            6,
                        child: const _Marker(
                          key: Key('dress_up_fit_anchor_marker'),
                          color: Color(0xFF4FB8D9),
                          label: 'A',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentLayer(
    EquipmentDefinition equipment,
    EquipmentPlacement placement,
  ) {
    return Positioned(
      key: const Key('dress_up_fit_equipment_layer'),
      left: placement.topLeft.dx,
      top: placement.topLeft.dy,
      child: SizedBox(
        width: placement.itemSize.width,
        height: placement.itemSize.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              equipment.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewLegend() {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: const [
        _LegendDot(color: Color(0xFFFF6B6B), label: 'Socket'),
        _LegendDot(color: Color(0xFF4FB8D9), label: 'Anchor'),
        _LegendDot(color: Color(0xFFF59E0B), label: 'Item bounds'),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSelectors(),
        const Gap(18),
        _SectionTitle('Socket (${_slotToken(_draft.slot)})'),
        _buildSliderControl(
          key: const Key('dress_up_fit_socket_x_slider'),
          label: 'Socket x',
          value: _draft.socket.x,
          min: 0,
          max: 1,
          onChanged: (value) => _updateSocket(x: value),
        ),
        _buildSliderControl(
          key: const Key('dress_up_fit_socket_y_slider'),
          label: 'Socket y',
          value: _draft.socket.y,
          min: 0,
          max: 1,
          onChanged: (value) => _updateSocket(y: value),
        ),
        _buildResetButton('Reset socket', _resetSocket),
        const Gap(18),
        const _SectionTitle('Equipment'),
        _buildSliderControl(
          key: const Key('dress_up_fit_anchor_x_slider'),
          label: 'Anchor x',
          value: _draft.anchor.x,
          min: 0,
          max: 1,
          onChanged: (value) => _updateAnchor(x: value),
        ),
        _buildSliderControl(
          key: const Key('dress_up_fit_anchor_y_slider'),
          label: 'Anchor y',
          value: _draft.anchor.y,
          min: 0,
          max: 1,
          onChanged: (value) => _updateAnchor(y: value),
        ),
        _buildSliderControl(
          key: const Key('dress_up_fit_size_w_slider'),
          label: 'Width ratio',
          value: _draft.sizeRatio.w,
          min: 0.05,
          max: 1.5,
          onChanged: (value) => _updateSize(w: value),
        ),
        _buildSliderControl(
          key: const Key('dress_up_fit_size_h_slider'),
          label: 'Height ratio',
          value: _draft.sizeRatio.h,
          min: 0.05,
          max: 1.5,
          onChanged: (value) => _updateSize(h: value),
        ),
        _buildResetButton('Reset item', _resetItem),
        const Gap(18),
        const _SectionTitle('Per-pet override'),
        _buildSliderControl(
          key: const Key('dress_up_fit_override_dx_slider'),
          label: 'Offset dx',
          value: _draft.overrideOffset.dx,
          min: -0.5,
          max: 0.5,
          onChanged: (value) => _updateOverrideOffset(dx: value),
        ),
        _buildSliderControl(
          key: const Key('dress_up_fit_override_dy_slider'),
          label: 'Offset dy',
          value: _draft.overrideOffset.dy,
          min: -0.5,
          max: 0.5,
          onChanged: (value) => _updateOverrideOffset(dy: value),
        ),
        _buildSliderControl(
          key: const Key('dress_up_fit_override_scale_slider'),
          label: 'Scale',
          value: _draft.overrideScale,
          min: 0.4,
          max: 1.8,
          onChanged: (value) => setState(
            () => _draft = _draft.copyWith(overrideScale: _round(value)),
          ),
        ),
        _buildResetButton('Reset override', _resetOverride),
        const Gap(20),
        _buildSnippetPanel(
          title: 'Pet socket snippet',
          hint: 'Paste into lib/features/pet/pet_sockets.dart',
          snippet: _petSocketSnippet,
          copiedMessage: 'Copied pet socket snippet.',
        ),
        _buildSnippetPanel(
          title: 'Equipment definition snippet',
          hint: 'Paste into lib/features/pet/equipment_catalog.dart',
          snippet: _equipmentSnippet,
          copiedMessage: 'Copied equipment snippet.',
        ),
        _buildSnippetPanel(
          title: 'Per-pet override snippet',
          hint: 'Paste into the matching EquipmentDefinition.',
          snippet: _overrideSnippet,
          copiedMessage: 'Copied per-pet override snippet.',
        ),
      ],
    );
  }

  Widget _buildSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown<String>(
                key: const Key('dress_up_fit_pet_dropdown'),
                label: 'Pet',
                value: _draft.petId,
                items: PetCatalog.pets.map((pet) => pet.id).toList(),
                labelFor: (value) => value,
                onChanged: _selectPet,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _buildDropdown<String>(
                key: const Key('dress_up_fit_equipment_dropdown'),
                label: 'Equipment',
                value: _draft.equipmentSku,
                items: EquipmentCatalog.items.map((item) => item.sku).toList(),
                labelFor: (value) => value,
                onChanged: _selectEquipment,
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown<String>(
                key: const Key('dress_up_fit_slot_dropdown'),
                label: 'Slot',
                value: _draft.slot,
                items: PetEquipmentSlot.values,
                labelFor: _slotToken,
                onChanged: _selectSlot,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _LayerToggle(
                inFront: _equipmentInFront,
                onChanged: (value) => setState(() => _equipmentInFront = value),
              ),
            ),
          ],
        ),
        const Gap(14),
        _SegmentRow<DressUpFitAnimationState>(
          label: 'Animation',
          values: DressUpFitAnimationState.values,
          selected: _draft.state,
          labelFor: _stateLabel,
          onChanged: _selectState,
        ),
        const Gap(12),
        _SegmentRow<bool>(
          label: 'Facing preview',
          values: const [true, false],
          selected: _draft.facingRight,
          labelFor: (value) => value ? 'Right' : 'Left',
          onChanged: (value) {
            setState(() => _draft = _draft.copyWith(facingRight: value));
          },
        ),
      ],
    );
  }

  Widget _buildSliderControl({
    required Key key,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _format(value),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Gap(8),
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => onChanged(
                  (value - _controlStep).clamp(min, max).toDouble(),
                ),
              ),
              const Gap(6),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => onChanged(
                  (value + _controlStep).clamp(min, max).toDouble(),
                ),
              ),
            ],
          ),
          Slider(
            key: key,
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: ((max - min) / _controlStep).round(),
            activeColor: AppTheme.primaryColor,
            onChanged: (next) => onChanged(_round(next)),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(String label, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerLeft,
      child: JuicyScaleButton(
        onTap: onTap,
        child: _PillButton(label: label, icon: Icons.refresh_rounded),
      ),
    );
  }

  Widget _buildSnippetPanel({
    required String title,
    required String hint,
    required String snippet,
    required String copiedMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  JuicyScaleButton(
                    onTap: () => _copySnippet(snippet, copiedMessage),
                    child: const _PillButton(
                      label: 'Copy',
                      icon: Icons.copy_rounded,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Text(
                hint,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.62),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              SelectableText(
                snippet,
                key: Key('dress_up_fit_snippet_${title.hashCode}'),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required Key key,
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    return KeyedSubtree(
      key: key,
      child: DropdownButtonFormField<T>(
        key: ValueKey<Object?>(value),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelFor(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        selectedItemBuilder: (context) {
          return [
            for (final item in items)
              Text(
                labelFor(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ];
        },
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  DressUpFitDraft _buildDraft({
    required String petId,
    required EquipmentDefinition equipment,
    required String slot,
    required DressUpFitAnimationState state,
    required bool facingRight,
  }) {
    final override =
        equipment.petOverrides[petId] ?? const EquipmentFitOverride();
    return DressUpFitDraft(
      petId: petId,
      equipmentSku: equipment.sku,
      slot: slot,
      state: state,
      facingRight: facingRight,
      socket: _catalogSocket(petId, slot, state),
      anchor: equipment.anchor,
      sizeRatio: equipment.sizeRatio,
      overrideOffset: override.offset,
      overrideScale: override.scale,
    );
  }

  void _selectPet(String petId) {
    setState(() {
      final equipment = _selectedEquipment;
      _draft = _buildDraft(
        petId: petId,
        equipment: equipment,
        slot: _draft.slot,
        state: _draft.state,
        facingRight: _draft.facingRight,
      );
    });
  }

  void _selectEquipment(String sku) {
    final equipment = EquipmentCatalog.bySku(sku);
    if (equipment == null) {
      return;
    }
    setState(() {
      _draft = _buildDraft(
        petId: _draft.petId,
        equipment: equipment,
        slot: equipment.slot,
        state: _draft.state,
        facingRight: _draft.facingRight,
      );
    });
  }

  void _selectSlot(String slot) {
    setState(() {
      _draft = _draft.copyWith(
        slot: slot,
        socket: _catalogSocket(_draft.petId, slot, _draft.state),
      );
    });
  }

  void _selectState(DressUpFitAnimationState state) {
    setState(() {
      _draft = _draft.copyWith(
        state: state,
        socket: _catalogSocket(_draft.petId, _draft.slot, state),
      );
    });
  }

  void _updateSocket({double? x, double? y}) {
    setState(() {
      _draft = _draft.copyWith(
        socket: PetSocket(
          x: _round(x ?? _draft.socket.x),
          y: _round(y ?? _draft.socket.y),
        ),
      );
    });
  }

  void _updateAnchor({double? x, double? y}) {
    setState(() {
      _draft = _draft.copyWith(
        anchor: EquipmentAnchor(
          x: _round(x ?? _draft.anchor.x),
          y: _round(y ?? _draft.anchor.y),
        ),
      );
    });
  }

  void _updateSize({double? w, double? h}) {
    setState(() {
      _draft = _draft.copyWith(
        sizeRatio: EquipmentSize(
          w: _round(w ?? _draft.sizeRatio.w),
          h: _round(h ?? _draft.sizeRatio.h),
        ),
      );
    });
  }

  void _updateOverrideOffset({double? dx, double? dy}) {
    setState(() {
      _draft = _draft.copyWith(
        overrideOffset: Offset(
          _round(dx ?? _draft.overrideOffset.dx),
          _round(dy ?? _draft.overrideOffset.dy),
        ),
      );
    });
  }

  void _resetSocket() {
    setState(() {
      _draft = _draft.copyWith(
        socket: _catalogSocket(_draft.petId, _draft.slot, _draft.state),
      );
    });
  }

  void _resetItem() {
    final equipment = _selectedEquipment;
    setState(() {
      _draft = _draft.copyWith(
        anchor: equipment.anchor,
        sizeRatio: equipment.sizeRatio,
      );
    });
  }

  void _resetOverride() {
    setState(() {
      _draft = _draft.copyWith(overrideOffset: Offset.zero, overrideScale: 1);
    });
  }

  Future<void> _copySnippet(String snippet, String message) async {
    await Clipboard.setData(ClipboardData(text: snippet));
    if (!mounted) {
      return;
    }
    showJuiceSnackbar(context: context, message: message);
  }

  PetSocket _catalogSocket(
    String petId,
    String slot,
    DressUpFitAnimationState state,
  ) {
    final config = PetSocketCatalog.forPet(petId);
    return config?.resolve(
          slot,
          isWalking: state == DressUpFitAnimationState.walk,
          isSleeping: state == DressUpFitAnimationState.sleep,
        ) ??
        const PetSocket(x: 0.5, y: 0.5);
  }

  EquipmentDefinition get _selectedEquipment {
    return EquipmentCatalog.bySku(_draft.equipmentSku) ??
        EquipmentCatalog.items.first;
  }

  String _assetForState(PetDefinition pet, DressUpFitAnimationState state) {
    return switch (state) {
      DressUpFitAnimationState.idle => pet.stayAsset,
      DressUpFitAnimationState.walk => pet.walkAsset,
      DressUpFitAnimationState.sleep => pet.sleepAsset,
    };
  }

  String get _petSocketSnippet {
    final line =
        '${_slotReference(_draft.slot)}: PetSocket(x: ${_format(_draft.socket.x)}, y: ${_format(_draft.socket.y)}),';
    return switch (_draft.state) {
      DressUpFitAnimationState.idle => line,
      DressUpFitAnimationState.walk => 'walkOverrides: {\n  $line\n},',
      DressUpFitAnimationState.sleep => 'sleepOverrides: {\n  $line\n},',
    };
  }

  String get _equipmentSnippet {
    return 'anchor: EquipmentAnchor(x: ${_format(_draft.anchor.x)}, y: ${_format(_draft.anchor.y)}),\n'
        'sizeRatio: EquipmentSize(w: ${_format(_draft.sizeRatio.w)}, h: ${_format(_draft.sizeRatio.h)}),';
  }

  String get _overrideSnippet {
    return 'petOverrides: {\n'
        "  '${_draft.petId}': EquipmentFitOverride(\n"
        '    offset: Offset(${_format(_draft.overrideOffset.dx)}, ${_format(_draft.overrideOffset.dy)}),\n'
        '    scale: ${_format(_draft.overrideScale)},\n'
        '  ),\n'
        '},';
  }

  String _slotReference(String slot) => 'PetEquipmentSlot.${_slotToken(slot)}';

  String _slotToken(String slot) {
    switch (slot) {
      case PetEquipmentSlot.head:
        return 'head';
      case PetEquipmentSlot.body:
        return 'body';
      case PetEquipmentSlot.back:
        return 'back';
    }
    return slot;
  }

  String _stateLabel(DressUpFitAnimationState state) {
    return switch (state) {
      DressUpFitAnimationState.idle => 'Idle',
      DressUpFitAnimationState.walk => 'Walk',
      DressUpFitAnimationState.sleep => 'Sleep',
    };
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  String _format(double value) => value.toStringAsFixed(2);
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFFF7EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const Gap(6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return JuicyScaleButton(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: SizedBox(width: 34, height: 34, child: Icon(icon, size: 20)),
      ),
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              JuicyScaleButton(
                onTap: () => onChanged(value),
                child: _SelectableChip(
                  label: labelFor(value),
                  selected: value == selected,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({required this.inFront, required this.onChanged});

  final bool inFront;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SegmentRow<bool>(
      label: 'Layer check',
      values: const [true, false],
      selected: inFront,
      labelFor: (value) => value ? 'Front' : 'Behind',
      onChanged: onChanged,
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? AppTheme.secondaryColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: const SizedBox(width: 12, height: 12),
        ),
        const Gap(5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: SizedBox(
        width: 12,
        height: 12,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FitGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const divisions = 4;
    for (var index = 1; index < divisions; index++) {
      final x = size.width * index / divisions;
      final y = size.height * index / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final centerPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.2);
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
