import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
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
import 'package:messagyre_client/utility/widgets/basics/section_header.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/chart.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
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

  /// A group of grades (several tests counting as one grade), as a row of a card
  Widget buildGroupRow(String groupName) {
    final gradesInGroup = thisSubjectGrades.where((grade) => grade.groupName == groupName).toList();

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .55,
      onPressed: () => Navigator.of(context, rootNavigator: true)
          .push(
            CupertinoPageRoute(
              builder: (context) => GradeGroupPage(groupName: groupName, groupSubject: widget.subject),
            ),
          )
          .then((_) => setState(() {})),
      child: Padding(
        padding: const .fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.m, AppSpacing.m),
        child: Row(
          spacing: AppSpacing.m + 2,
          children: [
            GradeDisplay(grade: calculateAverage(gradesInGroup), size: 46, isGroup: true),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                spacing: 3,
                children: [
                  Text(groupName, maxLines: 1, overflow: .ellipsis, style: AppStyles.strongText(context)),
                  Text(gradesInGroup.map((grade) => grade.title).join(" · "), maxLines: 1, overflow: .ellipsis, style: AppStyles.subheadline(context)),
                ],
              ),
            ),
            AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
          ],
        ),
      ),
    );
  }

  /// The average, big, with its curve
  Widget buildAverageCard() {
    final grades = thisSubjectGrades.sorted((a, b) => a.date.compareTo(b.date));
    final average = calculateAverage(grades);
    final color = average < 4 ? getGradeColor(average, context) : widget.subject.color;

    return RoundContainer(
      padding: const .all(AppSpacing.card),
      child: Row(
        crossAxisAlignment: .end,
        spacing: AppSpacing.xl,
        children: [
          Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                spacing: AppSpacing.s,
                children: [
                  SubjectBadge(subject: widget.subject, size: 18),
                  Text("MOYENNE", style: AppStyles.overline(context)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                grades.isEmpty ? "–" : average.toStringAsFixed(2),
                style: AppStyles.display(context).copyWith(color: average < 4 && grades.isNotEmpty ? color : null),
              ),
              Text(grades.isEmpty ? "Aucune note" : "${grades.length} note${grades.length > 1 ? "s" : ""}", style: AppStyles.subheadline(context)),
            ],
          ),
          if (grades.isNotEmpty)
            Expanded(
              child: SizedBox(
                height: 72,
                child: Chart(
                  color: color,
                  showLines: false,
                  showDots: true,
                  spots: grades
                      .mapIndexed(
                        (index, grade) => FlSpot(index.toDouble(), calculateAverage(grades.where((other) => other.date.compareTo(grade.date) <= 0).toList())),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The grade needed at the next test (weight 1) to keep, raise or reach the average
  Widget buildGoals() {
    final average = calculateAverage(thisSubjectGrades);
    final (toPass, toMaintain, toBoost) = calculateGoalGrades(thisSubjectGrades, 1);

    String formatGrade(double grade) => grade < 1
        ? "< 1"
        : grade > 6
        ? "> 6"
        : grade.removeTrailingZero();

    Widget goal({required List<List<dynamic>> icon, required String title, required double needed}) {
      final impossible = needed > 6;
      final certain = needed < 1;
      return Padding(
        padding: const .symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m + 1),
        child: Row(
          spacing: AppSpacing.m,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: .center,
              decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(9)),
              child: AppIcon(icon: icon, size: 18, color: AppColors.text.adaptTo(context)),
            ),
            Expanded(child: Text(title, style: AppStyles.primaryText(context))),
            Text(
              impossible ? "Impossible" : (certain ? "Assuré" : formatGrade(needed)),
              style: (impossible || certain ? AppStyles.subheadline(context) : AppStyles.secondaryHeader(context).copyWith(fontWeight: .w700)).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        const SectionHeader("Objectifs"),
        CardGroup(
          separatorInset: AppSpacing.l + 32 + AppSpacing.m,
          children: [
            if (average < 3.75) goal(icon: AppIcons.goalPass, title: "Avoir la moyenne", needed: toPass),
            if (average < 5.75) goal(icon: AppIcons.goalUp, title: "Monter à ${(average.roundToHalves() + .5).removeTrailingZero()}", needed: toBoost),
            goal(icon: AppIcons.goalKeep, title: "Rester à ${average.roundToHalves().removeTrailingZero()}", needed: toMaintain),
            if (average >= 4.25) goal(icon: AppIcons.goalDown, title: "Garder la moyenne", needed: toPass),
          ],
        ),
        Padding(
          padding: const .only(left: 4, top: AppSpacing.s),
          child: Text("La note à obtenir au prochain test (poids 1).", style: AppStyles.footer(context)),
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

          final ungrouped = thisSubjectGrades.where((grade) => grade.groupName == null).sorted((a, b) => b.date.compareTo(a.date));

          Widget section(Widget child) => Padding(
            padding: const .only(top: AppSpacing.section),
            child: child,
          );

          return ListView(
            padding: const .only(top: AppSpacing.s),
            children: [
              buildAverageCard(),

              if (thisSubjectGrades.isNotEmpty) section(buildGoals()),

              if (ungrouped.isNotEmpty)
                section(
                  Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      const SectionHeader("Notes"),
                      CardGroup(
                        separatorInset: GradeBar.separatorInset,
                        children: [
                          for (final grade in ungrouped)
                            GradeBar(
                              gradeData: grade,
                              onTap: () => showNewGradePopup(toEdit: grade),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (groups.isNotEmpty)
                section(
                  Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      const SectionHeader("Groupes"),
                      CardGroup(separatorInset: GradeBar.separatorInset, children: [for (final groupName in groups.keys) buildGroupRow(groupName)]),
                    ],
                  ),
                ),

              if (incomingGrades.isNotEmpty)
                section(
                  Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      const SectionHeader("Prévues"),
                      CardGroup(
                        separatorInset: GradeBar.separatorInset,
                        children: [
                          for (final assignment in incomingGrades)
                            GradeBar(
                              gradeData: Grade()
                                ..title = assignment.title ?? assignment.content
                                ..grade = 0
                                ..date = assignment.dueDate,
                              onTap: () {
                                if (assignment.dueDate.isBefore(DateTime.now())) {
                                  showNewGradePopup(toReference: assignment);
                                  return;
                                }
                                if (widget.wasPushedFromGradesBySubjectPage) Navigator.pop(context);
                                Navigator.pop(context);
                                MainPage.pageIndex.value = 1;
                              },
                              isGradeUnknown: true,
                              isIncoming: assignment.dueDate.isBefore(DateTime.now()),
                              isPlanned: assignment.dueDate.isAfter(DateTime.now()),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

              const BottomSpacing(),
            ],
          );
        },
      ),
    );
  }
}
