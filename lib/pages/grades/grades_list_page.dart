import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_by_subject_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/grades/subpages/recent_grades_page.dart';
import 'package:messagyre_client/pages/grades/widgets/grades_top_card.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class GradesListPage extends StatefulWidget {
  const GradesListPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> {
  static const double subjectTileMaxHeight = 106;

  final database = DatabaseService();

  Widget buildSubjectsGrid(List<Subject> subjects, List<CompositeSubject> compositeSubjects) {
    const double maxHeight = 250;

    final rows = (subjects.length / 2).ceil();
    final totalHeight = rows * subjectTileMaxHeight + (rows - 1) * 8; // mainAxisSpacing

    final bool shouldFade = totalHeight > maxHeight;

    Widget grid = GridView.builder(
      padding: .zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: subjectTileMaxHeight,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length + compositeSubjects.length,
      itemBuilder: (context, index) {
        final subject = subjects.elementAtOrNull(index);
        final compositeSubject = subject == null ? compositeSubjects.elementAt(index - subjects.length) : null;
        return SubjectCard(subject: subject, compositeSubject: compositeSubject);
      },
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHeight),
      child: shouldFade
          ? ShaderMask(
              shaderCallback: (Rect rect) {
                return const LinearGradient(
                  begin: .topCenter,
                  end: Alignment(0, 1.1),
                  colors: [AppColors.black, AppColors.black, AppColors.transparent],
                  stops: [0, 0.6, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: grid,
            )
          : grid,
    );
  }

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
      topBar: TopBar.sliver(title: "Notes"),
      onFloatingButtonTap: showNewGradePopup,
      body: StreamBuilder(
        stream: database.grades.watchAll(),
        builder: (context, _) {
          // All the grades
          final allGrades = database.grades.getAll().sortedBy((grade) => grade.date).reversed;

          // A list of all the subjects with at least 1 grade
          final List<Subject> allSubjects = database.subjects.getAll().sorted((a, b) => a.name.compareTo(b.name));
          final List<CompositeSubject> allCompositeSubjects = database.compositeSubjects.getAll().sorted((a, b) => a.name.compareTo(b.name));

          return SingleChildScrollView(
            child: Column(
              spacing: 10,
              crossAxisAlignment: .stretch,
              children: [
                GradesTopCard(),

                Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text("Par branche", style: AppStyles.header(context)),
                    Button.icon(
                      context,
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: AppColors.secondaryBackground.adaptTo(context),
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GradesBySubjectPage())),
                      size: 45,
                    ),
                  ],
                ),
                buildSubjectsGrid(allSubjects, allCompositeSubjects),

                if (allGrades.isNotEmpty) ...[
                  SizedBox(),
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Text("Récentes", style: AppStyles.header(context)),
                      Button.icon(
                        context,
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: AppColors.secondaryBackground.adaptTo(context),
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => RecentGradesPage())),
                        size: 45,
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: ShaderMask(
                      shaderCallback: (Rect rect) {
                        return const LinearGradient(
                          begin: .topCenter,
                          end: .bottomCenter,
                          colors: [AppColors.black, AppColors.black, AppColors.transparent],
                          stops: [0.0, 0.6, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: .dstIn,
                      child: ListView.separated(
                        padding: .zero,
                        itemCount: min(4, allGrades.length),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final grade = allGrades.elementAtOrNull(index);
                          return grade == null
                              ? const SizedBox.shrink()
                              : GradeBar(
                                  gradeData: grade,
                                  showSubject: true,
                                  onTap: () => showNewGradePopup(toEdit: grade),
                                );
                        },
                        separatorBuilder: (_, _) => SizedBox(height: 8),
                      ),
                    ),
                  ),
                ],

                BottomSpacing(includeBottomBar: true),
              ],
            ),
          );
        },
      ),
    );
  }
}
