import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/grade_group_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/chart.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class GradesSubjectPage extends StatefulWidget {
  final Subject subject;
  final bool wasPushedFromGradesBySubjectPage;

  const GradesSubjectPage({super.key, required this.subject, this.wasPushedFromGradesBySubjectPage = false});

  @override
  State<StatefulWidget> createState() => _GradesSubjectPageState();
}

class _GradesSubjectPageState extends State<GradesSubjectPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  List<Grade> get thisSubjectGrades => database.grades.getAll().where((grade) => grade.subject.value?.code == widget.subject.code).toList();
  late final allAssignments = database.assignments.getAll();

  Widget buildGroupBar(String groupName) {
    final gradesInGroup = thisSubjectGrades.where((grade) => grade.groupName == groupName).toList();

    return Column(
      children: [
        CupertinoButton(
          padding: .zero,
          child: IntrinsicHeight(
            child: Column(
              spacing: 6,
              children: [
                Row(
                  children: [
                    GradeDisplay(grade: calculateAverage(gradesInGroup), isGroup: true),

                    SizedBox(width: 12),

                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: .start,
                              crossAxisAlignment: .start,
                              spacing: 4,
                              children: [
                                Row(
                                  spacing: 6,
                                  crossAxisAlignment: .baseline,
                                  textBaseline: .alphabetic,
                                  children: [
                                    Text(groupName, style: AppStyles.secondaryHeader(context)),

                                    Text(
                                      "contient ${gradesInGroup.length} note${gradesInGroup.length > 1 ? "s" : ""}",
                                      maxLines: 2,
                                      overflow: .ellipsis,
                                      style: AppStyles.tertiaryText(context),
                                    ),
                                  ],
                                ),

                                gradesInGroup.map((data) => data.title).isNotEmpty
                                    ? Text(
                                        gradesInGroup.map((data) => "• ${data.title}").join("\n"),
                                        maxLines: 2,
                                        overflow: .fade,
                                        style: AppStyles.tertiaryText(context),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          CupertinoListTileChevron(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true)
                .push(
                  CupertinoPageRoute(
                    builder: (context) => GradeGroupPage(groupName: groupName, groupSubject: widget.subject),
                  ),
                )
                .then((_) => setState(() {}));
          },
        ),
      ],
    );
  }

  Widget buildTopCard() {
    final average = calculateAverage(thisSubjectGrades);
    final (toPass, toMaintain, toBoost) = calculateGoalGrades(thisSubjectGrades, 1); //TODO: let the user choose the weight

    String formatGrade(double grade) {
      return grade < 1
          ? "< 1"
          : grade > 6
          ? "> 6"
          : grade.removeTrailingZero();
    }

    Widget buildGoalBox({required IconData icon, required String title, required String neededGrade, String? goalGrade, Color? gradeColor, bool dim = false}) {
      return Opacity(
        opacity: dim ? .4 : 1,
        child: Row(
          spacing: 8,
          children: [
            Icon(icon, color: AppColors.tertiaryText.adaptTo(context)),
            RoundContainer(
              margin: const .symmetric(vertical: 4),
              padding: const .symmetric(vertical: 4, horizontal: 10),
              color: AppColors.tertiaryBackground.adaptTo(context),
              child: Text(neededGrade, style: AppStyles.header(context)),
            ),

            Expanded(
              child: Row(
                spacing: 8,
                children: [
                  Text(title),
                  if (goalGrade != null) Text(goalGrade, style: AppStyles.header(context).copyWith(color: gradeColor)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return PagedCard(
      height: 200,
      pages: [
        Column(
          crossAxisAlignment: .stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                SubjectBadge(subject: widget.subject, size: 24),
                Text("Moyenne", style: AppStyles.header(context)),
                Spacer(),
                Text(average.toStringAsFixed(2), style: AppStyles.header(context).copyWith(color: widget.subject.color)),
              ],
            ),
            Expanded(
              child: Padding(
                padding: .only(top: 10),
                child: Chart(
                  color: widget.subject.color,
                  spots: thisSubjectGrades
                      .sorted((gradeA, gradeB) => gradeA.date.compareTo(gradeB.date))
                      .mapIndexed(
                        (index, grade) => FlSpot(
                          index / thisSubjectGrades.length,
                          calculateAverage(thisSubjectGrades.where((element) => element.date.compareTo(grade.date) <= 0).toList()),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: .stretch,
          children: [
            Text("Évolution des notes", style: AppStyles.header(context)),
            Expanded(
              child: Padding(
                padding: .only(top: 10, bottom: 8, left: 4),
                child: Chart(
                  color: widget.subject.color,
                  showDots: true,
                  showTitles: true,
                  spots: thisSubjectGrades
                      .sorted((gradeA, gradeB) => gradeA.date.compareTo(gradeB.date))
                      .mapIndexed((index, grade) => FlSpot(index / thisSubjectGrades.length, grade.grade))
                      .toList(),
                ),
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: .stretch,
          spacing: 6,
          children: [
            Row(
              spacing: 8,
              children: [
                Text("Objectifs", style: AppStyles.header(context)),
                Spacer(),
                Text(average.toStringAsFixed(2), style: AppStyles.header(context).copyWith(color: widget.subject.color)),
              ],
            ),
            Expanded(
              child: ListView(
                padding: .zero,
                physics: ClampingScrollPhysics(),
                children: [
                  if (average < 3.75)
                    buildGoalBox(icon: CupertinoIcons.bandage, title: "pour avoir la moyenne", neededGrade: formatGrade(toPass), dim: toPass < 1 || toPass > 6),
                  if (average < 5.75)
                    buildGoalBox(
                      icon: CupertinoIcons.arrow_turn_right_up,
                      title: "pour monter à",
                      goalGrade: (average.roundToHalves() + .5).removeTrailingZero(),
                      neededGrade: formatGrade(toBoost),
                      gradeColor: getGradeColor(average + .5, defaultColor: widget.subject.color),
                      dim: toBoost < 1 || toBoost > 6,
                    ),
                  buildGoalBox(
                    icon: CupertinoIcons.minus,
                    title: "pour maintenir",
                    goalGrade: average.roundToHalves().removeTrailingZero(),
                    neededGrade: formatGrade(toMaintain),
                    gradeColor: getGradeColor(average, defaultColor: widget.subject.color),
                    dim: toMaintain < 1 || toMaintain > 6,
                  ),
                  if (average >= 4.25)
                    buildGoalBox(
                      icon: CupertinoIcons.arrow_turn_right_down,
                      title: "pour avoir la moyenne",
                      neededGrade: formatGrade(toPass),
                      dim: toPass < 1 || toPass > 6,
                    ),
                ],
              ),
            ),
            Row(
              spacing: 8,
              children: [
                RoundContainer(
                  padding: const .symmetric(vertical: 4, horizontal: 10),
                  color: AppColors.tertiaryBackground.adaptTo(context),
                  child: Text("Note nécessaire", style: AppStyles.tertiaryText(context)),
                ),

                Expanded(child: Text("pour atteindre l'objectif", style: AppStyles.tertiaryText(context))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void showNewGradePopup({Grade? toEdit, Assignment? toReference}) async {
    await showCupertinoSheet(
      context: context,
      enableDrag: false,
      builder: (context) => NewGradePage(subject: widget.subject, toEdit: toEdit, toReference: toReference),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      onFloatingButtonTap: showNewGradePopup,
      topBar: TopBar.sliverWithChevron(
        context,
        title: widget.subject.name,
        trailing: Button.icon(
          context,
          icon: HugeIcons.strokeRoundedSettings05,
          onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => NewSubjectPage(toEdit: widget.subject))),
        ),
      ),
      body: StreamBuilder(
        stream: database.grades.watchAll(),
        builder: (context, _) {
          final incomingGrades = allAssignments
              .where(
                (assignment) =>
                    assignment.subject.value?.code == widget.subject.code &&
                    assignment.type == AssignmentType.test &&
                    !thisSubjectGrades.any((grade) => grade.referenceId == assignment.referenceId),
              )
              .sortedBy((assignment) => assignment.dueDate)
              .toList();

          final groups = {};
          for (var grade in thisSubjectGrades) {
            if (grade.groupName == null) continue;
            groups.putIfAbsent(grade.groupName!, () => []).add(grade);
          }

          final listContent = [
            buildTopCard(),

            // All grades
            if (thisSubjectGrades.isNotEmpty) Text("Notes", style: AppStyles.header(context)),
            ...thisSubjectGrades
                .where((grade) => grade.groupName == null)
                .toList()
                .sorted((gradeA, gradeB) {
                  return gradeB.date.compareTo(gradeA.date);
                })
                .map(
                  (grade) => GradeBar(
                    gradeData: grade,
                    onTap: () => showNewGradePopup(toEdit: grade),
                  ),
                ),

            // Groups
            if (groups.isNotEmpty) ...[
              SizedBox(),
              Text("Groupes", style: AppStyles.header(context)),
              ...groups.keys.map((groupName) => buildGroupBar(groupName)),
            ],

            // Incoming grades
            if (incomingGrades.isNotEmpty) ...[
              SizedBox(),
              Text("Notes prévues", style: AppStyles.header(context)),
              ...incomingGrades.map((assignment) {
                final grade = Grade()
                  ..title = assignment.title ?? assignment.content
                  ..grade = 0
                  ..date = assignment.dueDate;
                final isIncoming = assignment.dueDate.isBefore(DateTime.now());
                final isPlanned = assignment.dueDate.isAfter(DateTime.now());

                return GradeBar(
                  gradeData: grade,
                  onTap: () {
                    if (isIncoming) {
                      showNewGradePopup(toReference: assignment);
                      return;
                    }
                    if (widget.wasPushedFromGradesBySubjectPage) Navigator.pop(context);
                    Navigator.pop(context);
                    MainPage.pageIndex.value = 1;
                    //assignmentListPageKey.currentState?.showAssignment(assignment);
                  },
                  isGradeUnknown: true,
                  isIncoming: isIncoming,
                  isPlanned: isPlanned,
                );
              }),
            ],
          ];

          return ListView.separated(
            shrinkWrap: true,
            padding: .only(top: 8),
            itemCount: listContent.length,
            itemBuilder: (context, index) => listContent[index],
            separatorBuilder: (_, _) => SizedBox(height: 8),
          );
        },
      ),
    );
  }
}
