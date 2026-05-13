import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/extensions/widget_extensions.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

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
      final firstSubject = compositeSubject?.firstSubject.value;
      final secondSubject = compositeSubject?.secondSubject.value;

      if (firstSubject == null || secondSubject == null) return;

      showCupertinoModalPopup(
        context: context,
        builder: (dialogContext) => CupertinoActionSheet(
          actions: [
            Padding(
              padding: .symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: 10,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      CustomIcon(icon: HugeIcons.strokeRoundedNodeAdd, size: 24, color: AppColors.text.adaptTo(context)),
                      Text("Branche composée", style: TextStyle(fontSize: 26, fontWeight: .w600)),
                      Spacer(),
                      CustomIcon(icon: HugeIcons.strokeRoundedHelpCircle, color: AppColors.secondaryText.adaptTo(context), size: 24, strokeWidth: 1.5),
                    ],
                  ),

                  CustomText("\"*${compositeSubject?.name}*\" est une *branche composée*, elle n'a pas de notes propres.", style: TextStyle(fontSize: 16)),
                  Text("Appuyez pour voir les notes de :", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () => pushPage(context, firstSubject, dialogContext: dialogContext),
              child: Row(
                spacing: 8,
                children: [
                  Padding(
                    padding: .symmetric(horizontal: 8),
                    child: SubjectBadge(subject: firstSubject),
                  ),
                  Text(firstSubject.name, style: TextStyle(fontSize: 20, color: AppColors.text.adaptTo(context))),
                  Spacer(),
                  CupertinoListTileChevron(),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () => pushPage(context, secondSubject, dialogContext: dialogContext),
              child: Row(
                spacing: 8,
                children: [
                  Padding(
                    padding: .symmetric(horizontal: 8),
                    child: SubjectBadge(subject: secondSubject),
                  ),
                  Text(secondSubject.name, style: TextStyle(fontSize: 20, color: AppColors.text.adaptTo(context))),
                  Spacer(),
                  CupertinoListTileChevron(),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compositeSubjectMode = subject == null && compositeSubject != null;

    final database = DatabaseService();

    final subjectGrades = database.grades.getAll().where((grade) => grade.subject.value?.code == subject?.code).toList();

    final isSubjectLocked = subject?.isLocked ?? false;
    final isSubjectEmpty = subjectGrades.isEmpty;

    final average =
        subject?.lockedGrade ??
        (compositeSubjectMode ? calculateCompositeSubjectAverage(compositeSubject!, round: true) : calculateAverage(subjectGrades, round: true));

    return Button(
      color: AppColors.secondaryBackground.adaptTo(context),
      transparent: isSubjectLocked,
      padding: .all(10).copyWith(bottom: 8),
      onTap: () => onTap(context, isSubjectLocked, compositeSubjectMode),
      rawChild: Column(
        mainAxisSize: .max,
        mainAxisAlignment: .spaceBetween,
        crossAxisAlignment: .stretch,
        spacing: 6,
        children: [
          // Badge + Average
          SizedBox(
            height: 32,
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                // Subject badge
                if (subject != null) SubjectBadge(subject: subject!).withAspectRatio(1),
                if (compositeSubject != null) CompositeSubjectBadge(compositeSubject: compositeSubject!).withAspectRatio(1),

                // Average label
                if ((average ?? 0) != 0)
                  RoundContainer(
                    height: 32,
                    color: AppColors.background.adaptTo(context),
                    padding: .symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        average!.removeTrailingZero(),
                        style: AppStyles.header(context).copyWith(color: getGradeColor(average, defaultColor: AppColors.text.adaptTo(context))),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Title
          Expanded(
            child: Align(
              alignment: .bottomLeft,
              child: Row(
                crossAxisAlignment: .baseline,
                textBaseline: .alphabetic,
                children: [
                  Expanded(
                    child: Text(subject?.name ?? compositeSubject?.name ?? "-", style: AppStyles.secondaryHeader(context), overflow: .ellipsis, maxLines: 1),
                  ),

                  if (isSubjectLocked) Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.text.adaptTo(context)),
                  if (compositeSubjectMode) CustomIcon(icon: HugeIcons.strokeRoundedNodeAdd, size: 14, color: AppColors.text.adaptTo(context)),
                  if (isSubjectEmpty && !isSubjectLocked && compositeSubject == null)
                    Expanded(
                      child: Text("+ Ajouter une note", softWrap: false, style: AppStyles.tertiaryText(context), overflow: .fade),
                    ),
                ],
              ),
            ),
          ),

          // Progress bar
          if (!isSubjectLocked && (average ?? 0) != 0)
            ProgressBar(progress: average! / 6, color: subject?.color ?? compositeSubject?.firstSubject.value?.color),
        ],
      ),
    );
  }
}
