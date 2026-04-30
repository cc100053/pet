import 'package:flutter/material.dart';

import 'pet_animation_frames.dart';

typedef PetAnimationFrameWidgetBuilder =
    Widget Function(
      BuildContext context,
      String asset,
      double animationProgress,
      PetFrameSequence? sequence,
    );

class PetAnimationFrameBuilder extends StatefulWidget {
  const PetAnimationFrameBuilder({
    super.key,
    required this.sourceAsset,
    required this.builder,
  });

  final String sourceAsset;
  final PetAnimationFrameWidgetBuilder builder;

  @override
  State<PetAnimationFrameBuilder> createState() =>
      _PetAnimationFrameBuilderState();
}

class _PetAnimationFrameBuilderState extends State<PetAnimationFrameBuilder>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (!_disableAnimationForWidgetTests) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(hours: 1),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sequence = PetAnimationFrames.sequenceForAsset(widget.sourceAsset);
    if (sequence == null) {
      return widget.builder(context, widget.sourceAsset, 0, null);
    }
    final controller = _controller;
    if (controller == null) {
      return widget.builder(context, sequence.assetForProgress(0), 0, sequence);
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final elapsedMs = controller.lastElapsedDuration?.inMilliseconds ?? 0;
        final progress = sequence.progressForElapsedMs(elapsedMs);
        return widget.builder(
          context,
          sequence.assetForProgress(progress),
          progress,
          sequence,
        );
      },
    );
  }

  bool get _disableAnimationForWidgetTests {
    var disabled = false;
    assert(() {
      disabled = WidgetsBinding.instance.runtimeType.toString().contains(
        'TestWidgetsFlutterBinding',
      );
      return true;
    }());
    return disabled;
  }
}

class PetAnimatedImage extends StatelessWidget {
  const PetAnimatedImage({
    super.key,
    required this.sourceAsset,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.high,
    this.gaplessPlayback = true,
    this.errorBuilder,
    this.frameBuilder,
  });

  final String sourceAsset;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageFrameBuilder? frameBuilder;

  @override
  Widget build(BuildContext context) {
    return PetAnimationFrameBuilder(
      sourceAsset: sourceAsset,
      builder: (context, asset, _, sequence) {
        return Image.asset(
          asset,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: gaplessPlayback,
          filterQuality: filterQuality,
          errorBuilder: errorBuilder,
          frameBuilder: frameBuilder,
        );
      },
    );
  }
}
