import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/utility.dart';

class GradeDisplay extends StatefulWidget {
  final double grade;
  final double size;
  final double weight;
  final double strokeWidth;
  final String? textBelow;
  final bool isIncoming;
  final bool isPlanned;
  final bool isGroup;
  final bool roundGrade;

  const GradeDisplay({
    super.key,
    required this.grade,
    this.size = 48,
    this.strokeWidth = 3,
    this.weight = 1.0,
    this.textBelow,
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
            ? CupertinoTheme.of(context).primaryColor
            : widget.grade > 3.75
            ? AppColors.orange
            : AppColors.red;

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
        final gradeAlpha = animatedGrade / 6;

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
                            color: AppColors.secondaryBackground.adaptTo(context),
                            strokeWidth: widget.strokeWidth,
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
                            CircularProgressIndicator(
                              value: gradeAlpha,
                              strokeWidth: widget.strokeWidth,
                              strokeCap: StrokeCap.round,
                              color: color.withAlpha(alpha),
                            ),

                            Transform.flip(
                              flipX: true,
                              child: Transform.rotate(
                                angle: pi / .25 / size,
                                child: CircularProgressIndicator(
                                  value: 1 - gradeAlpha - 1 / (.25 * size),
                                  strokeWidth: widget.strokeWidth,
                                  strokeCap: StrokeCap.round,
                                  color: adaptiveColor(AppColors.black, AppColors.white).withAlpha(30),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),

              // Grade
              if (!isGradeHidden)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Text(
                      animatedGrade.toStringAsFixed(widget.roundGrade ? 1 : 2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''),
                      style: TextStyle(fontSize: size / 2.75, fontWeight: FontWeight.w600, height: 1.0, color: AppColors.text.adaptTo(context)),
                    ),

                    if (widget.textBelow != null)
                      Text(
                        widget.textBelow!,
                        style: TextStyle(fontSize: size / 6, fontWeight: FontWeight.w400, height: 1.0, color: AppColors.secondaryText.adaptTo(context)),
                      ),
                  ],
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
                        boxShadow: [BoxShadow(color: AppColors.background.adaptTo(context).withAlpha(200), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        getFractionString(widget.weight) ?? "${(widget.weight * 100).round()}%",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: AppColors.text.adaptTo(context)),
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.background.adaptTo(context)),
                    padding: const EdgeInsets.only(left: 4, top: 5),
                    child: HugeIcon(icon: badge, size: 16, strokeWidth: 2, color: (widget.isGroup ? AppColors.text : AppColors.tertiaryText).adaptTo(context)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
