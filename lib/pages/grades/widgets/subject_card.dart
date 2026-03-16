import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectCard extends StatelessWidget {
  final Subject? subject;
  final CompositeSubject? compositeSubject;

  const SubjectCard({super.key, this.subject, this.compositeSubject});

  void pushPage(BuildContext context, Subject pageSubject, {BuildContext? dialogContext}) {
    if (dialogContext != null && dialogContext.mounted) Navigator.pop(dialogContext);
    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => GradesSubjectPage(subject: pageSubject)));
  }

  @override
  Widget build(BuildContext context) {
    final compositeSubjectMode = subject == null && compositeSubject != null;

    final database = DatabaseService();

    final subjectGrades = database.grades.getAll().where((grade) => grade.subject.value?.code == subject?.code).toList();

    final isSubjectLocked = subject?.isLocked ?? false;
    final isSubjectEmpty = subjectGrades.isEmpty;

    final average = compositeSubjectMode ? calculateCompositeSubjectAverage(compositeSubject!, round: true) : calculateAverage(subjectGrades, round: true);

    return Container(
      decoration: BoxDecoration(
        color: isSubjectLocked ? AppColors.transparent : AppColors.secondaryBackground.adaptTo(context),
        border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(maxHeight: 150),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onPressed: () {
          // If the subject is locked
          if (isSubjectLocked) {
            showCupertinoDialog(
              context: context,
              builder:
                  (context) => CupertinoAlertDialog(
                    title: Text("Branche bloquée"),
                    content: CustomText(
                      "Cette branche est *bloquée à ${subject!.lockedGrade?.removeTrailingZero() ?? 4}*,\npour la débloquer ou changer la note: *Réglages > Branches*.",
                      textAlign: TextAlign.center,
                    ),
                    actions: [CupertinoDialogAction(child: Text("Fermer"), onPressed: () => Navigator.pop(context))],
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
          if (compositeSubjectMode) {
            final firstSubject = compositeSubject?.firstSubject.value;
            final secondSubject = compositeSubject?.secondSubject.value;

            if (firstSubject == null || secondSubject == null) return;

            showCupertinoModalPopup(
              context: context,
              builder:
                  (dialogContext) => CupertinoActionSheet(
                    actions: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 10,
                          children: [
                            Row(
                              spacing: 6,
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedNodeAdd, size: 24, color: AppColors.text.adaptTo(context)),
                                Text("Branche composée", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                                Spacer(),
                                HugeIcon(icon: HugeIcons.strokeRoundedHelpCircle, color: AppColors.secondaryText.adaptTo(context), size: 24, strokeWidth: 1.5),
                              ],
                            ),

                            CustomText(
                              "\"*${compositeSubject?.name}*\" est une *branche composée*, elle n'a pas de notes propres.",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text("Appuyez pour voir les notes de :", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                          ],
                        ),
                      ),
                      CupertinoActionSheetAction(
                        onPressed: () => pushPage(context, firstSubject, dialogContext: dialogContext),
                        child: Row(
                          spacing: 8,
                          children: [
                            Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SubjectBadge(subject: firstSubject)),
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
                            Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SubjectBadge(subject: secondSubject)),
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
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Subject badge
                if (subject != null) SubjectBadge(subject: subject!, size: 32),
                if (compositeSubject != null) CompositeSubjectBadge(compositeSubject: compositeSubject!, size: 32),

                // Average label
                if ((!isSubjectEmpty || isSubjectLocked) && average != null)
                  Text(
                    (subject?.lockedGrade ?? average).removeTrailingZero(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context)),
                  ),
              ],
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                // Subject title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: [
                    Text(
                      subject?.name ?? compositeSubject?.name ?? "-",
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: AppColors.text.adaptTo(context)),
                    ),
                    if (isSubjectLocked) Icon(CupertinoIcons.lock_fill, size: 18, color: AppColors.text.adaptTo(context)),
                    if (compositeSubject != null) HugeIcon(icon: HugeIcons.strokeRoundedNodeAdd, size: 18, color: AppColors.text.adaptTo(context)),
                  ],
                ),

                // Progress bar
                if (!isSubjectEmpty && !isSubjectLocked && average != null)
                  ProgressBar(progress: average / 6, color: subject?.color ?? compositeSubject?.firstSubject.value?.color),
              ],
            ),

            if (isSubjectEmpty && !isSubjectLocked && compositeSubject == null)
              Text("+ Ajouter une note", style: TextStyle(color: AppColors.tertiaryText.adaptTo(context))),
          ],
        ),
      ),
    );
  }
}
