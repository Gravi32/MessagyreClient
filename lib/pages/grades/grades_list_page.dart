import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/grades/subpages/grades_subject_page.dart';
import 'package:messagyre_client/pages/assignments/assignments_list_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class GradesListPage extends StatefulWidget {
  const GradesListPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesListPageState();
}

class _GradesListPageState extends State<GradesListPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  bool isAverageBarExpanded = false;
  bool isIncomingGradesInfoExpanded = false;

  Widget buildSubjectBar(Subject subject, {bool isGradeUnknown = false}) {
    final grades = database.grades.getAll().where((grade) => grade.subject.value?.code == subject.code).toList();
    final thisSubjectGradedAssignment =
        database.assignments
            .getAll()
            .where(
              (assignment) =>
                  assignment.subject.value == subject &&
                  assignment.referenceId != null &&
                  (assignment.isTest || assignment.isGraded) &&
                  !grades.any((grade) => grade.referenceId != null && grade.referenceId == assignment.referenceId),
            )
            .toList();

    // Passed tests that have not yet been graded
    final incomingGrades = thisSubjectGradedAssignment.where((assignment) => assignment.dueDate.isBefore(DateTime.now())).toList();

    // Tests that are planned in the future
    final plannedGrades = thisSubjectGradedAssignment.where((assignment) => assignment.dueDate.isAfter(DateTime.now())).toList();

    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              isGradeUnknown
                  ? () async {
                    final firstIncomingGrade = incomingGrades.elementAtOrNull(0);
                    final firstPlannedGrade = plannedGrades.elementAtOrNull(0);

                    if (firstIncomingGrade != null) {
                      showNewGradePopup(toReference: firstIncomingGrade);
                      return;
                    }

                    if (firstPlannedGrade != null) {
                      MainPage.pageIndex.value = 1;
                      assignmentListPageKey.currentState?.showAssignment(firstPlannedGrade);
                    }
                  }
                  : () {
                    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => GradesSubjectPage(subject: subject)));
                  },
          child: IntrinsicHeight(
            child: Row(
              children: [
                SizedBox(width: 4),
                GradeDisplay(
                  grade: isGradeUnknown ? 0 : calculateAverage(grades),
                  size: 48,
                  isIncoming: incomingGrades.isNotEmpty,
                  isPlanned: plannedGrades.isNotEmpty,
                  roundGrade: false,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: isGradeUnknown ? MainAxisAlignment.center : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        subject.name,
                        style: TextStyle(
                          fontWeight: isGradeUnknown ? FontWeight.w400 : FontWeight.w500,
                          fontSize: 18,
                          color: isGradeUnknown ? AppColors.tertiaryText.adaptTo(context) : adaptiveColor(AppColors.black, AppColors.white),
                        ),
                      ),

                      CustomText(
                        isGradeUnknown ? incomingGrades.join(", ") + plannedGrades.join(", ") : "${grades.length} note${grades.length > 1 ? 's' : ''}",
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(indent: 60, color: AppColors.secondaryBackground.adaptTo(context).withAlpha(.4.toByte())),
      ],
    );
  }

  Widget buildAverageBar() {
    final grades = database.grades.getAll();
    final average = calculateAverage(grades.toList());

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, top: 6),
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
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: StreamBuilder(
                  stream: database.grades.watchAll(),
                  builder: (context, _) {
                    // All the grades
                    final allGrades = database.grades.getAll();

                    // A list of all the subjects with at least 1 grade
                    final allSubjects = [];
                    for (final grade in allGrades) {
                      print(grade.subject);
                      if (!allSubjects.contains(grade.subject.value)) allSubjects.add(grade.subject.value);
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

                    print("$allGrades\t$allSubjects");

                    return allGrades.isEmpty
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 2,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedDashedLine02, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),
                            const SizedBox(height: 8),
                            Text(
                              "Rien pour le moment...",
                              style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22),
                            ),
                            Text(
                              "Vos résultats s'afficheront ici",
                              style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.tertiaryText.adaptTo(context)),
                            ),
                            CupertinoButton(
                              onPressed: () => showNewGradePopup(),
                              padding: EdgeInsets.only(top: 40),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  Text("Ajouter une note", style: TextStyle(fontWeight: FontWeight.w400)),
                                  HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
                                ],
                              ),
                            ),
                          ],
                        )
                        : SingleChildScrollView(
                          child: Column(
                            spacing: 20,
                            children: [
                              buildAverageBar(),

                              GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8),
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: allSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = allSubjects[index];
                                  return Container(child: buildSubjectBar(subject));
                                },
                              ),

                              if (allIncomingSubjects.isNotEmpty) ...[
                                CupertinoPressable(
                                  onTap: () => setState(() => isIncomingGradesInfoExpanded = !isIncomingGradesInfoExpanded),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Branches prévues", style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context))),
                                      HugeIcon(
                                        icon: isIncomingGradesInfoExpanded ? HugeIcons.strokeRoundedCancel01 : HugeIcons.strokeRoundedHelpCircle,
                                        size: 18,
                                        color: AppColors.tertiaryText.adaptTo(context),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: Duration(milliseconds: 300),
                                  switchInCurve: Curves.easeInOut,
                                  switchOutCurve: Curves.easeInOut,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SizeTransition(sizeFactor: animation, axis: Axis.vertical, axisAlignment: 1, child: child),
                                    );
                                  },
                                  child:
                                      isIncomingGradesInfoExpanded
                                          ? Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              "Les branches en gris ci-dessous apparaîtront dans la liste des moyennes dès que vous ajouterez votre première note.\nMessagyre les crée automatiquement lorsque vous créez un devoir avec l'option « ajouter à la page des notes » activée.",
                                              key: ValueKey("info"),
                                              style: TextStyle(color: AppColors.tertiaryText.adaptTo(context)),
                                            ),
                                          )
                                          : SizedBox(key: ValueKey("empty")),
                                ),

                                Divider(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(.4.toByte())),
                              ],

                              ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: allIncomingSubjects.length,
                                itemBuilder: (context, index) {
                                  final subjectFutureGrade = allIncomingSubjects.elementAt(index);
                                  return buildSubjectBar(subjectFutureGrade, isGradeUnknown: true);
                                },
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
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
