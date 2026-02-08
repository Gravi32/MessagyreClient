import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/grade_group_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/pages/assignments/assignments_list_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class GradesSubjectPage extends StatefulWidget {
  final Subject subject;

  const GradesSubjectPage({super.key, required this.subject});

  @override
  State<StatefulWidget> createState() => _GradesSubjectPageState();
}

class _GradesSubjectPageState extends State<GradesSubjectPage> {
  final network = NetworkService();
  final globals = GlobalsService();

  Box<Grade> allGrades = Hive.box<Grade>("Grades");
  Box<Assignment> allAssignment = Hive.box<Assignment>("Assignment");

  List<Grade> allSubjectGrades = [];
  List<Grade> singleGrades = [];
  Map<String, List> groups = {};
  List<Assignment> subjectIncomingGrades = [];

  @override
  void initState() {
    super.initState();
    loadGrades();
  }

  void loadGrades() {
    // Loading all this subject' grades
    allSubjectGrades.clear();
    allSubjectGrades = allGrades.values.where((grade) => grade.subject == widget.subject).toList();

    // Loading single grades
    singleGrades = allSubjectGrades.where((grade) => grade.groupName == null).toList().sorted((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    // Loading groups
    for (var grade in allSubjectGrades) {
      if (grade.groupName == null) continue;
      groups.putIfAbsent(grade.groupName!, () => []).add(grade);
    }

    // Loading incoming grades
    subjectIncomingGrades =
        allAssignment.values
            .where(
              (assignment) =>
                  assignment.subject == widget.subject &&
                  (assignment.isGraded || assignment.isTest) &&
                  !allSubjectGrades.any((grade) => grade.referenceId == assignment.referenceId),
            )
            .sortedBy((assignment) => assignment.dueDate)
            .toList();
  }

  Widget buildGroupBar(String groupName) {
    final gradesInGroup = allSubjectGrades.where((grade) => grade.groupName == groupName).toList();

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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        color: adaptiveColor(CupertinoColors.black, CupertinoColors.white),
                                      ),
                                    ),

                                    Text(
                                      "contient ${gradesInGroup.length} note${gradesInGroup.length > 1 ? "s" : ""}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15, color: CupertinoColors.tertiaryLabel.resolveFrom(context), fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),

                                gradesInGroup.map((data) => data.title).isNotEmpty
                                    ? Text(
                                      gradesInGroup.map((data) => "• ${data.title}").join("\n"),
                                      maxLines: 2,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(color: CupertinoColors.tertiaryLabel.resolveFrom(context), fontSize: 15),
                                    )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(indent: 60, color: CupertinoColors.separator.resolveFrom(context).withAlpha(30)),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (context) => GradeGroupPage(grades: gradesInGroup))).then((_) {
              loadGrades();
              setState(() {});
            });
          },
        ),
      ],
    );
  }

  Widget buildList() {
    loadGrades();

    return Column(
      spacing: 1,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 8),

            children: [
              ...singleGrades.map((grade) => GradeBar(gradeData: grade, onTap: () => showNewGradePopup(toEdit: grade))),
              ...groups.keys.map((groupName) => buildGroupBar(groupName)),

              if (subjectIncomingGrades.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Notes prévues", style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context))),
                    Divider(color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withValues(alpha: .4)),
                  ],
                ),

                ...subjectIncomingGrades.map((assignment) {
                  final grade =
                      Grade()
                        ..title = assignment.content
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
                      assignmentListPageKey.currentState?.showAssignment(assignment);
                    },
                    isGradeUnknown: true,
                    isIncoming: isIncoming,
                    isPlanned: isPlanned,
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void showNewGradePopup({Grade? toEdit, Assignment? toReference}) async {
    final newGrade = await showCupertinoModalBottomSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder:
          (context) => NewGradePage(
            subject: widget.subject,
            toEdit: toEdit,
            onDelete: () {
              allGrades.delete(toEdit);
              loadGrades();
              setState(() {});

              // Closing the page if empty
              if (!allGrades.values.any((grade) => grade.subject == widget.subject)) {
                if (mounted) Navigator.of(context).pop();
              }
            },
            toReference: toReference,
          ),
    );

    if (newGrade == null) return;

    if (toEdit != null) {
      toEdit
        ..title = newGrade.title
        ..grade = newGrade.grade
        ..subject = newGrade.subject
        ..date = newGrade.date
        ..weight = newGrade.weight
        ..details = newGrade.details
        ..groupName = newGrade.groupName;

      await toEdit.save();
    } else {
      await Hive.box<Grade>("Grades").add(newGrade);
    }

    loadGrades();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [CupertinoSliverNavigationBar(largeTitle: Text(SubjectHelper.toFrench(widget.subject)), previousPageTitle: "Retour")];
            },
            body: SafeArea(top: false, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: buildList())),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: GestureDetector(
              onTap: showNewGradePopup,
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(20)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: CupertinoColors.label.resolveFrom(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
