import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_by_subject_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/grades/subpages/recent_grades_page.dart';
import 'package:messagyre_client/pages/grades/widgets/subject_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class GradesListPage extends StatefulWidget {
  const GradesListPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> {
  static const double subjectTileMaxHeight = 106;

  final database = DatabaseService();

  Widget buildSubjectsGrid(List<Subject> allSubjects) {
    const double maxHeight = 250;

    final rows = (allSubjects.length / 2).ceil();
    final totalHeight = rows * subjectTileMaxHeight + (rows - 1) * 8; // mainAxisSpacing

    final bool shouldFade = totalHeight > maxHeight;

    Widget grid = GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: subjectTileMaxHeight,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allSubjects.length,
      itemBuilder: (context, index) {
        final subject = allSubjects[index];
        return SubjectCard(subject: subject);
      },
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: maxHeight),
      child:
          shouldFade
              ? ShaderMask(
                shaderCallback: (Rect rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.black, AppColors.black, AppColors.transparent],
                    stops: [0.0, 0.6, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: grid,
              )
              : grid,
    );
  }

  Widget buildGeneralAverageBar() {
    final grades = database.grades.getAll();
    final average = calculateAverage(grades.toList());

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: PagedCard(
        height: 150,
        pages: [
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 10,
            children: [
              GradeDisplay(grade: average, size: 100, strokeWidth: 5, roundGrade: false, textBelow: "${grades.length} note${grades.length > 1 ? 's' : ''}"),
              Text("Moyenne générale", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bulletin", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    database.subjects.getAll().map((subject) {
                      return Row(
                        spacing: 6,
                        children: [
                          SubjectBadge(subject: subject, size: 20),
                          Text(subject.name),
                          Text(calculateAverage(grades.where((g) => g.subject.value?.code == subject.code).toList(), round: true).toString()),
                        ],
                      );
                    }).toList(),
              ),
              Spacer(),
              Text("Total des points: ${calculateAverage(grades)}", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 2,
      children: [
        HugeIcon(icon: HugeIcons.strokeRoundedDashedLine02, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),
        const SizedBox(height: 8),
        Text("Rien pour le moment...", style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22)),
        Text("Vos résultats s'afficheront ici", style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.tertiaryText.adaptTo(context))),
        CupertinoButton(
          onPressed: () => showNewGradePopup(),
          padding: EdgeInsets.only(top: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [Text("Ajouter une note", style: TextStyle(fontWeight: FontWeight.w400)), HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18)],
          ),
        ),
      ],
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
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: StreamBuilder(
                  stream: database.grades.watchAll(),
                  builder: (context, _) {
                    // All the grades
                    final allGrades = database.grades.getAll();

                    // A list of all the subjects with at least 1 grade
                    final List<Subject> allSubjects = [];
                    for (final grade in allGrades) {
                      if (grade.subject.value != null && !allSubjects.any((subject) => grade.subject.value?.code == subject.code)) {
                        allSubjects.add(grade.subject.value!);
                      }
                    }

                    return allGrades.isEmpty
                        ? buildPlaceholder()
                        : SingleChildScrollView(
                          child: Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buildGeneralAverageBar(),

                              SizedBox(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Par branche", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),

                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GradesBySubjectPage())),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Tout voir",
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.tertiaryText.adaptTo(context)),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              buildSubjectsGrid(allSubjects),

                              SizedBox(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Récentes", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),

                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => RecentGradesPage())),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Tout voir",
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.tertiaryText.adaptTo(context)),
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
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [AppColors.black, AppColors.black, AppColors.transparent],
                                      stops: [0.0, 0.6, 1.0],
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: min(10, allGrades.length),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final grade = allGrades.elementAtOrNull(index);
                                      return grade == null
                                          ? const SizedBox.shrink()
                                          : GradeBar(gradeData: grade, showSubject: true, onTap: () => showNewGradePopup(toEdit: grade));
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
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
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground.adaptTo(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.black.withAlpha(30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))],
                        ),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
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
