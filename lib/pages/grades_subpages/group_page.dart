import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/grades_subpages/new_grade.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';

class GroupPage extends StatefulWidget {
  final List<Grade> grades;
  final List<String> existingGroupNames;

  const GroupPage({super.key, required this.grades, required this.existingGroupNames});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final Box<Grade> allGrades = Hive.box<Grade>("Grades");

  Widget buildGradeBar(Grade gradeData) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                GradeDisplay(grade: gradeData.grade, weight: gradeData.weight),

                SizedBox(width: 12),

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(
                            gradeData.title,
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                          ),
                          if (gradeData.details != null && gradeData.details!.isNotEmpty) ...[
                            Text(
                              gradeData.details!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 15),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        formatDate(gradeData.date).capitalize(),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          onPressed: () => showNewGradePopup(toEdit: gradeData),
        ),

        Divider(indent: 60, color: Theme.of(context).dividerColor.withAlpha(30)),
      ],
    );
  }

  Widget buildList() {
    // Sorting grades by date
    widget.grades.sort((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    return widget.grades.isEmpty
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
          itemCount: widget.grades.length,
          itemBuilder: (context, index) => buildGradeBar(widget.grades.elementAt(index)),
        );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoSheet<Grade?>(
      context: context,
      builder:
          (context) => NewGrade(
            subject: widget.grades.first.subject,
            toEdit: toEdit,
            onDelete: () {
              widget.grades.remove(toEdit);
              setState(() {});
            },
            groupName: widget.grades.first.groupName,
            existingGroupNames: widget.existingGroupNames,
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

      if (widget.grades.length == 1 && newGrade.groupName == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } else {
      await allGrades.add(newGrade);
      setState(() => widget.grades.add(newGrade));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                CupertinoSliverNavigationBar(
                  largeTitle: Row(
                    spacing: 10,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedSelect01, color: CupertinoColors.label.resolveFrom(context), size: 28),
                      Text(widget.grades.first.groupName ?? "Groupe"),
                    ],
                  ),
                  previousPageTitle: "Retour",
                ),
              ];
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
