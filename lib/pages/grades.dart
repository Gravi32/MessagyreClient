import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/grades_subpages/new_grade.dart';
import 'package:messagyre_client/pages/grades_subpages/subject_page.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<StatefulWidget> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> with AutomaticKeepAliveClientMixin {
  final router = ConnectionController();
  final data = Data();

  late Box<Grade> allGrades;
  late Box<Homework> allHomework;
  late Box<List> subjectOrderBox;
  List<MapEntry<Subject, List<Grade>>> subjectGradesList = [];
  List<MapEntry<Subject, List<Homework>>> subjectIncomingGradesList = [];

  Widget buildSubjectBar(Subject subject, {List<Grade> grades = const [], int index = 0, bool isIncoming = false}) {
    final incomingGrades =
        allHomework.values
            .where((homework) => homework.dueDate.isAfter(DateTime.now()) && (homework.isGraded || homework.isTest) && homework.subject == subject)
            .toList()
            ;

    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed:
              isIncoming
                  ? null
                  : () {
                    Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => SubjectPage(subject: subject)));
                  },
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                SizedBox(width: 4),
                GradeDisplay(grade: isIncoming ? null : calculateAverage(grades), size: 48, isIncoming: incomingGrades.isNotEmpty),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: isIncoming ? MainAxisAlignment.center : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SubjectHelper.toFrench(subject),
                        style: TextStyle(
                          fontWeight: isIncoming ? FontWeight.w400 : FontWeight.w500,
                          fontSize: 18,
                          color: isIncoming ? CupertinoColors.tertiaryLabel.resolveFrom(context) : adaptiveColor(CupertinoColors.black, CupertinoColors.white),
                        ),
                      ),

                      Text(
                        isIncoming ? incomingGrades.join(", "): "${grades.length} note${grades.length > 1 ? 's' : ''}",
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 18),
                      ),
                    ],
                  ),
                ),

                if (!isIncoming)
                  ReorderableDragStartListener(
                    index: index,

                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedUnfoldMore, color: CupertinoColors.systemGrey),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(indent: 60, color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(.4)),
      ],
    );
  }

  Widget buildAverageBar() {
    final average = calculateAverage(allGrades.values.toList());
    final incomingGrades =
        allHomework.values.where((homework) => homework.dueDate.isAfter(DateTime.now()) && (homework.isGraded || homework.isTest)).toList().length;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6, top: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    "Moyenne générale",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                  ),
                  Row(
                    children: [
                      Text(
                        "${allGrades.length} note${allGrades.length > 1 ? 's' : ''}",
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      if (incomingGrades > 0) ...[
                        Opacity(
                          opacity: .3,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            size: 14,
                            strokeWidth: 2,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "$incomingGrades à venir",
                          maxLines: 2,
                          overflow: TextOverflow.fade,
                          softWrap: true,
                          style: TextStyle(color: CupertinoColors.tertiaryLabel.resolveFrom(context), fontSize: 18),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              GradeDisplay(grade: average, size: 64),
            ],
          ),
          Divider(color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(.4)),
        ],
      ),
    );
  }

  void showNewHomeworkPopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoModalBottomSheet<Grade?>(enableDrag: false, context: context, builder: (context) => NewGrade());

    if (newGrade == null) return;

    if (toEdit != null) toEdit.delete();

    allGrades.add(newGrade);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    allGrades = Hive.box<Grade>("Grades");
    allHomework = Hive.box<Homework>("Homework");
    subjectOrderBox = Hive.box<List>("SubjectOrder");

    allHomework.listenable().addListener(
      () => setState(() {
        print("changedAAAA");
      }),
    );
  }

  void loadSubjects() {
    final gradeList = allGrades.values.toList();
    final homeworkList = allHomework.values.toList();

    final subjectGradesMap = <Subject, List<Grade>>{};
    final subjectIncomingGradesMap = <Subject, List<Homework>>{};

    for (var grade in gradeList) {
      subjectGradesMap.putIfAbsent(grade.subject, () => []);
      subjectGradesMap[grade.subject]!.add(grade);
    }

    for (var homework in homeworkList) {
      if (homework.dueDate.isBefore(DateTime.now()) || (!homework.isGraded && !homework.isTest)) continue;
      subjectIncomingGradesMap.putIfAbsent(homework.subject, () => []);
      subjectIncomingGradesMap[homework.subject]!.add(homework);
    }

    subjectGradesList = subjectGradesMap.entries.toList();
    subjectIncomingGradesList = subjectIncomingGradesMap.entries.toList();

    final savedOrder = subjectOrderBox.get('order')?.cast<int>();
    if (savedOrder != null) {
      subjectGradesList.sort((a, b) {
        final aIndex = savedOrder.indexOf(a.key.index);
        final bIndex = savedOrder.indexOf(b.key.index);
        return aIndex.compareTo(bIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    loadSubjects();

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
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: ValueListenableBuilder(
                  valueListenable: allGrades.listenable(),
                  builder: (context, Box<Grade> box, _) {
                    loadSubjects();

                    return subjectGradesList.isEmpty
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedSparkles, strokeWidth: .5, size: 36, color: CupertinoColors.separator.resolveFrom(context)),
                            Text(
                              "Ajoutez une note !",
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: CupertinoColors.separator.resolveFrom(context)),
                            ),
                          ],
                        )
                        : SingleChildScrollView(
                          child: Column(
                            children: [
                              buildAverageBar(),
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                itemCount: subjectGradesList.length,
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex--;
                                  final subjectGrades = subjectGradesList.removeAt(oldIndex);
                                  subjectGradesList.insert(newIndex, subjectGrades);

                                  final order = subjectGradesList.map((e) => e.key.index).toList();
                                  subjectOrderBox.put('order', order);
                                },
                                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                  return Material(color: CupertinoColors.systemBackground.resolveFrom(context).withAlpha(150), child: child);
                                },
                                itemBuilder: (context, index) {
                                  final subjectGrades = subjectGradesList[index];
                                  return Container(
                                    key: ValueKey(subjectGrades.key),
                                    child: buildSubjectBar(subjectGrades.key, grades: subjectGrades.value, index: index),
                                  );
                                },
                              ),
                              ListView.builder(
                                padding: EdgeInsets.zero,
                                itemBuilder: (context, index) {
                                  final subjectIncomingGrades = subjectIncomingGradesList[index];
                                  return buildSubjectBar(subjectIncomingGrades.key, isIncoming: true);
                                },
                                itemCount: subjectIncomingGradesList.length,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                              ),
                            ],
                          ),
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
              onTap: showNewHomeworkPopup,
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
