import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class GradesBySubjectPage extends StatefulWidget {
  const GradesBySubjectPage({super.key});

  @override
  State<GradesBySubjectPage> createState() => _GradesBySubjectPageState();
}

class _GradesBySubjectPageState extends State<GradesBySubjectPage> {
  final database = DatabaseService();

  String? activeFilter;

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      topBar: TopBar.sliverWithChevron(
        context,
        title: "Notes par branche",
        trailing: Button.icon(
          context,
          icon: HugeIcons.strokeRoundedSettings05,
          onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (context) => SubjectsListPage())),
        ),
      ),
      field: Field.search(
        placeholder: "Chercher une branche...",
        onChanged: (content) => setState(() => activeFilter = content.isEmpty ? null : content.toLowerCase()),
      ),
      body: StreamBuilder(
        stream: database.grades.watchAll(),
        builder: (context, _) {
          // All the grades
          final allGrades = database.grades.getAll();
          final allSubjects = database.subjects
              .getAll()
              .sorted((a, b) => a.name.compareTo(b.name))
              .where((s) => activeFilter != null ? s.name.toLowerCase().contains(activeFilter!) : true);
          final allCompositeSubjects = database.compositeSubjects
              .getAll()
              .sorted((a, b) => a.name.compareTo(b.name))
              .where((s) => activeFilter != null ? s.name.toLowerCase().contains(activeFilter!) : true);

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
            padding: .only(top: 16),
            child: Column(
              spacing: 10,
              crossAxisAlignment: .stretch,
              children: [
                if (allCompositeSubjects.isNotEmpty || allActiveSubjects.isNotEmpty)
                  GridView.builder(
                    padding: .only(bottom: 16),
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
                  Text("Branches bloquées", style: AppStyles.header(context)),
                  GridView.builder(
                    padding: .only(bottom: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 100,
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
                  Text("Branches sans notes", style: AppStyles.header(context)),
                  GridView.builder(
                    padding: .only(bottom: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 90,
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

                BottomSpacing(),
              ],
            ),
          );
        },
      ),
    );
  }
}
