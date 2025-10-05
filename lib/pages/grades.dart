import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  late Box<List> subjectOrderBox;
  List<MapEntry<Subject, List<Grade>>> subjectGradeList = [];

  Widget buildSubjectBar(Subject subject, List<Grade> grades, int index) {
    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                SizedBox(width: 4),
                GradeDisplay(grade: calculateAverage(grades), size: 52),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SubjectHelper.toFrench(subject),
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                      ),
                      Text(
                        "${grades.length} note${grades.length > 1 ? 's' : ''}",
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 18),
                      ),
                    ],
                  ),
                ),

                ReorderableDragStartListener(
                  index: index,

                  child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(Icons.drag_handle_rounded, color: CupertinoColors.systemGrey)),
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => SubjectPage(subject: subject)));
          },
        ),
        Divider(indent: 60, color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(.75)),
      ],
    );
  }

  Widget buildAverageBar() {
    final average = calculateAverage(allGrades.values.toList());
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
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      Text(
                        "${allGrades.length} note${allGrades.length > 1 ? 's' : ''}",
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: Theme.of(context).dividerColor, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
              GradeDisplay(grade: average, size: 64),
            ],
          ),
          Divider(color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(.75)),
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
    subjectOrderBox = Hive.box<List>("SubjectOrder");
  }

  void loadSubjects() {
    final gradeList = allGrades.values.toList();
    final subjectGradeMap = <Subject, List<Grade>>{};
    for (var grade in gradeList) {
      subjectGradeMap.putIfAbsent(grade.subject, () => []);
      subjectGradeMap[grade.subject]!.add(grade);
    }
    subjectGradeList = subjectGradeMap.entries.toList();

    final savedOrder = subjectOrderBox.get('order')?.cast<int>();
    if (savedOrder != null) {
      subjectGradeList.sort((a, b) {
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

                    return subjectGradeList.isEmpty
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Icon(CupertinoIcons.sparkles, size: 36, color: CupertinoColors.separator.resolveFrom(context)),
                            Text(
                              "Ajoutez une note !",
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: CupertinoColors.separator.resolveFrom(context)),
                            ),
                          ],
                        )
                        : SingleChildScrollView(
                          child: Column(
                            spacing: 8,
                            children: [
                              buildAverageBar(),
                              ReorderableListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                buildDefaultDragHandles: false,
                                itemCount: subjectGradeList.length,
                                padding: EdgeInsets.only(top: 8),
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex--;
                                  final subjectGrades = subjectGradeList.removeAt(oldIndex);
                                  subjectGradeList.insert(newIndex, subjectGrades);

                                  final order = subjectGradeList.map((e) => e.key.index).toList();
                                  subjectOrderBox.put('order', order);
                                },
                                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                  return Material(color: CupertinoColors.systemBackground.resolveFrom(context).withAlpha(150), child: child);
                                },
                                itemBuilder: (context, index) {
                                  final subjectGrades = subjectGradeList[index];
                                  return Container(key: ValueKey(subjectGrades.key), child: buildSubjectBar(subjectGrades.key, subjectGrades.value, index));
                                },
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
                child: Icon(CupertinoIcons.add, color: CupertinoColors.label.resolveFrom(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
