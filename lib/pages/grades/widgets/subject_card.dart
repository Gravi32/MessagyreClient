import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/subject_page.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_composite_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/modal_popup.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/chart.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectCard extends StatelessWidget {
  final Subject? subject;
  final CompositeSubject? compositeSubject;
  final bool wasPushedFromGradesBySubjectPage;

  const SubjectCard({super.key, this.subject, this.compositeSubject, this.wasPushedFromGradesBySubjectPage = false});

  void pushPage(BuildContext context, Subject pageSubject, {BuildContext? dialogContext}) {
    if (dialogContext != null && dialogContext.mounted) Navigator.pop(dialogContext);
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (builder) => GradesSubjectPage(subject: pageSubject, wasPushedFromGradesBySubjectPage: wasPushedFromGradesBySubjectPage),
      ),
    );
  }

  void onTap(BuildContext context, bool isLocked, bool compositeMode) {
    // If the subject is locked
    if (isLocked) {
      showCupertinoDialog(
        context: context,
        builder: (_) => Dialog(
          title: "Branche bloquée",
          content:
              "Cette branche est *bloquée à ${subject!.lockedGrade?.removeTrailingZero() ?? 4}*,\npour la débloquer ou changer la note: *Réglages > Branches*.",
        ),
      );
      return;
    }

    // If it's a normal subject
    if (subject != null) {
      pushPage(context, subject!);
      return;
    }

    // If it's a composite subject
    if (compositeMode) {
      final subSubjects = compositeSubject?.subjects ?? [];
      if (subSubjects.length < 2) return;

      showCupertinoModalPopup(
        context: context,
        builder: (dialogContext) => ModalPopup(
          topBar: TopBar.form(
            context,
            title: "Branche composée",
            trailing: Button.icon(
              context,
              icon: HugeIcons.strokeRoundedMoreHorizontal,
              onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => NewCompositeSubjectPage(toEdit: compositeSubject))),
            ),
          ),
          decorations: [Text("Touchez une partie pour voir ses notes", style: AppStyles.footer(context))],
          child: Column(
            mainAxisSize: .min,
            spacing: 16,
            children: [
              CustomText("\"*${compositeSubject?.name}*\" est une *branche composée*, elle n'a pas de notes propres.", style: AppStyles.primaryText(context)),
              CardGroup(
                separatorInset: SubjectCard.separatorInset,
                children: [for (final subSubject in subSubjects) SubjectCard(subject: subSubject)],
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Where the separators between two rows start: under the name
  static const double separatorInset = AppSpacing.l + 36 + AppSpacing.m;

  @override
  Widget build(BuildContext context) {
    final compositeSubjectMode = subject == null && compositeSubject != null;

    final database = DatabaseService();

    final subjectGrades = database.grades
        .getAll()
        .where((grade) => grade.subject.value?.code == subject?.code)
        .sorted((a, b) => a.date.compareTo(b.date))
        .toList();

    final isSubjectLocked = subject?.isLocked ?? false;

    final average =
        subject?.lockedGrade ??
        (compositeSubjectMode ? calculateCompositeSubjectAverage(compositeSubject!, round: true) : calculateAverage(subjectGrades, round: true));
    final hasAverage = (average ?? 0) != 0;
    final color = subject?.color ?? compositeSubject?.firstSubject.value?.color ?? AppColors.grey;

    final String subtitle = isSubjectLocked
        ? "Bloquée"
        : compositeSubjectMode
        ? "Branche composée · ${compositeSubject!.subjects.length} parties"
        : subjectGrades.isEmpty
        ? "Aucune note"
        : "${subjectGrades.length} note${subjectGrades.length > 1 ? "s" : ""}";

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .55,
      onPressed: () => onTap(context, isSubjectLocked, compositeSubjectMode),
      child: Padding(
        padding: const .fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.m, AppSpacing.m),
        child: Row(
          spacing: AppSpacing.m,
          children: [
            if (subject != null) SubjectBadge(subject: subject!, size: 36),
            if (compositeSubject != null && subject == null) SizedBox.square(dimension: 36, child: CompositeSubjectBadge(compositeSubject: compositeSubject!)),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 2,
                children: [
                  Text(subject?.name ?? compositeSubject?.name ?? "-", style: AppStyles.strongText(context), overflow: .ellipsis, maxLines: 1),
                  Row(
                    spacing: 4,
                    children: [
                      if (isSubjectLocked) AppIcon(icon: AppIcons.locked, size: 13, color: AppColors.tertiaryText.adaptTo(context)),
                      Flexible(
                        child: Text(subtitle, maxLines: 1, overflow: .ellipsis, style: AppStyles.subheadline(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // The grades' curve, in the subject's color
            if (!isSubjectLocked && subjectGrades.length >= 2)
              SizedBox(
                width: 52,
                height: 26,
                child: Chart(
                  color: color,
                  showLines: false,
                  showDots: false,
                  showArea: false,
                  spots: subjectGrades.mapIndexed((index, grade) => FlSpot(index / subjectGrades.length, grade.grade)).toList(),
                ),
              ),

            SizedBox(
              width: 44,
              child: Text(
                hasAverage ? average!.removeTrailingZero() : "–",
                textAlign: .right,
                style: AppStyles.secondaryHeader(context).copyWith(
                  fontWeight: .w700,
                  color: hasAverage ? getGradeColor(average!, context, defaultColor: AppColors.text.adaptTo(context)) : AppColors.quaternaryText.adaptTo(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
          ],
        ),
      ),
    );
  }
}
