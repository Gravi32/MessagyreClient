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

  late Box<Grade> allGrades;
  List<Grade> subjectGrades = [];
  List<String> groupNames = [];

  @override
  void initState() {
    super.initState();
    loadGrades();
  }

  void loadGrades() {
    allGrades = Hive.box<Grade>("Grades");

    subjectGrades.clear();

    subjectGrades = allGrades.values.where((grade) => grade.subject == widget.subject).toList();
  }

  Widget buildGroupBar(String groupName) {
    final gradesInGroup = subjectGrades.where((grade) => grade.groupName == groupName).toList();

    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 65,
            child: Row(
              children: [
                GradeDisplay(grade: calculateAverage(gradesInGroup)),

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
                              spacing: 10,
                              crossAxisAlignment: CrossAxisAlignment.end,
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
                                  gradesInGroup.length == 1 ? "1 note" : "${gradesInGroup.length} notes",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),

                            gradesInGroup.map((data) => data.title).isNotEmpty
                                ? Text(
                                  gradesInGroup.map((data) => "- ${data.title}").join("\n"),
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

        Divider(indent: 60, color: Theme.of(context).dividerColor.withAlpha(30)),
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

    return subjectGrades.isEmpty
        ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 40, strokeWidth: .5, color: CupertinoColors.separator.resolveFrom(context)),
            Text("Ajoutez une note !", style: TextStyle(fontWeight: FontWeight.w500, color: CupertinoColors.separator.resolveFrom(context))),
          ],
        )
        : ListView.builder(
          padding: EdgeInsets.only(top: 8),
          itemCount: barsToBuild,
          itemBuilder: (context, index) {
            return index + 1 <= barsToBuild - groupNames.length
                ? GradeBar(gradeData: subjectGrades.elementAt(index), onTap: () => showNewGradePopup(toEdit: subjectGrades.elementAt(index)))
                : buildGroupBar(groupNames[index - (barsToBuild - groupNames.length)]);
          },
        );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoModalBottomSheet<Grade?>(
      context: context,
      builder:
          (context) => NewGrade(
            subject: widget.subject,
            toEdit: toEdit,
            onDelete: () {
              allGrades.delete(toEdit);
              loadGrades();
              setState(() {});
            },
            existingGroupNames: groupNames,
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
