import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/avatar_display_position.dart';
import 'juice_wrappers.dart';

class AvatarPositionEditorPage extends StatefulWidget {
  const AvatarPositionEditorPage({
    super.key,
    required this.imageProvider,
    required this.initialFraming,
    required this.title,
    required this.applyLabel,
    required this.cancelLabel,
    required this.hintLabel,
    required this.zoomLabel,
    required this.resetLabel,
  });

  final ImageProvider imageProvider;
  final AvatarFramingData initialFraming;
  final String title;
  final String applyLabel;
  final String cancelLabel;
  final String hintLabel;
  final String zoomLabel;
  final String resetLabel;

  @override
  State<AvatarPositionEditorPage> createState() =>
      _AvatarPositionEditorPageState();
}

class _AvatarPositionEditorPageState extends State<AvatarPositionEditorPage> {
  late Alignment _alignment;
  late double _scale;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  double _imageAspectRatio = 1;
  Offset? _gestureStartOffset;
  double? _gestureStartScale;
  Offset? _gestureStartFocalPoint;

  @override
  void initState() {
    super.initState();
    _alignment = widget.initialFraming.alignment;
    _scale = widget.initialFraming.scale
        .clamp(avatarRelativeMinScale, avatarRelativeMaxScale)
        .toDouble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImageAspectRatio();
  }

  @override
  void didUpdateWidget(covariant AvatarPositionEditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider) {
      _resolveImageAspectRatio();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStream = null;
    _imageStreamListener = null;
  }

  void _resolveImageAspectRatio() {
    _removeImageListener();
    final stream = widget.imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    final listener = ImageStreamListener((imageInfo, _) {
      final width = imageInfo.image.width.toDouble();
      final height = imageInfo.image.height.toDouble();
      if (!mounted || width <= 0 || height <= 0) {
        return;
      }
      setState(() {
        _imageAspectRatio = width / height;
      });
    }, onError: (_, _) {});
    _imageStream = stream;
    _imageStreamListener = listener;
    stream.addListener(listener);
  }

  AvatarFramingTransform _transformFor(Size cropSize, {double? scale}) {
    return AvatarFramingTransform.resolve(
      viewport: cropSize,
      imageAspectRatio: _imageAspectRatio,
      alignment: _alignment,
      scale: scale ?? _scale,
    );
  }

  void _handleScaleStart(ScaleStartDetails details, Size cropSize) {
    final transform = _transformFor(cropSize);
    _gestureStartOffset = transform.offset;
    _gestureStartScale = transform.relativeScale;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, Size cropSize) {
    final startOffset = _gestureStartOffset;
    final startScale = _gestureStartScale;
    final startPoint = _gestureStartFocalPoint;
    if (startOffset == null || startScale == null || startPoint == null) {
      return;
    }

    final nextScale = (startScale * details.scale)
        .clamp(avatarRelativeMinScale, avatarRelativeMaxScale)
        .toDouble();
    final nextTransform = _transformFor(cropSize, scale: nextScale);
    final nextOffset = startOffset + details.localFocalPoint - startPoint;

    setState(() {
      _scale = nextScale;
      _alignment = nextTransform.alignmentForOffset(nextOffset);
    });
  }

  void _setScale(double value, Size cropSize) {
    final nextScale = value
        .clamp(avatarRelativeMinScale, avatarRelativeMaxScale)
        .toDouble();
    final nextTransform = _transformFor(cropSize, scale: nextScale);
    setState(() {
      _scale = nextScale;
      _alignment = nextTransform.alignment;
    });
  }

  void _resetFraming() {
    setState(() {
      _alignment = Alignment.center;
      _scale = avatarRelativeMinScale;
    });
  }

  void _save(Size cropSize) {
    final transform = _transformFor(cropSize);
    Navigator.of(context).pop(
      AvatarFramingData(
        alignment: transform.alignment,
        scale: transform.relativeScale,
      ),
    );
  }

