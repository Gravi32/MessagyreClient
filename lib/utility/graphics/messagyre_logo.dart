import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:path_drawing/path_drawing.dart';

class MessagyreLogo extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;

  const MessagyreLogo({super.key, required this.size, this.backgroundColor, this.borderColor, this.borderWidth = 2, this.blurSigma = 4, this.padding});

  static const String _rawSvgPath =
      "M1275 3836 c-31 -16 -64 -44 -87 -73 -19 -27 -114 -154 -210 -283 -95 -129 -209 -282 -252 -340 -43 -58 -87 -123 -97 -146 -27 -59 -35 -170 -16 -215 12 -29 434 -743 756 -1277 73 -122 102 -156 154 -181 51 -25 132 -28 181 -7 18 7 117 64 219 125 199 119 228 145 253 228 23 77 7 126 -101 308 -52 87 -95 160 -95 162 0 2 -15 27 -34 56 -116 180 -327 548 -320 559 7 13 82 114 260 353 47 64 92 131 100 150 30 72 13 172 -38 236 -13 15 -299 230 -426 319 -57 40 -69 45 -130 48 -56 3 -75 -1 -117 -22z "
      "M3539 3571 c-36 -12 -45 -17 -365 -207 -173 -103 -304 -188 -322 -208 -40 -46 -55 -96 -50 -166 4 -61 -1 -51 169 -337 44 -73 79 -136 79 -141 0 -4 -15 -16 -32 -26 -285 -164 -694 -416 -718 -442 -37 -43 -54 -104 -47 -172 5 -45 23 -83 123 -250 64 -108 130 -218 146 -244 28 -44 99 -117 116 -118 4 -1 26 -5 50 -9 92 -18 85 -22 622 299 52 31 307 183 567 338 265 159 481 294 493 309 35 44 50 91 50 152 0 67 19 31 -368 681 -175 294 -279 459 -307 486 -56 55 -136 76 -206 55z";

  @override
  Widget build(BuildContext context) {
    final logoSize = Size(size, size);

    return Padding(
      padding: padding ?? .zero,
      child: SizedBox.fromSize(
        size: logoSize,
        child: Stack(
          alignment: .center,
          fit: .expand,
          children: [
            ClipPath(
              clipper: _LogoClipper(_rawSvgPath),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(color: backgroundColor ?? AppColors.accent.withTransparency(.75)),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(size: logoSize, painter: _LogoPainter(_rawSvgPath, borderColor ?? AppColors.accent, borderWidth)),
            ),
          ],
        ),
      ),
    );
  }
}

Path _generateTransformedPath(String data, Size canvasSize) {
  final path = parseSvgPathData(data);
  final bounds = path.getBounds();
  final scale = canvasSize.width / bounds.width < canvasSize.height / bounds.height ? canvasSize.width / bounds.width : canvasSize.height / bounds.height;

  final matrix = Matrix4.identity();
  matrix.scaleByDouble(scale, -scale, 1, 1);

  final tx = (canvasSize.width / scale - bounds.width) / 2 - bounds.left;
  final ty = -(canvasSize.height / scale + bounds.height) / 2 - bounds.top;
  matrix.translateByDouble(tx, ty, 0, 1);

  return path.transform(matrix.storage);
}

class _LogoClipper extends CustomClipper<Path> {
  final String pathData;
  _LogoClipper(this.pathData);

  @override
  Path getClip(Size size) => _generateTransformedPath(pathData, size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LogoPainter extends CustomPainter {
  final String pathData;
  final Color strokeColor;
  final double strokeWidth;

  _LogoPainter(this.pathData, this.strokeColor, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeWidth <= 0) return;
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = .round;

    canvas.drawPath(_generateTransformedPath(pathData, size), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
