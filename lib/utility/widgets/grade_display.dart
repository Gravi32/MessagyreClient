import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/utility.dart';

class GradeDisplay extends StatefulWidget {
  final double grade;
  final double size;
  final double weight;
  final bool isIncoming;
  final bool isPlanned;
  final bool isGroup;
  final bool roundGrade;

  const GradeDisplay({
    super.key,
    required this.grade,
    this.size = 48,
    this.weight = 1.0,
    this.isIncoming = false,
    this.isPlanned = false,
    this.isGroup = false,
    this.roundGrade = true,
  });

  @override
  State<GradeDisplay> createState() => _GradeDisplayState();
}

class _GradeDisplayState extends State<GradeDisplay> {
  @override
  Widget build(BuildContext context) {
    final isGradeHidden = widget.grade == 0;
    final size = widget.size;
    final int alpha = ((.25 + widget.weight * .75) * 255).toInt();

    final color =
        widget.grade >= 4
            ? CupertinoColors.activeGreen
            : widget.grade > 3.75
            ? CupertinoColors.activeOrange
            : CupertinoColors.systemRed;

    List<List<dynamic>>? badge;
    if (widget.isIncoming) {
      badge = HugeIcons.strokeRoundedClock01;
    } else if (widget.isPlanned) {
      badge = HugeIcons.strokeRoundedCalendar04;
    } else if (widget.isGroup) {
      badge = HugeIcons.strokeRoundedSelect01;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.grade),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, animatedGrade, _) {
        return SizedBox(
          width: size,
          height: size + 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Content \\

              // Dotted line / Circle
              SizedBox(
                width: size,
                height: size,
                child:
                    isGradeHidden
                        ? DottedBorder(
                          options: RoundedRectDottedBorderOptions(
                            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                            strokeWidth: 2,
                            dashPattern: [4, 5],
                            radius: Radius.circular(200),
                            strokeCap: StrokeCap.round,
                            borderPadding: EdgeInsets.all(2),
                          ),
                          child: SizedBox.square(dimension: 200),
                        )
                        : Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(value: animatedGrade / 6, strokeWidth: 3, strokeCap: StrokeCap.round, color: color.withAlpha(alpha)),

                            Transform.flip(
                              flipX: true,
                              child: Transform.rotate(
                                angle: 3.14 * .1,
                                child: CircularProgressIndicator(
                                  value: 1 - animatedGrade / 6 - 0.1,
                                  strokeWidth: 4,
                                  strokeCap: StrokeCap.round,
                                  color: adaptiveColor(CupertinoColors.black, CupertinoColors.white).withAlpha(30),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),

              // Grade
              if (!isGradeHidden)
                Text(
                  animatedGrade.toStringAsFixed(widget.roundGrade ? 1 : 2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''),

                  style: TextStyle(fontSize: size / 2.75, fontWeight: FontWeight.w600, color: CupertinoColors.label.resolveFrom(context)),
                ),

              // Weight
              if (widget.weight != 1)
                Positioned(
                  bottom: 0,
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(color: CupertinoColors.systemBackground.resolveFrom(context).withAlpha(200), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        getFractionString(widget.weight) ?? "${(widget.weight * 100).round()}%",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: CupertinoColors.label.resolveFrom(context)),
                      ),
                    ),
                  ),
                ),

              // Badge
              if (badge != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: CupertinoColors.systemBackground.resolveFrom(context)),
                    padding: const EdgeInsets.only(left: 4, top: 5),
                    child: Opacity(
                      opacity: widget.isGroup ? 1 : .3,
                      child: HugeIcon(icon: badge, size: 16, strokeWidth: 2, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