  double _resolveCropDiameter(BoxConstraints constraints) {
    const topReserve = 72.0;
    const bottomReserve = 172.0;
    const horizontalPadding = 32.0;
    final maxWidth = math.max(120.0, constraints.maxWidth - horizontalPadding);
    final maxHeight = math.max(
      120.0,
      constraints.maxHeight - topReserve - bottomReserve,
    );
    return math.min(maxWidth, maxHeight).clamp(120.0, 520.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cropDiameter = _resolveCropDiameter(constraints);
            final cropSize = Size.square(cropDiameter);
            final transform = _transformFor(cropSize);

            return Column(
              children: [
                _EditorTopBar(
                  title: widget.title,
                  cancelLabel: widget.cancelLabel,
                  applyLabel: widget.applyLabel,
                  onCancel: () => Navigator.of(context).pop(),
                  onApply: () => _save(cropSize),
                ),
                Expanded(
                  child: Center(
                    child: _AvatarCropFrame(
                      cropSize: cropSize,
                      imageProvider: widget.imageProvider,
                      transform: transform,
                      onScaleStart: (details) =>
                          _handleScaleStart(details, cropSize),
                      onScaleUpdate: (details) =>
                          _handleScaleUpdate(details, cropSize),
                    ),
                  ),
                ),
                _EditorControls(
                  hintLabel: widget.hintLabel,
                  zoomLabel: widget.zoomLabel,
                  resetLabel: widget.resetLabel,
                  scale: transform.relativeScale,
                  onScaleChanged: (value) => _setScale(value, cropSize),
                  onReset: _resetFraming,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AvatarFramingData {
  const AvatarFramingData({required this.alignment, required this.scale});

  final Alignment alignment;
  final double scale;
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.title,
    required this.cancelLabel,
    required this.applyLabel,
    required this.onCancel,
    required this.onApply,
  });

  final String title;
  final String cancelLabel;
  final String applyLabel;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _TopActionButton(
              key: const ValueKey<String>('avatar-editor-cancel-button'),
              label: cancelLabel,
              onTap: onCancel,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.mPlusRounded1c(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _TopActionButton(
              key: const ValueKey<String>('avatar-editor-save-button'),
              label: applyLabel,
              emphasized: true,
              onTap: onApply,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppTheme.secondaryColor : Colors.white;
    return Semantics(
      button: true,
      label: label,
      child: JuicyScaleButton(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.mPlusRounded1c(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarCropFrame extends StatelessWidget {
  const _AvatarCropFrame({
    required this.cropSize,
    required this.imageProvider,
    required this.transform,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  final Size cropSize;
  final ImageProvider imageProvider;
  final AvatarFramingTransform transform;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: cropSize,
      child: GestureDetector(
        key: const ValueKey<String>('avatar-editor-gesture-area'),
        behavior: HitTestBehavior.opaque,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
            ClipOval(
              child: ColoredBox(
                color: Colors.black,
                child: _AvatarFramedImage(
                  imageProvider: imageProvider,
                  transform: transform,
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.92),
                    width: 3,
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

class _AvatarFramedImage extends StatelessWidget {
  const _AvatarFramedImage({
    required this.imageProvider,
    required this.transform,
  });

  final ImageProvider imageProvider;
  final AvatarFramingTransform transform;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: transform.offset,
        child: Transform.scale(
          scale: transform.effectiveScale,
          child: SizedBox(
            width: transform.baseImageSize.width,
            height: transform.baseImageSize.height,
            child: Image(
              image: imageProvider,
              fit: BoxFit.fill,
              width: transform.baseImageSize.width,
              height: transform.baseImageSize.height,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorControls extends StatelessWidget {
  const _EditorControls({
    required this.hintLabel,
    required this.zoomLabel,
    required this.resetLabel,
    required this.scale,
    required this.onScaleChanged,
    required this.onReset,
  });

  final String hintLabel;
  final String zoomLabel;
  final String resetLabel;
  final double scale;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Colors.white, Color(0xFFFFF7EA)],
              ),
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hintLabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mPlusRounded1c(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: Text(
                          zoomLabel,
                          style: GoogleFonts.mPlusRounded1c(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.secondaryColor,
                            inactiveTrackColor: AppTheme.secondaryColor
                                .withValues(alpha: 0.25),
                            thumbColor: Colors.white,
                            overlayColor: AppTheme.secondaryColor.withValues(
                              alpha: 0.18,
                            ),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                          ),
                          child: Slider(
                            key: const ValueKey<String>(
                              'avatar-editor-zoom-slider',
                            ),
                            min: avatarRelativeMinScale,
                            max: avatarRelativeMaxScale,
                            divisions: 30,
                            value: scale
                                .clamp(
                                  avatarRelativeMinScale,
                                  avatarRelativeMaxScale,
                                )
                                .toDouble(),
                            label: '${scale.toStringAsFixed(1)}x',
                            onChanged: onScaleChanged,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${scale.toStringAsFixed(1)}x',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.mPlusRounded1c(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ResetButton(label: resetLabel, onTap: onReset),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: JuicyScaleButton(
        onTap: onTap,
        child: Container(
          key: const ValueKey<String>('avatar-editor-reset-button'),
          constraints: const BoxConstraints(minWidth: 92, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.mPlusRounded1c(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
