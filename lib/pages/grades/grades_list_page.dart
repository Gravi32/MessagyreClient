import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_by_subject_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/grades/subpages/recent_grades_page.dart';
import 'package:messagyre_client/pages/grades/widgets/grades_top_card.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

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
      child:
          shouldFade
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
    await showCupertinoModalBottomSheet<Grade?>(
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
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [CupertinoSliverNavigationBar(largeTitle: Text("Notes"))];
            },
            body: SafeArea(
              top: false,
              child: Padding(
                padding: .symmetric(horizontal: 12),
                child: StreamBuilder(
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

                          SizedBox(),
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Text(
                                "Par branche",
                                style: TextStyle(fontSize: 25, letterSpacing: .1, fontWeight: .w600, color: AppColors.text.adaptTo(context)),
                              ),

                              CupertinoButton(
                                padding: .zero,
                                onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GradesBySubjectPage())),
                                child: Row(
                                  crossAxisAlignment: .end,
                                  children: [
                                    Text(
                                      "Tout voir",
                                      style: TextStyle(fontSize: 17, fontWeight: .w500, color: AppColors.tertiaryText.adaptTo(context)),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          buildSubjectsGrid(allSubjects, allCompositeSubjects),

                          if (allGrades.isNotEmpty) ...[
                            SizedBox(),
                            Row(
                              mainAxisAlignment: .spaceBetween,
                              children: [
                                Text(
                                  "Récentes",
                                  style: TextStyle(fontSize: 25, letterSpacing: .1, fontWeight: .w600, color: AppColors.text.adaptTo(context)),
                                ),

                                CupertinoButton(
                                  padding: .zero,
                                  onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => RecentGradesPage())),
                                  child: Row(
                                    crossAxisAlignment: .end,
                                    children: [
                                      Text(
                                        "Tout voir",
                                        style: TextStyle(fontSize: 17, fontWeight: .w500, color: AppColors.tertiaryText.adaptTo(context)),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
                                    ],
                                  ),
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
                                blendMode: BlendMode.dstIn,
                                child: ListView.separated(
                                  padding: .zero,
                                  itemCount: min(10, allGrades.length),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final grade = allGrades.elementAtOrNull(index);
                                    return grade == null
                                        ? const SizedBox.shrink()
                                        : GradeBar(gradeData: grade, showSubject: true, onTap: () => showNewGradePopup(toEdit: grade));
                                  },
                                  separatorBuilder: (_, _) => SizedBox(height: 8),
                                ),
                              ),
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
          Positioned(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
            right: 20,
            child: ValueListenableBuilder(
              valueListenable: MainPage.pageIndex,
              builder:
                  (context, pageIndex, _) => AnimatedOpacity(
                    opacity: pageIndex == 0 ? 1 : 0,
                    duration: Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: showNewGradePopup,
                      child: Container(
                        padding: .all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground.adaptTo(context),
                          borderRadius: .circular(20),
                          boxShadow: [BoxShadow(color: AppColors.black.withAlpha(30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))],
                        ),
                        child: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
