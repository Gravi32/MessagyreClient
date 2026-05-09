import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class GradesBySubjectPage extends StatefulWidget {
  const GradesBySubjectPage({super.key});

  @override
  State<GradesBySubjectPage> createState() => _GradesBySubjectPageState();
}

class _GradesBySubjectPageState extends State<GradesBySubjectPage> {
  final database = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Notes par branche"), previousPageTitle: "Toutes les notes")];
        },
        body: SafeArea(
          top: false,
          child: Padding(
            padding: .symmetric(horizontal: 12, vertical: 10),
            child: StreamBuilder(
              stream: database.grades.watchAll(),
              builder: (context, _) {
                // All the grades
                final allGrades = database.grades.getAll();
                final allSubjects = database.subjects.getAll().sorted((a, b) => a.name.compareTo(b.name));
                final allCompositeSubjects = database.compositeSubjects.getAll().sorted((a, b) => a.name.compareTo(b.name));

                // A list of all the subjects with at least 1 grade
                final List<Subject> allActiveSubjects = [];
                for (final grade in allGrades) {
                  if (grade.subject.value != null && !allActiveSubjects.any((subject) => grade.subject.value?.code == subject.code)) {
                    allActiveSubjects.add(grade.subject.value!);
                  }
                }
                allActiveSubjects.sort((subjectA, subjectB) => subjectA.name.compareTo(subjectB.name));

                // A list of all the subjects without any grade
                final List<Subject> allInactiveSubjects = [];
                for (final subject in allSubjects) {
                  if (!allActiveSubjects.any((activeSubject) => activeSubject.code == subject.code) && !subject.isLocked) allInactiveSubjects.add(subject);
                }
                allInactiveSubjects.sort((subjectA, subjectB) => subjectA.name.compareTo(subjectB.name));

                // A list of all the locked subjects
                final List<Subject> allLockedSubjects = [];
                for (final subject in allSubjects) {
                  if (subject.isLocked) allLockedSubjects.add(subject);
                }
                allLockedSubjects.sort((subjectA, subjectB) => subjectA.name.compareTo(subjectB.name));

                return SingleChildScrollView(
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: .stretch,
                    children: [
                      GridView.builder(
                        padding: .zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 110,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allCompositeSubjects.length + allActiveSubjects.length,
                        itemBuilder: (context, index) {
                          final compositeSubject = allCompositeSubjects.elementAtOrNull(index);
                          final subject = compositeSubject == null ? allActiveSubjects.elementAt(index - allCompositeSubjects.length) : null;
                          return SubjectCard(subject: subject, compositeSubject: compositeSubject, wasPushedFromGradesBySubjectPage: true);
                        },
                      ),

                      if (allLockedSubjects.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text("Branches bloquées", style: TextStyle(fontSize: 25, fontWeight: .w600, color: AppColors.text.adaptTo(context))),
                        GridView.builder(
                          padding: .zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: 90,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allLockedSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = allLockedSubjects[index];
                            return SubjectCard(subject: subject, wasPushedFromGradesBySubjectPage: true);
                          },
                        ),
                      ],

                      if (allInactiveSubjects.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text("Branches sans notes", style: TextStyle(fontSize: 25, fontWeight: .w600, color: AppColors.text.adaptTo(context))),
                        GridView.builder(
                          padding: .zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: 110,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allInactiveSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = allInactiveSubjects[index];
                            return SubjectCard(subject: subject, wasPushedFromGradesBySubjectPage: true);
                          },
                        ),
                      ],

                      CupertinoListSection.insetGrouped(
                        backgroundColor: AppColors.transparent,
                        margin: .zero,
                        header: const SizedBox.shrink(),
                        children: [
                          CupertinoListTile.notched(
                            backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                            leading: CustomIcon(icon: HugeIcons.strokeRoundedBooks02),
                            title: Text("Ajouter ou modifier des branches"),
                            subtitle: Text("Réglages > Branches", style: TextStyle(color: AppColors.tertiaryText.adaptTo(context))),
                            trailing: CupertinoListTileChevron(),

                            onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => SubjectsListPage())),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
