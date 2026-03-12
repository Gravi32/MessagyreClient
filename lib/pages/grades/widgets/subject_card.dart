import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;

  const SubjectCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final database = DatabaseService();

    final isSubjectEmpty = database.grades.getAll().where((grade) => grade.subject.value?.code == subject.code).isEmpty;

    final grades = database.grades.getAll().where((grade) => grade.subject.value?.code == subject.code).toList();
    final average = calculateAverage(grades, round: true);

    return Container(
      decoration: BoxDecoration(
        color: subject.isLocked ? AppColors.transparent : AppColors.secondaryBackground.adaptTo(context),
        border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(maxHeight: 150),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onPressed: () {
          subject.isLocked
              ? showCupertinoDialog(
                context: context,
                builder:
                    (context) => CupertinoAlertDialog(
                      title: Text("Branche bloquée"),
                      content: CustomText(
                        "Cette branche est *bloquée à ${subject.lockedGrade?.removeTrailingZero() ?? 4}*,\npour la débloquer ou changer la note: *Réglages > Branches*.",
                        textAlign: TextAlign.center,
                      ),
                      actions: [CupertinoDialogAction(child: Text("Fermer"), onPressed: () => Navigator.pop(context))],
                    ),
              )
              : Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => GradesSubjectPage(subject: subject)));
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
                SubjectBadge(subject: subject, size: 32),

                // Average label
                if (!isSubjectEmpty || subject.isLocked)
                  Text(
                    (subject.lockedGrade ?? average).removeTrailingZero(),
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
                    Text(subject.name, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: AppColors.text.adaptTo(context))),
                    if (subject.isLocked) Icon(CupertinoIcons.lock_fill, size: 18, color: AppColors.text.adaptTo(context)),
                  ],
                ),

                // Progress bar
                if (!isSubjectEmpty && !subject.isLocked) ProgressBar(progress: average / 6, color: subject.color),
              ],
            ),

            if (isSubjectEmpty && !subject.isLocked) Text("+ Ajouter une note", style: TextStyle(color: AppColors.tertiaryText.adaptTo(context))),
          ],
        ),
      ),
    );
  }
}
