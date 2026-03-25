import 'package:flutter/cupertino.dart';

class CutoutWidget extends StatelessWidget {
  final double size;
  final Widget childToCutout;
  final Widget? childInCutout;
  final Alignment alignment;

  const CutoutWidget({super.key, required this.size, required this.childToCutout, this.childInCutout, this.alignment = Alignment.bottomRight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(clipper: _CutoutClipper(size: size, alignment: alignment), child: childToCutout),
        Positioned(
          bottom: 0,
          right: 0,
          width: size,
          height: size,
          child: Container(alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle), child: childInCutout),
        ),
      ],
    );
  }
}

class _CutoutClipper extends CustomClipper<Path> {
  final double size;
  final Alignment alignment;

  _CutoutClipper({required this.size, this.alignment = Alignment.bottomRight});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(alignment.x, alignment.y, size.width, size.height));
    final hole = Path()..addOval(Rect.fromCircle(center: Offset(size.width - this.size / 2, size.height - this.size / 2), radius: this.size / 2));
    return Path.combine(PathOperation.difference, path, hole);
  }

  @override
  bool shouldReclip(_) => true;
}
