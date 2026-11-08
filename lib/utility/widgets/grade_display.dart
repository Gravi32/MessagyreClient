import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';

/// A grade in a ring filled up to it (out of 6): grey under 6, orange just under 4, red below. Its weight, when it is
/// not 1, sits in a small pill under the ring; a planned/incoming/group grade has a small badge.
///
/// Everything is drawn inside [size] × ([size] + [labelHeight]): nothing spills out of the widget.
class GradeDisplay extends StatelessWidget {
  final double grade;
  final double size;
  final double weight;

  /// The ring's thickness; by default proportional to [size]
  final double? strokeWidth;
  final String? textBelow;
  final bool isIncoming;
  final bool isPlanned;
  final bool isGroup;
  final bool roundGrade;

  /// Drawn in white, for a card on the icon's gradient
  final bool onAccent;

  const GradeDisplay({
    super.key,
    required this.grade,
    this.size = 52,
    this.strokeWidth,
    this.weight = 1.0,
    this.textBelow,
    this.isIncoming = false,
    this.isPlanned = false,
    this.isGroup = false,
    this.roundGrade = true,
    this.onAccent = false,
  });

  /// Room under the ring for the weight's pill
  static const double labelHeight = 10;

  static String format(double grade, {bool round = true}) => grade.toStringAsFixed(round ? 1 : 2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

  @override
  Widget build(BuildContext context) {
    final stroke = strokeWidth ?? max(4.0, size * .085);
    final isHidden = grade == 0;
    final track = onAccent ? AppColors.white.withValues(alpha: .2) : AppColors.tertiaryBackground.adaptTo(context);
    final textColor = onAccent ? AppColors.white : AppColors.text.adaptTo(context);
    final color = onAccent
        ? (grade >= 4 ? AppColors.white : (grade > 3.75 ? const Color.fromRGBO(255, 190, 90, 1) : const Color.fromRGBO(255, 130, 120, 1)))
        : getGradeColor(grade, defaultColor: textColor);

    final List<List<dynamic>>? badge = isIncoming
        ? HugeIcons.strokeRoundedClock01
        : isPlanned
        ? HugeIcons.strokeRoundedCalendar04
        : isGroup
        ? HugeIcons.strokeRoundedLayers01
        : null;

    return SizedBox(
      width: size,
      height: size + labelHeight,
      child: Stack(
        clipBehavior: .none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: grade),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => CustomPaint(
                painter: _RingPainter(
                  progress: isHidden ? 0 : (animated / 6).clamp(0, 1),
                  stroke: stroke,
                  track: track,
                  color: color.withValues(alpha: .35 + weight.clamp(0, 1) * .65),
                  dashed: isHidden,
                  dashColor: AppColors.quaternaryText.adaptTo(context),
                ),
                child: isHidden
                    ? Center(
                        child: Text(
                          "?",
                          style: AppStyles.strongText(context).copyWith(fontSize: size * .34, color: AppColors.tertiaryText.adaptTo(context)),
                        ),
                      )
                    : Padding(
                        // The number stays inside the ring, whatever its length ("4.75")
                        padding: .all(stroke + size * .1),
                        child: FittedBox(
                          fit: .scaleDown,
                          child: Column(
                            mainAxisSize: .min,
                            children: [
                              Text(
                                format(animated, round: roundGrade),
                                textScaler: .noScaling,
                                style: AppStyles.strongText(context).copyWith(
                                  fontSize: size * .36,
                                  fontFamily: AppStyles.titleFontFamily,
                                  fontWeight: .w600,
                                  height: 1.05,
                                  color: grade < 4 ? color : textColor,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              if (textBelow != null)
                                Text(
                                  textBelow!,
                                  textScaler: .noScaling,
                                  style: AppStyles.caption(context).copyWith(fontSize: max(10, size * .13), height: 1.2),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // The weight, in a pill over the bottom of the ring
          if (weight != 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const .symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground.adaptTo(context),
                    borderRadius: .circular(8),
                    border: .all(color: AppColors.separator.adaptTo(context)),
                  ),
                  child: Text(
                    weight > 1 ? "×${weight.removeTrailingZero()}" : (getFractionString(weight) ?? "${(weight * 100).round()}%"),
                    textScaler: .noScaling,
                    style: AppStyles.caption(context).copyWith(fontWeight: .w600, color: AppColors.secondaryText.adaptTo(context), height: 1.3),
                  ),
                ),
              ),
            ),

          // A planned, incoming or group grade
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: max(18, size * .38),
                height: max(18, size * .38),
                alignment: .center,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: AppColors.secondaryBackground.adaptTo(context),
                  border: .all(color: AppColors.separator.adaptTo(context)),
                ),
                child: HugeIcon(icon: badge, size: max(11, size * .22), strokeWidth: 2, color: AppColors.secondaryText.adaptTo(context)),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color track;
  final Color color;
  final bool dashed;
  final Color dashColor;

  _RingPainter({required this.progress, required this.stroke, required this.track, required this.color, required this.dashed, required this.dashColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by half the stroke: the ring is drawn entirely inside the box
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = .stroke
      ..strokeWidth = stroke
      ..strokeCap = .round;

    if (dashed) {
      paint
        ..color = dashColor
        ..strokeWidth = max(2, stroke * .6);
      const dashes = 18;
      const sweep = 2 * pi / dashes;
      for (var i = 0; i < dashes; i++) {
        canvas.drawArc(ring, -pi / 2 + i * sweep, sweep * .45, false, paint);
      }
      return;
    }

    canvas.drawArc(ring, 0, 2 * pi, false, paint..color = track);
    if (progress > 0) canvas.drawArc(ring, -pi / 2, 2 * pi * progress, false, paint..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.stroke != stroke || old.track != track || old.color != color || old.dashed != dashed || old.dashColor != dashColor;
}
