import 'package:flutter/material.dart';

class CutoutWidget extends StatelessWidget {
  final double cutoutSize;
  final Widget childToCutout;
  final Widget? childInCutout;
  final Alignment cutoutAlignment;

  const CutoutWidget({super.key, required this.cutoutSize, required this.childToCutout, this.childInCutout, this.cutoutAlignment = .bottomRight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(clipper: _CutoutClipper(cutoutSize: cutoutSize, alignment: cutoutAlignment), child: childToCutout),
        Positioned.fill(child: Align(alignment: cutoutAlignment, child: SizedBox(width: cutoutSize, height: cutoutSize, child: Center(child: childInCutout)))),
      ],
    );
  }
}

class _CutoutClipper extends CustomClipper<Path> {
  final double cutoutSize;
  final Alignment alignment;

  _CutoutClipper({required this.cutoutSize, required this.alignment});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final double centerX = ((alignment.x + 1) / 2) * size.width;
    final double centerY = ((alignment.y + 1) / 2) * size.height;

    final Offset center = Offset(
      centerX.clamp(0.0 + cutoutSize / 2, size.width - cutoutSize / 2),
      centerY.clamp(0.0 + cutoutSize / 2, size.height - cutoutSize / 2),
    );

    final hole = Path()..addOval(Rect.fromCircle(center: center, radius: cutoutSize / 2));

    return Path.combine(PathOperation.difference, path, hole);
  }

  @override
  bool shouldReclip(_CutoutClipper oldClipper) => oldClipper.cutoutSize != cutoutSize || oldClipper.alignment != alignment;
}
