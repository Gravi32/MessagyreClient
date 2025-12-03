import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/grades_subpages/group_page.dart';
import 'package:messagyre_client/pages/grades_subpages/new_grade.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SubjectPage extends StatefulWidget {
  final Subject subject;

  const SubjectPage({super.key, required this.subject});

  @override
  State<StatefulWidget> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final router = ConnectionController();
  final data = Data();

  Box<Grade> allGrades = Hive.box<Grade>("Grades");
  Box<Homework> allHomework = Hive.box<Homework>("Homework");
  List<Grade> subjectGrades = [];
  List<Homework> subjectIncomingGrades = [];
  List<String> groupNames = [];

  @override
  void initState() {
    super.initState();
    loadGrades();
  }

  void loadGrades() {
    subjectGrades.clear();
    subjectGrades = allGrades.values.where((grade) => grade.subject == widget.subject).toList();

    subjectIncomingGrades =
        allHomework.values
            .where(
              (homework) =>
                  homework.subject == widget.subject &&
                  (homework.isGraded || homework.isTest) &&
                  !subjectGrades.any((grade) => grade.referenceId == homework.referenceId),
            )
            .sortedBy((homework) => homework.dueDate)
            .toList();
  }

  Widget buildGroupBar(String groupName) {
    final gradesInGroup = subjectGrades.where((grade) => grade.groupName == groupName).toList();

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
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: CupertinoColors.systemGrey),
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
            Navigator.of(
              context,
              rootNavigator: true,
            ).push(CupertinoPageRoute(builder: (context) => GroupPage(grades: gradesInGroup, existingGroupNames: groupNames))).then((_) {
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

    int barsToBuild = 0;

    // Reading group names from grades
    groupNames.clear();
    for (final grade in subjectGrades) {
      if (grade.groupName != null) {
        if (!groupNames.contains(grade.groupName!)) {
          groupNames.add(grade.groupName!);
          barsToBuild++;
        }
      } else {
        barsToBuild++;
      }
    }

    // Sorting grades by date
    subjectGrades.sort((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    return Column(
      spacing: 1,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(top: 8),
          itemCount: barsToBuild,
          itemBuilder: (context, index) {
            return index + 1 <= barsToBuild - groupNames.length
                ? GradeBar(gradeData: subjectGrades.elementAt(index), onTap: () => showNewGradePopup(toEdit: subjectGrades.elementAt(index)))
                : buildGroupBar(groupNames[index - (barsToBuild - groupNames.length)]);
          },
        ),

        if (subjectIncomingGrades.isNotEmpty) ...[
          Text("Notes prévues", style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context))),
          Divider(color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(.4)),
        ],

        ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: subjectIncomingGrades.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final homework = subjectIncomingGrades[index];
            final grade =
                Grade()
                  ..title = homework.content
                  ..date = homework.dueDate;
            return GradeBar(
              gradeData: grade,
              onTap: () {},
              isGradeUnknown: true,
              isIncoming: homework.dueDate.isBefore(DateTime.now()),
              isPlanned: homework.dueDate.isAfter(DateTime.now()),
            );
          },
        ),
      ],
    );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoModalBottomSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder:
          (context) => NewGrade(
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
