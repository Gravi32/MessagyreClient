import 'package:flutter/widgets.dart';

/// Fades in while rising a little, [index] × 40 ms after the others (a list arrives one row after the other).
/// With [enabled] false it is shown at once: the rows built later, while scrolling, don't animate.
class Appear extends StatelessWidget {
  final int index;
  final bool enabled;
  final Widget child;

  const Appear({super.key, this.index = 0, this.enabled = true, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final delay = (index.clamp(0, 10) * 40).toDouble();
    final total = 340 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total.round()),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
    );
  }
}

/// Remembers when a page appeared: its rows animate only during its first second (not when scrolled to later)
mixin AppearOnOpen<T extends StatefulWidget> on State<T> {
  final _openedAt = DateTime.now();
  bool get isOpening => DateTime.now().difference(_openedAt) < const Duration(milliseconds: 900);
}
