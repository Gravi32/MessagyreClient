import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

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

    return CupertinoPressable(
      padding: .only(left: 1.5),
      onTap: onTap,
      child: Row(
        children: [
          // Grade Display
          GradeDisplay(
            grade: isGradeUnknown ? 0 : gradeData.grade,
            weight: isGradeUnknown ? 1 : gradeData.weight,
            isIncoming: isIncoming,
            isPlanned: isPlanned,
          ),
          SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              mainAxisAlignment: .center,
              crossAxisAlignment: .stretch,
              spacing: 4,
              children: [
                // Title
                Padding(
                  padding: .only(right: 20),
                  child: CustomText(
                    gradeData.title,
                    style: TextStyle(fontWeight: .w500, fontSize: 18, color: AppColors.text.adaptTo(context)),
                    overflow: .ellipsis,
                  ),
                ),

                // Description
                if (!isGradeUnknown && gradeData.details != null && gradeData.details!.isNotEmpty)
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 20),
                    child: CustomText(
                      gradeData.details!,
                      style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 17),
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                  ),

                // Subject / Date
                showSubject
                    ? Row(
                      spacing: 6,
                      children: [
                        if (gradeData.subject.value != null) SubjectBadge(subject: gradeData.subject.value!, size: 20),
                        Expanded(
                          child: Text(
                            "${gradeData.subject.value?.name ?? "Pas de branche"} • ${formatDate(gradeData.date)}",
                            style: TextStyle(fontSize: 18, fontWeight: .w400, color: AppColors.secondaryText.adaptTo(context)),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      isGradeUnknown
                          ? "${isIncoming ? "Passé" : "Prévu pour"} ${formatDate(gradeData.date, includeArticle: true)} ${isIncoming && daysDistance > 1 ? "(il y a $daysDistance jours)" : ""}"
                          : "Reçu ${formatDate(gradeData.date, includeArticle: true)}",
                      maxLines: 2,
                      overflow: .fade,
                      softWrap: true,
                      style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 15),
                    ),
              ],
            ),
          ),

          // Trailing
          if (!showSubject)
            CustomIcon(
              icon:
                  isGradeUnknown ? (isPlanned ? HugeIcons.strokeRoundedCalendarCheckOut01 : HugeIcons.strokeRoundedAdd01) : HugeIcons.strokeRoundedPencilEdit02,
              size: 20,
              color: AppColors.tertiaryText.adaptTo(context),
            ),
          CupertinoListTileChevron(),
        ],
      ),
    );
  }
}
