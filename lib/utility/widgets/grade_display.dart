import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

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
    this.strokeWidth = 2,
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
    final double transparency = .25 + widget.weight * .75;

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
            alignment: .center,
            children: [
              // Content \\

              // Dotted line / Circle
              SizedBox.square(
                dimension: size,
                child: isGradeHidden
                    ? DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          color: AppColors.tertiaryText.adaptTo(context),
                          strokeWidth: widget.strokeWidth - .5,
                          dashPattern: [4, 5],
                          radius: .circular(200),
                          strokeCap: .round,
                          borderPadding: .all(2),
                        ),
                        child: SizedBox.square(dimension: 200),
                      )
                    : RoundContainer(
                        blurOnly: true,
                        padding: .zero,
                        child: Stack(
                          fit: .expand,
                          children: [
                            Transform.flip(
                              flipX: true,
                              child: Transform.rotate(
                                angle: 4 * pi,
                                child: CircularProgressIndicator(
                                  value: 1 - gradeAlpha,
                                  strokeWidth: widget.strokeWidth,
                                  strokeCap: .round,
                                  color: AppColors.secondaryBackground.adaptTo(context),
                                ),
                              ),
                            ),

                            CircularProgressIndicator(
                              value: gradeAlpha,
                              strokeWidth: widget.strokeWidth,
                              strokeCap: .round,
                              color: getGradeColor(widget.grade).withTransparency(transparency),
                            ),
                          ],
                        ),
                      ),
              ),

              // Grade
              if (!isGradeHidden)
                Column(
                  mainAxisSize: .min,
                  mainAxisAlignment: .center,
                  spacing: 2,
                  children: [
                    Text(
                      animatedGrade.toStringAsFixed(widget.roundGrade ? 1 : 2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), ''),
                      style: AppStyles.secondaryHeader(context).copyWith(fontSize: size / 2.75, height: 1),
                    ),

                    if (widget.textBelow != null)
                      Text(
                        widget.textBelow!,
                        textScaler: .noScaling,
                        style: AppStyles.secondaryText(context).copyWith(fontSize: size / 6, height: 1),
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
                        borderRadius: .circular(4),
                        boxShadow: [BoxShadow(color: AppColors.background.adaptTo(context).withAlpha(200), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      padding: const .symmetric(horizontal: 4),
                      child: Text(
                        getFractionString(widget.weight) ?? "${(widget.weight * 100).round()}%",
                        textAlign: .center,
                        style: TextStyle(fontSize: 14, fontWeight: .w300, color: AppColors.text.adaptTo(context)),
                      ),
                    ),
                  ),
                ),

              // Badge
              if (badge != null)
                Positioned(
                  bottom: 5,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(shape: .circle, color: AppColors.background.adaptTo(context)),
                    padding: const .only(left: 4, top: 5),
                    child: CustomIcon(
                      icon: badge,
                      size: 16,
                      strokeWidth: 2,
                      color: (widget.isGroup ? AppColors.text : AppColors.tertiaryText).adaptTo(context),
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
