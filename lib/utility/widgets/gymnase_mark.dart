import 'package:flutter/widgets.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

/// The shape of Messagyre's icon: the Gymnase de Renens seen from above, with rounded corners (two blocks, the
/// paths of assets/icons/purple.svg). Drawn rather than loaded: it takes any color, at any size, without a package.
class GymnaseMark extends StatelessWidget {
  final double size;
  final Color? color;
  final Gradient? gradient;

  const GymnaseMark({super.key, this.size = 24, this.color, this.gradient});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GymnasePainter(color ?? AppColors.accent, gradient)),
    );
  }
}

/// A class chat's picture: the icon's shape on the accent color, round like a profile picture
class ClassAvatar extends StatelessWidget {
  final double size;
  const ClassAvatar({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromRGBO(196, 40, 204, 1), AppColors.accent, Color.fromRGBO(120, 6, 150, 1)],
        ),
      ),
      alignment: Alignment.center,
      child: GymnaseMark(size: size * .58, color: AppColors.white),
    );
  }
}

class _GymnasePainter extends CustomPainter {
  final Color color;
  final Gradient? gradient;
  _GymnasePainter(this.color, this.gradient);

  /// The two blocks of the icon, in the SVG's coordinates (y going up, 5000 units)
  static const _paths = [
    "M1275 3836 c-31 -16 -64 -44 -87 -73 -19 -27 -114 -154 -210 -283 -95 -129 -209 -282 -252 -340 -43 -58 -87 -123 "
        "-97 -146 -27 -59 -35 -170 -16 -215 12 -29 434 -743 756 -1277 73 -122 102 -156 154 -181 51 -25 132 -28 181 -7 18 "
        "7 117 64 219 125 199 119 228 145 253 228 23 77 7 126 -101 308 -52 87 -95 160 -95 162 0 2 -15 27 -34 56 -116 180 "
        "-327 548 -320 559 7 13 82 114 260 353 47 64 92 131 100 150 30 72 13 172 -38 236 -13 15 -299 230 -426 319 -57 40 "
        "-69 45 -130 48 -56 3 -75 -1 -117 -22z",
    "M3539 3571 c-36 -12 -45 -17 -365 -207 -173 -103 -304 -188 -322 -208 -40 -46 -55 -96 -50 -166 4 -61 -1 -51 169 "
        "-337 44 -73 79 -136 79 -141 0 -4 -15 -16 -32 -26 -285 -164 -694 -416 -718 -442 -37 -43 -54 -104 -47 -172 5 -45 "
        "23 -83 123 -250 64 -108 130 -218 146 -244 28 -44 99 -117 116 -118 4 -1 26 -5 50 -9 92 -18 85 -22 622 299 52 31 "
        "307 183 567 338 265 159 481 294 493 309 35 44 50 91 50 152 0 67 19 31 -368 681 -175 294 -279 459 -307 486 -56 55 "
        "-136 76 -206 55z",
  ];

  static final Path _shape = () {
    final path = Path();
    for (final data in _paths) {
      path.addPath(_parse(data), Offset.zero);
    }
    return path;
  }();

  /// Only what these paths use: an absolute move, relative cubic curves and a close
  static Path _parse(String data) {
    final path = Path();
    final tokens = RegExp(r'[Mcz]|-?\d+(?:\.\d+)?').allMatches(data).map((m) => m.group(0)!).toList();
    var x = 0.0, y = 0.0;
    var command = "";
    var i = 0;
    double next() => double.parse(tokens[i++]);

    while (i < tokens.length) {
      final token = tokens[i];
      if (token == "M" || token == "c" || token == "z") {
        command = token;
        i++;
        if (command == "z") path.close();
        continue;
      }
      if (command == "M") {
        x = next();
        y = -next();
        path.moveTo(x, y);
        command = "c";
      } else if (command == "c") {
        final x1 = x + next(), y1 = y - next(), x2 = x + next(), y2 = y - next(), ex = x + next(), ey = y - next();
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        x = ex;
        y = ey;
      } else {
        i++;
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = _shape.getBounds();
    final scale = size.shortestSide / (bounds.width > bounds.height ? bounds.width : bounds.height);
    final dx = (size.width - bounds.width * scale) / 2, dy = (size.height - bounds.height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);
    canvas.translate(-bounds.left, -bounds.top);

    final paint = Paint()..isAntiAlias = true;
    if (gradient != null) {
      paint.shader = gradient!.createShader(bounds);
    } else {
      paint.color = color;
    }
    canvas.drawPath(_shape, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GymnasePainter oldDelegate) => oldDelegate.color != color || oldDelegate.gradient != gradient;
}
