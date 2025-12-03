import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';

class GradeBar extends StatelessWidget {
  final Grade gradeData;
  final bool isGradeUnknown;
  final bool isIncoming;
  final bool isPlanned;
  final Function() onTap;

  const GradeBar({super.key, required this.gradeData, required this.onTap, this.isGradeUnknown = false, this.isIncoming = false, this.isPlanned = false});

  @override
  Widget build(BuildContext context) {
    final daysDistance = DateTime.now().difference(gradeData.date).inDays;

    return Column(
      children: [
        CupertinoPressable(
          padding: EdgeInsets.zero,
          onTap: isGradeUnknown ? null : onTap,
          child: Row(
            children: [
              GradeDisplay(
                grade: isGradeUnknown ? 0 : gradeData.grade,
                weight: isGradeUnknown ? 1 : gradeData.weight,
                isIncoming: isIncoming,
                isPlanned: isPlanned,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        CustomText(
                          gradeData.title,
                          style: TextStyle(
                            fontWeight: isGradeUnknown ? FontWeight.w400 : FontWeight.w500,
                            fontSize: isGradeUnknown ? 16 : 18,
                            color: isGradeUnknown ? CupertinoColors.secondaryLabel.resolveFrom(context) : CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        if (!isGradeUnknown && gradeData.details != null && gradeData.details!.isNotEmpty)
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(vertical: 4),
                            child: Row(
                              spacing: 6,
                              children: [
                                Opacity(
                                  opacity: .5,
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedTextAlignLeft,
                                    size: 16,
                                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                  ),
                                ),
                                CustomText(
                                  gradeData.details!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: CupertinoColors.separator.resolveFrom(context), fontSize: 15),
                                ),
                              ],
                            ),
                          ),

                        Text(
                          isGradeUnknown
                              ? "${isIncoming ? "Passé" : "Prévu pour"} ${formatDate(gradeData.date, includeArticle: true)} ${isIncoming && daysDistance > 1 ? "(il y a $daysDistance jours)" : ""}"
                              : "Reçu ${formatDate(gradeData.date, includeArticle: true)}",
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          softWrap: true,
                          style: TextStyle(color: CupertinoColors.separator.resolveFrom(context), fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: .75,
                child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.secondarySystemBackground.resolveFrom(context)),
              ),
            ],
          ),
        ),
        Divider(indent: 60, color: CupertinoColors.separator.resolveFrom(context).withAlpha(30)),
      ],
    );
  }
}
