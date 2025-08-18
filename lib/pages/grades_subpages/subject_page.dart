import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/pages/grades_subpages/new_grade.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';

class SubjectPage extends StatefulWidget {
  final Subject subject;
  final List<Grade> grades;

  const SubjectPage({super.key, required this.subject, required this.grades});

  @override
  State<StatefulWidget> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final router = ConnectionController();
  final data = Data();

  Widget buildGradeBar(Grade gradeData) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                GradeDisplay(grade: gradeData.grade),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            gradeData.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: adaptiveColor(
                                context,
                                CupertinoColors.black,
                                CupertinoColors.white,
                              ),
                            ),
                          ),
                          Text(
                            formatDate(gradeData.date).capitalize(),
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            softWrap: true,
                            style: TextStyle(
                              color: Theme.of(context).dividerColor,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          onPressed: () => showNewGradePopup(toEdit: gradeData),
        ),

        Divider(
          indent: 60,
          color: Theme.of(context).dividerColor.withAlpha(30),
        ),
      ],
    );
  }

  Widget buildList() {
    widget.grades.sort((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    return widget.grades.isEmpty
        ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(
              CupertinoIcons.sparkles,
              size: 40,
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            Text(
              "Ajoutez une note !",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
          ],
        )
        : ListView.builder(
          padding: EdgeInsets.only(top: 8),
          itemCount: widget.grades.length,
          itemBuilder: (context, index) {
            return buildGradeBar(widget.grades.elementAt(index));
          },
        );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoSheet<Grade?>(
      context: context,
      pageBuilder:
          (context) => NewGrade(subject: widget.subject, toEdit: toEdit),
    );

    if (newGrade == null) return;

    if (toEdit != null) {
      toEdit
        ..title = newGrade.title
        ..grade = newGrade.grade
        ..subject = newGrade.subject
        ..date = newGrade.date
        ..weight = newGrade.weight
        ..details = newGrade.details;

      await toEdit.save();
    } else {
      await Hive.box<Grade>("Grades").add(newGrade);
      widget.grades.add(newGrade);
    }

    setState(() {});
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
                  largeTitle: Text(SubjectHelper.toFrench(widget.subject)),
                  previousPageTitle: "Retour",
                ),
              ];
            },
            body: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: buildList(),
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: CupertinoButton.tinted(
              onPressed: showNewGradePopup,
              sizeStyle: CupertinoButtonSize.medium,
              child: Row(
                spacing: 8,
                children: [Icon(CupertinoIcons.add), Text("Ajouter une note")],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
