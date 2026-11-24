import 'dart:math';

import 'package:flutter/widgets.dart';

/// A band of light that sweeps diagonally every few seconds (the shimmering announcements). It fills its parent:
/// put it over the card in a Stack (Positioned.fill).
///
/// Clipped to [borderRadius], so it never spills out of the card. Each sweep fades in as it
/// starts and out as it ends (no hard edge entering or leaving), then waits. It stops with the system's "reduce
/// motion", and Flutter pauses it in tabs that aren't shown (TickerMode).
class Shimmer extends StatefulWidget {
  final BorderRadius borderRadius;
  final bool enabled;
  final Color color;

  const Shimmer({super.key, required this.borderRadius, this.enabled = true, this.color = const Color(0xFFFFFFFF)});

  /// One sweep, then the pause before the next one
  static const sweep = Duration(milliseconds: 1400);
  static const pause = Duration(milliseconds: 2200);

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: Shimmer.sweep + Shimmer.pause);

  bool get shouldRun => widget.enabled && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(covariant Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  void _update() {
    if (shouldRun && !controller.isAnimating) {
      controller.repeat();
    } else if (!shouldRun && controller.isAnimating) {
      controller.stop();
      controller.value = 0;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: RepaintBoundary(
          child: CustomPaint(painter: _ShimmerPainter(controller, widget.color), size: Size.infinite),
        ),
      ),
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _ShimmerPainter(this.animation, this.color) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final total = Shimmer.sweep.inMilliseconds + Shimmer.pause.inMilliseconds;
    final progress = animation.value * total / Shimmer.sweep.inMilliseconds;
    if (progress <= 0 || progress >= 1) return;

    // Fades in over the first quarter of the sweep and out over the last one, eased
    final fade = Curves.easeInOut.transform((min(progress, 1 - progress) / .25).clamp(0.0, 1.0));
    if (fade <= 0) return;

    final eased = Curves.easeInOutSine.transform(progress);
    final bandWidth = max(80.0, size.width * .35);
    // From fully left of the card to fully right of it, slanted (its top leans to the right)
    final slant = size.height * .5;
    final center = -bandWidth - slant + eased * (size.width + 2 * (bandWidth + slant));

    // Drawn straight, then skewed: the gradient leans with the band
    final band = Rect.fromLTWH(center - bandWidth / 2, -size.height / 2, bandWidth, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: .32 * fade), color.withValues(alpha: 0)],
        stops: const [0, .5, 1],
      ).createShader(band);

    canvas.save();
    canvas.translate(0, size.height / 2);
    canvas.skew(-2 * slant / size.height, 0);
    canvas.drawRect(band, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) => oldDelegate.color != color;
}
