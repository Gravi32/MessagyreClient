import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class GradeBar extends StatelessWidget {
  final Grade gradeData;
  final bool showSubject;
  final bool isGradeUnknown;
  final bool isIncoming;
  final bool isPlanned;
  final Function()? onTap;

  const GradeBar({
    super.key,
    required this.gradeData,
    required this.onTap,
    this.showSubject = false,
    this.isGradeUnknown = false,
    this.isIncoming = false,
    this.isPlanned = false,
  });

  @override
  Widget build(BuildContext context) {
    final daysDistance = DateTime.now().difference(gradeData.date).inDays;

    return Column(
      children: [
        CupertinoPressable(
          padding: EdgeInsets.only(left: 1.5),
          onTap: onTap,
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
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 20),
                            child: CustomText(
                              gradeData.title,
                              style: TextStyle(
                                fontWeight: isGradeUnknown ? FontWeight.w400 : FontWeight.w500,
                                fontSize: isGradeUnknown ? 16 : 18,
                                color: isGradeUnknown ? AppColors.tertiaryText.adaptTo(context) : AppColors.text.adaptTo(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isGradeUnknown && gradeData.details != null && gradeData.details!.isNotEmpty)
                            Padding(
                              padding: EdgeInsetsGeometry.only(top: 2, right: 20),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: HugeIcon(icon: HugeIcons.strokeRoundedTextAlignLeft, size: 14, color: AppColors.tertiaryText.adaptTo(context)),
                                      ),
                                    ),
                                    ...CustomText.parseSpans(
                                      gradeData.details!,
                                      style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 17),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          showSubject
                              ? Row(
                                spacing: 6,
                                children: [
                                  if (gradeData.subject.value != null) SubjectBadge(subject: gradeData.subject.value!, size: 20),
                                  Text(
                                    "${gradeData.subject.value?.name ?? "Pas de branche"} • ${formatDate(gradeData.date)}",
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.secondaryText.adaptTo(context)),
                                  ),
                                ],
                              )
                              : Text(
                                isGradeUnknown
                                    ? "${isIncoming ? "Passé" : "Prévu pour"} ${formatDate(gradeData.date, includeArticle: true)} ${isIncoming && daysDistance > 1 ? "(il y a $daysDistance jours)" : ""}"
                                    : "Reçu ${formatDate(gradeData.date, includeArticle: true)}",
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                                softWrap: true,
                                style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 15),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!showSubject)
                HugeIcon(
                  icon:
                      isGradeUnknown
                          ? (isPlanned ? HugeIcons.strokeRoundedCalendarCheckOut01 : HugeIcons.strokeRoundedAdd01)
                          : HugeIcons.strokeRoundedPencilEdit02,
                  color: AppColors.tertiaryText.adaptTo(context),
                ),
            ],
          ),
        ),
        //Divider(indent: 60, height: 10, color: AppColors.separator.adaptTo(context).withAlpha(30)),
      ],
    );
  }
}
