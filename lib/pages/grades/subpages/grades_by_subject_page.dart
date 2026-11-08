import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/utility/widgets/basics/section_header.dart';
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
        title: "Branches",
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
            // A locked subject is listed with the locked ones only, even with grades left this year
            if (grade.subject.value != null &&
                !grade.subject.value!.isLocked &&
                !allActiveSubjects.any((subject) => grade.subject.value?.code == subject.code)) {
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

          Widget group(String? title, List<Widget> rows) => Padding(
            padding: const .only(bottom: AppSpacing.section),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                if (title != null) SectionHeader(title),
                CardGroup(separatorInset: SubjectCard.separatorInset, children: rows),
              ],
            ),
          );

          return ListView(
            padding: const .only(top: AppSpacing.m),
            children: [
              if (allCompositeSubjects.isNotEmpty || allActiveSubjects.isNotEmpty)
                group(null, [
                  for (final subject in allActiveSubjects) SubjectCard(subject: subject, wasPushedFromGradesBySubjectPage: true),
                  for (final composite in allCompositeSubjects) SubjectCard(compositeSubject: composite, wasPushedFromGradesBySubjectPage: true),
                ]),
              if (allLockedSubjects.isNotEmpty)
                group("Bloquées", [for (final subject in allLockedSubjects) SubjectCard(subject: subject, wasPushedFromGradesBySubjectPage: true)]),
              if (allInactiveSubjects.isNotEmpty)
                group("Sans notes", [for (final subject in allInactiveSubjects) SubjectCard(subject: subject, wasPushedFromGradesBySubjectPage: true)]),
              const BottomSpacing(),
            ],
          );
        },
      ),
    );
  }
}
