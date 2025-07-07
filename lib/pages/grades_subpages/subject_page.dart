import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/pages/grades_subpages/new_grade.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';

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

  late Box<Grade> allGrades;

  Widget gradeDisplay(double grade) {
    final double size = 48;
    final CupertinoDynamicColor color;

    if (grade >= 4) {
      color = CupertinoColors.activeGreen;
    } else if (grade > 3.75) {
      color = CupertinoColors.activeOrange;
    } else {
      color = CupertinoColors.systemRed;
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: grade / 6,
              strokeWidth: 4,
              backgroundColor: adaptiveColor(
                context,
                CupertinoColors.black.withAlpha(20),
                CupertinoColors.white.withAlpha(30),
              ),
              color: color,
            ),
          ),
          Text(
            grade.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSubjectBar(Subject subject, List<Grade> grades) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                gradeDisplay(1),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SubjectHelper.toFrench(subject),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: adaptiveColor(
                            context,
                            CupertinoColors.black,
                            CupertinoColors.white,
                          ),
                        ),
                      ),
                      Text(
                        "${grades.length} notes",
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
                ),
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.end,
                //   children: [
                //     Text(
                //       DateFormat('HH:mm').format(data.content.last.sentAt),
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: CupertinoColors.systemGrey,
                //         fontWeight:
                //             hasUnreadMessages
                //                 ? FontWeight.w400
                //                 : FontWeight.w400,
                //       ),
                //     ),
                //     if (hasUnreadMessages)
                //       Container(
                //         margin: EdgeInsets.only(top: 4),
                //         padding: EdgeInsets.symmetric(
                //           horizontal: 6,
                //           vertical: 2,
                //         ),
                //         decoration: BoxDecoration(
                //           color: CupertinoColors.systemBlue,
                //           borderRadius: BorderRadius.circular(12),
                //         ),
                //         child: Text(
                //           data.unreadMessages.toString(),
                //           style: TextStyle(
                //             color: CupertinoColors.white,
                //             fontSize: 12,
                //           ),
                //         ),
                //       ),
                //   ],
                // ),
              ],
            ),
          ),
          onPressed: () {
            // Navigator.of(context, rootNavigator: true).push(
            //   CupertinoPageRoute(
            //     builder:
            //         (builder) => SubjectPage(subject: subject, grades: grades),
            //   ),
            // );
          },
        ),

        Divider(
          indent: 60,
          color: Theme.of(context).dividerColor.withAlpha(30),
        ),
      ],
    );
  }

  void showNewHomeworkPopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoSheet<Grade?>(
      context: context,
      pageBuilder: (context) => NewGrade(), //toEdit: toEdit),
    );

    if (newGrade == null) return;

    if (toEdit != null) toEdit.delete();

    allGrades.add(newGrade);
  }

  @override
  void initState() {
    super.initState();

    allGrades = Hive.box<Grade>("Grades");
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
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder(
                  valueListenable: allGrades.listenable(),
                  builder: (context, Box<Grade> box, _) {
                    final gradeList = box.values.toList();
                    gradeList.sort((gradeA, gradeB) {
                      return gradeB.date.compareTo(gradeA.date);
                    });

                    final subjectGradeList = <Subject, List<Grade>>{};
                    for (var grade in gradeList) {
                      subjectGradeList.putIfAbsent(grade.subject, () => []);
                      subjectGradeList[grade.subject]!.add(grade);
                    }

                    return gradeList.isEmpty
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 40,
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            Text(
                              "Ajoutez une note !",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          padding: EdgeInsets.only(top: 8),
                          itemCount: subjectGradeList.length,
                          itemBuilder: (context, index) {
                            final subjectGrades = subjectGradeList.entries
                                .elementAt(index);
                            return buildSubjectBar(
                              subjectGrades.key,
                              subjectGrades.value,
                            );
                          },
                        );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: CupertinoButton.tinted(
              onPressed: showNewHomeworkPopup,
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
