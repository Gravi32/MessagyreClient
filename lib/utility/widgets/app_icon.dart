import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// An icon of [AppIcons]. Use it instead of [HugeIcon]: a HugeIcon is made of several strokes drawn one over the
/// other, and with a see-through color (the secondary texts' grey, a faded state) the places where they overlap
/// show as darker spots. Here the icon is drawn opaque and made see-through as a whole, with [Opacity].
class AppIcon extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color? color;
  final double? size;
  final double? strokeWidth;

  const AppIcon({required this.icon, this.color, this.size, this.strokeWidth, super.key});

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    final alpha = resolved.a;
    final drawn = HugeIcon(icon: icon, color: resolved.withValues(alpha: 1), size: size, strokeWidth: strokeWidth);

    if (alpha >= 1) return drawn;
    if (alpha <= 0) return SizedBox.square(dimension: size ?? IconTheme.of(context).size ?? 24);
    return Opacity(opacity: alpha, child: drawn);
  }
}
