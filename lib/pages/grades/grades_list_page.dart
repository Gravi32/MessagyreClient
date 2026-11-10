import 'package:messagyre_client/utility/widgets/appear.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_by_subject_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/grades/subpages/recent_grades_page.dart';
import 'package:messagyre_client/pages/grades/widgets/grades_top_card.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/utility/widgets/basics/section_header.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class GradesListPage extends StatefulWidget {
  const GradesListPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> with AppearOnOpen {
  final database = DatabaseService();
  final globals = GlobalsService();

  final lockNotifier = ValueNotifier(0);

  void showNewGradePopup({Grade? toEdit, Assignment? toReference}) async {
    await showCupertinoSheet(
      enableDrag: false,
      context: context,
      builder: (context) => NewGradePage(toEdit: toEdit, toReference: toReference),
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    database.subjects.watchAll().listen((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      pageIndex: 0,
      topBar: TopBar.sliver(
        title: "Notes",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedFaceId, onTap: () => lockNotifier.value++),
      ),
      lockNotifier: lockNotifier,
      requireFaceId: globals.persistent.getBool("GradesPageRequiresFaceId") ?? false,
      onFloatingButtonTap: showNewGradePopup,
      body: StreamBuilder(
        stream: database.grades.watchAll(),
        builder: (context, _) {
          final allGrades = database.grades.getAll().sortedBy((grade) => grade.date).reversed.toList();

          // The subjects that have something to show: grades, or a locked average
          final gradedCodes = allGrades.map((grade) => grade.subject.value?.code).toSet();
          bool hasSomething(Subject subject) => subject.isLocked || gradedCodes.contains(subject.code);
          final subjects = database.subjects.getAll().where(hasSomething).sorted((a, b) => a.name.compareTo(b.name));
          final compositeSubjects = database.compositeSubjects
              .getAll()
              .where((composite) => composite.subjects.any(hasSomething))
              .sorted((a, b) => a.name.compareTo(b.name));

          return ListView(
            padding: .zero,
            children: [
              const SizedBox(height: AppSpacing.s),
              Appear(enabled: isOpening, child: const GradesTopCard()),

              if (subjects.isNotEmpty || compositeSubjects.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                SectionHeader("Branches", onAction: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const GradesBySubjectPage()))),
                Appear(
                  index: 1,
                  enabled: isOpening,
                  child: CardGroup(
                    separatorInset: SubjectCard.separatorInset,
                    children: [
                      for (final subject in subjects) SubjectCard(subject: subject),
                      for (final composite in compositeSubjects) SubjectCard(compositeSubject: composite),
                    ],
                  ),
                ),
              ],

              if (allGrades.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                SectionHeader("Récentes", onAction: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const RecentGradesPage()))),
                Appear(
                  index: 2,
                  enabled: isOpening,
                  child: CardGroup(
                    separatorInset: GradeBar.separatorInset,
                    children: [
                      for (final grade in allGrades.take(4))
                        GradeBar(
                          gradeData: grade,
                          showSubject: true,
                          onTap: () => showNewGradePopup(toEdit: grade),
                        ),
                    ],
                  ),
                ),
              ],

              const BottomSpacing(includeBottomBar: true),
            ],
          );
        },
      ),
    );
  }
}
