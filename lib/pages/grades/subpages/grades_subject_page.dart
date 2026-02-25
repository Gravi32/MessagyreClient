import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/grades/subpages/grade_group_page.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
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
  final database = DatabaseService();

  List<Grade> get thisSubjectGrades => database.grades.getAll().where((grade) => grade.subject.value?.code == widget.subject.code).toList();
  late final allAssignments = database.assignments.getAll();

  Widget buildGroupBar(String groupName) {
    final gradesInGroup = thisSubjectGrades.where((grade) => grade.groupName == groupName).toList();

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
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white)),
                                    ),

                                    Text(
                                      "contient ${gradesInGroup.length} note${gradesInGroup.length > 1 ? "s" : ""}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15, color: AppColors.tertiaryText.adaptTo(context), fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),

                                gradesInGroup.map((data) => data.title).isNotEmpty
                                    ? Text(
                                      gradesInGroup.map((data) => "• ${data.title}").join("\n"),
                                      maxLines: 2,
                                      overflow: TextOverflow.fade,
                                      style: TextStyle(color: AppColors.tertiaryText.adaptTo(context), fontSize: 15),
                                    )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.secondaryText.adaptTo(context)),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(indent: 60, color: AppColors.separator.adaptTo(context).withAlpha(30)),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).push(CupertinoPageRoute(builder: (context) => GradeGroupPage(grades: gradesInGroup))).then((_) => setState(() {}));
          },
        ),
      ],
    );
  }

  Widget buildList() {
    return StreamBuilder(
      stream: database.grades.watchAll(),
      builder: (context, _) {
        final incomingGrades =
            allAssignments
                .where(
                  (assignment) =>
                      assignment.subject.value == widget.subject &&
                      (assignment.isGraded || assignment.isTest) &&
                      !thisSubjectGrades.any((grade) => grade.referenceId == assignment.referenceId),
                )
                .sortedBy((assignment) => assignment.dueDate)
                .toList();

        final groups = {};
        for (var grade in thisSubjectGrades) {
          if (grade.groupName == null) continue;
          groups.putIfAbsent(grade.groupName!, () => []).add(grade);
        }

        final listContent = [
          ...thisSubjectGrades
              .where((grade) => grade.groupName == null)
              .toList()
              .sorted((gradeA, gradeB) {
                return gradeB.date.compareTo(gradeA.date);
              })
              .map((grade) => GradeBar(gradeData: grade, onTap: () => showNewGradePopup(toEdit: grade))),

          ...groups.keys.map((groupName) => buildGroupBar(groupName)),

          if (incomingGrades.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Notes prévues", style: TextStyle(fontSize: 16, color: AppColors.tertiaryText.adaptTo(context))),
                Divider(color: AppColors.secondaryBackground.adaptTo(context).withAlpha(.4.toByte())),
              ],
            ),

            ...incomingGrades.map((assignment) {
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
                  //assignmentListPageKey.currentState?.showAssignment(assignment);
                },
                isGradeUnknown: true,
                isIncoming: isIncoming,
                isPlanned: isPlanned,
              );
            }),
          ],
        ];

        return Column(
          spacing: 1,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.only(top: 8),
                itemCount: listContent.length,
                itemBuilder: (context, index) => listContent[index],
                separatorBuilder: (_, _) => SizedBox(height: 8),
              ),
            ),
          ],
        );
      },
    );
  }

  void showNewGradePopup({Grade? toEdit, Assignment? toReference}) async {
    await showCupertinoModalBottomSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder: (context) => NewGradePage(subject: widget.subject, toEdit: toEdit, toReference: toReference),
    );

    setState(() {});

    // Closing the page if empty
    if (thisSubjectGrades.isEmpty && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [CupertinoSliverNavigationBar(largeTitle: Text(widget.subject.name), previousPageTitle: "Retour")];
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
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(20)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
