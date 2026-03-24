import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/grade_group_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class GradesSubjectPage extends StatefulWidget {
  final Subject subject;

  const GradesSubjectPage({super.key, required this.subject});

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
          padding: EdgeInsets.zero,
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
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: [
                                Row(
                                  spacing: 6,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      groupName,
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white)),
                                    ),

                                    Text(
                                      "contient ${gradesInGroup.length} note${gradesInGroup.length > 1 ? "s" : ""}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15, color: AppColors.tertiaryText.adaptTo(context), fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),

                                gradesInGroup.map((data) => data.title).isNotEmpty
                                    ? Text(
                                      gradesInGroup.map((data) => "• ${data.title}").join("\n"),
                                      maxLines: 2,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(color: AppColors.tertiaryText.adaptTo(context), fontSize: 15),
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
            Navigator.of(
              context,
              rootNavigator: true,
            ).push(CupertinoPageRoute(builder: (context) => GradeGroupPage(groupName: groupName, groupSubject: widget.subject))).then((_) => setState(() {}));
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground.adaptTo(context),
                border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(neededGrade, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22))]),
                ],
              ),
            ),

            Expanded(
              child: Row(
                spacing: 8,
                children: [Text(title), if (goalGrade != null) Text(goalGrade, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: gradeColor))],
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              spacing: 8,
              children: [
                SubjectBadge(subject: widget.subject, size: 24),
                Text("Moyenne", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: AppColors.text.adaptTo(context))),
                Spacer(),
                Text(average.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: widget.subject.color)),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: LineChart(
                  LineChartData(
                    minY: 1,
                    maxY: 6,
                    lineBarsData: [
                      LineChartBarData(
                        color: widget.subject.color,
                        isCurved: true,
                        barWidth: 3,
                        preventCurveOverShooting: true,
                        isStrokeCapRound: true,
                        isStrokeJoinRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [widget.subject.color.withAlpha(80), AppColors.transparent],
                          ),
                        ),
                        spots:
                            thisSubjectGrades
                                .sorted((gradeA, gradeB) => gradeA.date.compareTo(gradeB.date))
                                .mapIndexed(
                                  (index, grade) => FlSpot(
                                    index / thisSubjectGrades.length,
                                    calculateAverage(thisSubjectGrades.where((element) => element.date.compareTo(grade.date) <= 0).toList()),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                    titlesData: FlTitlesData(show: false),
                    lineTouchData: LineTouchData(enabled: false),
                    gridData: FlGridData(drawVerticalLine: false, horizontalInterval: 1),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Évolution des notes", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 10, bottom: 8, left: 4),
                child: LineChart(
                  LineChartData(
                    minY: 1,
                    maxY: 6,
                    lineBarsData: [
                      LineChartBarData(
                        color: widget.subject.color,
                        isCurved: true,
                        barWidth: 3,
                        preventCurveOverShooting: true,
                        isStrokeCapRound: true,
                        isStrokeJoinRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [widget.subject.color.withAlpha(80), AppColors.transparent],
                          ),
                        ),
                        spots:
                            thisSubjectGrades
                                .sorted((gradeA, gradeB) => gradeA.date.compareTo(gradeB.date))
                                .mapIndexed((index, grade) => FlSpot(index / thisSubjectGrades.length, grade.grade))
                                .toList(),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(),
                      bottomTitles: AxisTitles(),
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 18,
                          getTitlesWidget:
                              (value, meta) => Align(
                                alignment: Alignment.centerRight,
                                child: Text(meta.formattedValue, style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context))),
                              ),
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(enabled: false),
                    gridData: FlGridData(drawVerticalLine: false, horizontalInterval: 1),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
          ],
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Row(
              spacing: 8,
              children: [
                Text("Objectifs", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: AppColors.text.adaptTo(context))),
                Spacer(),
                Text(
                  average.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: getGradeColor(average, greenOverride: widget.subject.color)),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: ClampingScrollPhysics(),
                children: [
                  if (average < 3.75)
                    buildGoalBox(icon: CupertinoIcons.bandage, title: "pour avoir la moyenne", neededGrade: formatGrade(toPass), dim: toPass < 1 || toPass > 6),
                  buildGoalBox(
                    icon: CupertinoIcons.arrow_turn_right_up,
                    title: "pour monter à",
                    goalGrade: (average.roundToHalves() + .5).removeTrailingZero(),
                    neededGrade: formatGrade(toBoost),
                    gradeColor: getGradeColor(average + .5, greenOverride: widget.subject.color),
                    dim: toBoost < 1 || toBoost > 6,
                  ),
                  buildGoalBox(
                    icon: CupertinoIcons.minus,
                    title: "pour maintenir",
                    goalGrade: average.roundToHalves().removeTrailingZero(),
                    neededGrade: formatGrade(toMaintain),
                    gradeColor: getGradeColor(average, greenOverride: widget.subject.color),
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground.adaptTo(context),
                    border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("Note nécessaire", style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context))),
                ),
                Text(" pour atteindre l'objectif", style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void showNewGradePopup({Grade? toEdit, Assignment? toReference}) async {
    await showCupertinoSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder: (context) => NewGradePage(subject: widget.subject, toEdit: toEdit, toReference: toReference),
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
              return [CupertinoSliverNavigationBar(largeTitle: Text(widget.subject.name), previousPageTitle: "Retour")];
            },
            body: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder(
                  stream: database.grades.watchAll(),
                  builder: (context, _) {
                    final incomingGrades =
                        allAssignments
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
                      if (thisSubjectGrades.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 0),
                          child: Text("Notes", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),
                        ),
                      ...thisSubjectGrades
                          .where((grade) => grade.groupName == null)
                          .toList()
                          .sorted((gradeA, gradeB) {
                            return gradeB.date.compareTo(gradeA.date);
                          })
                          .map((grade) => GradeBar(gradeData: grade, onTap: () => showNewGradePopup(toEdit: grade))),

                      // Groups
                      if (groups.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text("Groupes", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),
                        ),
                      ...groups.keys.map((groupName) => buildGroupBar(groupName)),

                      if (incomingGrades.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(top: 36),
                          child: Text("Notes prévues", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: AppColors.text.adaptTo(context))),
                        ),

                        ...incomingGrades.map((assignment) {
                          final grade =
                              Grade()
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
                      padding: EdgeInsets.only(top: 8),
                      itemCount: listContent.length,
                      itemBuilder: (context, index) => listContent[index],
                      separatorBuilder: (_, _) => SizedBox(height: 8),
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: GestureDetector(
              onTap: showNewGradePopup,
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(20)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
