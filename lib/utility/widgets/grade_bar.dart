import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

/// A grade as a row of a [CardGroup]: its ring, its title, then its subject or its date
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

  /// Where the separators between two rows start: under the title
  static const double separatorInset = AppSpacing.l + 46 + AppSpacing.m + 2;

  @override
  Widget build(BuildContext context) {
    final daysDistance = DateTime.now().difference(gradeData.date).inDays;
    final subject = gradeData.subject.value;
    final hasDetails = !isGradeUnknown && (gradeData.details ?? "").trim().isNotEmpty;

    final String subtitle = isGradeUnknown
        ? "${isIncoming ? "Passé" : "Prévu pour"} ${formatDate(gradeData.date, includeArticle: true)}${isIncoming && daysDistance > 1 ? " · il y a $daysDistance jours" : ""}"
        : showSubject
        ? "${subject?.name ?? "Pas de branche"} · ${formatDate(gradeData.date)}"
        : "Reçu ${formatDate(gradeData.date, includeArticle: true)}";

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .55,
      onPressed: onTap,
      child: Padding(
        padding: const .fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.m, AppSpacing.m),
        child: Row(
          spacing: AppSpacing.m + 2,
          children: [
            GradeDisplay(
              grade: isGradeUnknown ? 0 : gradeData.grade,
              size: 46,
              weight: isGradeUnknown ? 1 : gradeData.weight,
              isIncoming: isIncoming,
              isPlanned: isPlanned,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 3,
                children: [
                  CustomText(gradeData.title, style: AppStyles.strongText(context), maxLines: 1, overflow: .ellipsis),
                  Row(
                    spacing: 6,
                    children: [
                      if (showSubject && subject != null && !isGradeUnknown) SubjectBadge(subject: subject, size: 16),
                      Expanded(
                        child: Text(subtitle, maxLines: 1, overflow: .ellipsis, style: AppStyles.subheadline(context)),
                      ),
                    ],
                  ),
                  if (hasDetails) CustomText(gradeData.details!, style: AppStyles.footnote(context), maxLines: 2, overflow: .ellipsis),
                ],
              ),
            ),
            if (isGradeUnknown)
              HugeIcon(
                icon: isPlanned ? HugeIcons.strokeRoundedCalendarCheckOut01 : HugeIcons.strokeRoundedAdd01,
                size: 20,
                color: AppColors.tertiaryText.adaptTo(context),
              ),
            HugeIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
          ],
        ),
      ),
    );
  }
}
