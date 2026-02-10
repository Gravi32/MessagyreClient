import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class GradesListPage extends StatefulWidget {
  const GradesListPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> {
  static const double subjectTileMaxHeight = 106;

  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  bool isAverageBarExpanded = false;
  bool isIncomingGradesInfoExpanded = false;

  Widget buildSubjectBar(Subject subject, {bool isGradeUnknown = false}) {
    final grades = database.grades.getAll().where((grade) => grade.subject.value?.code == subject.code).toList();
    final average = calculateAverage(grades, round: true);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground.adaptTo(context),
        border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(maxHeight: subjectTileMaxHeight),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => GradesSubjectPage(subject: subject)));
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
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SizedBox.square(
                    dimension: 28,
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedArtboard, color: AppColors.yellow.withBrightness(.5)),
                    ),
                  ),
                ),
                Text(average.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),
              ],
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Text(
                  subject.name,
                  style: TextStyle(
                    fontWeight: isGradeUnknown ? FontWeight.w400 : FontWeight.w500,
                    fontSize: 18,
                    color: isGradeUnknown ? AppColors.tertiaryText.adaptTo(context) : adaptiveColor(AppColors.black, AppColors.white),
                  ),
                ),

                Container(
                  height: 8,
                  decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final progress = average / 6;

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGeneralAverageBar() {
    final grades = database.grades.getAll();
    final average = calculateAverage(grades.toList());

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: CupertinoPressable(
        onTap: () => setState(() => isAverageBarExpanded = !isAverageBarExpanded),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, axis: Axis.vertical, axisAlignment: 1, child: child));
              },
              child:
                  isAverageBarExpanded
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            "Informations supplémentaires",
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white)),
                          ),
                          Text("Total des points: ${calculateAverage(grades)}", style: TextStyle(fontSize: 16)),
                          Text(
                            "Plusieurs options seront disponibles dans les prochaines mises à jours...",
                            style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context)),
                          ),
                          const SizedBox(height: 6),
                        ],
                      )
                      : const SizedBox.shrink(),
            ),

            Row(
              spacing: 3,
              children: [
                Text("Voir ${isAverageBarExpanded ? "moins" : "plus"}", style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context))),

                HugeIcon(
                  icon: isAverageBarExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                  size: 18,
                  color: AppColors.tertiaryText.adaptTo(context),
                ),
              ],
            ),
          ],
        ),
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

                    // All the assignments
                    final allAssignments = database.assignments.getAll();

                    // A list of the subjects that are going to be added
                    final allIncomingSubjects = [];
                    for (final assignment in allAssignments.sortedBy((assignment) => assignment.dueDate)) {
                      if ((assignment.isGraded || assignment.isTest) &&
                          assignment.referenceId != null &&
                          assignment.subject.value != null &&
                          !allIncomingSubjects.contains(assignment.subject.value)) {
                        allIncomingSubjects.add(assignment.subject.value!);
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
                              Text("Vos branches", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
                              GridView.builder(
                                padding: EdgeInsets.zero,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  mainAxisExtent: subjectTileMaxHeight,
                                ),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: allSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = allSubjects[index];
                                  return buildSubjectBar(subject);
                                },
                              ),

                              SizedBox(),
                              Text("Évaluations récentes", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
                              ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: min(10, allGrades.length),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final grade = allGrades.elementAtOrNull(index);
                                  return grade == null ? const SizedBox.shrink() : GradeBar(gradeData: grade, showSubject: true, onTap: null);
                                },
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
