import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/services/database_service.dart';

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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: StreamBuilder(
              stream: database.grades.watchAll(),
              builder: (context, _) {
                // All the grades
                final allGrades = database.grades.getAll();
                final allSubjects = database.subjects.getAll().sorted((subjectA, subjectB) => subjectA.name.compareTo(subjectB.name));

                // A list of all the subjects with at least 1 grade
                final List<Subject> allActiveSubjects = [];
                for (final grade in allGrades) {
                  if (grade.subject.value != null && !allActiveSubjects.any((subject) => grade.subject.value?.code == subject.code)) {
                    allActiveSubjects.add(grade.subject.value!);
                  }
                }
                allActiveSubjects.sort((subjectA, subjectB) => subjectA.name.compareTo(subjectB.name));

                final List<Subject> allInactiveSubjects = [];
                for (final subject in allSubjects) {
                  if (!allActiveSubjects.any((activeSubject) => activeSubject.code == subject.code)) allInactiveSubjects.add(subject);
                }
                allInactiveSubjects.sort((subjectA, subjectB) => subjectA.name.compareTo(subjectB.name));


                return SingleChildScrollView(
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 110,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allActiveSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = allActiveSubjects[index];
                          return SubjectCard(subject: subject);
                        },
                      ),

                      if (allInactiveSubjects.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text("Branches sans notes", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: 120,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allInactiveSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = allInactiveSubjects[index];
                            return SubjectCard(subject: subject, isSubjectActive: false);
                          },
                        ),
                      ],
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
