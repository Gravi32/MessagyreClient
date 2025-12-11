import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/grades_subpages/new_grade.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';

class GroupPage extends StatefulWidget {
  final List<Grade> grades;

  const GroupPage({super.key, required this.grades});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final Box<Grade> allGrades = Hive.box<Grade>("Grades");

  Widget buildList() {
    // Sorting grades by date
    widget.grades.sort((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    return ListView.builder(
      padding: EdgeInsets.only(top: 8),
      itemCount: widget.grades.length,
      itemBuilder:
          (context, index) => GradeBar(gradeData: widget.grades.elementAt(index), onTap: () => showNewGradePopup(toEdit: widget.grades.elementAt(index))),
    );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder:
          (context) => NewGrade(
            subject: widget.grades.isNotEmpty ? widget.grades.first.subject : null,
            toEdit: toEdit,
            onDelete: () {
              widget.grades.remove(toEdit);
              setState(() {});

              // Closing the page if empty
              if (widget.grades.isEmpty && mounted) {
                Navigator.of(context).pop();
              }
            },
            groupName: widget.grades.isNotEmpty ? widget.grades.first.groupName : null,
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

      // Closing the page if empty
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
                      Text(widget.grades.isNotEmpty ? (widget.grades.first.groupName ?? "Groupe") : "Groupe"),
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
