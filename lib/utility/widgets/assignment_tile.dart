import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class AssignmentTile extends StatefulWidget {
  final Assignment assignment;
  final bool showDate;
  final bool dim;
  final bool ignoreTouch;

  const AssignmentTile({super.key, required this.assignment, this.showDate = true, this.dim = false, this.ignoreTouch = false});

  @override
  State<AssignmentTile> createState() => _AssignmentTileState();
}

class _AssignmentTileState extends State<AssignmentTile> {
  final database = DatabaseService();

  late final assignment = widget.assignment;

  final Duration animationDuration = const Duration(milliseconds: 500);

  late bool isDone;

  @override
  void initState() {
    super.initState();
    isDone = assignment.isMarkedAsDone;
  }

  @override
  void didUpdateWidget(covariant AssignmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assignment.isMarkedAsDone != assignment.isMarkedAsDone) {
      isDone = assignment.isMarkedAsDone;
    }
  }

  Future<void> toggleDone() async {
    setState(() {
      isDone = !isDone;
    });

    await Future.delayed(animationDuration);

    assignment.isMarkedAsDone = isDone;
    await database.assignments.save(assignment);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile.notched(
      key: ValueKey(assignment.id),
      backgroundColor: Color.lerp(AppColors.secondaryBackground.adaptTo(context), AppColors.background.adaptTo(context), widget.dim ? .4 : 0),
      padding: const .all(10),
      trailing: widget.ignoreTouch ? null : CustomIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.grey),
      title: Row(
        spacing: 16,
        children: [
          if (assignment.type == AssignmentType.assignment)
            SizedBox(
              height: 30,
              child: GestureDetector(
                onTap: widget.ignoreTouch ? null : toggleDone,
                child: CustomIcon(
                  icon: isDone ? HugeIcons.strokeRoundedCheckmarkSquare04 : HugeIcons.strokeRoundedSquare,
                  size: 30,
                  color: isDone ? AppColors.green : AppColors.secondaryText.adaptTo(context),
                ),
              ),
            ),
          Expanded(
            child: Opacity(
              opacity: widget.dim ? .6 : 1,
              child: Column(
                crossAxisAlignment: .start,
                spacing: 8,
                children: [
                  // Title and tag
                  Row(
                    spacing: 10,
                    children: [
                      // Test tag
                      if (assignment.type == AssignmentType.test)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.red.withBrightness(-.25),
                            border: .all(color: AppColors.red),
                            borderRadius: .circular(6),
                          ),
                          padding: .all(2),
                          child: Text(
                            "TEST",
                            style: TextStyle(fontSize: 14, letterSpacing: .3, fontWeight: .w900, color: AppColors.white),
                          ),
                        ),

                      // Leave tag
                      if (assignment.type == AssignmentType.leave)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange.withBrightness(-.05),
                            border: .all(color: AppColors.yellow, strokeAlign: BorderSide.strokeAlignOutside),
                            borderRadius: .circular(6),
                          ),
                          padding: .all(2),
                          child: Text(
                            "CONGÉ",
                            style: TextStyle(fontSize: 14, letterSpacing: .3, fontWeight: .w900, color: AppColors.white),
                          ),
                        ),

                      // Title
                      Expanded(
                        child: AnimatedLineThrough(
                          isCrossed: switch (assignment.type) {
                            AssignmentType.assignment => isDone,
                            AssignmentType.test => widget.dim,
                            AssignmentType.leave => false,
                          },
                          duration: animationDuration,
                          child: Text(
                            switch (assignment.type) {
                              AssignmentType.assignment => assignment.content,
                              AssignmentType.test => assignment.title ?? "Test sans titre",
                              AssignmentType.leave => assignment.content,
                            },
                            style: TextStyle(fontSize: 22, fontWeight: .w500, color: assignment.type == AssignmentType.test ? AppColors.red : null),
                            softWrap: true,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (assignment.type == AssignmentType.test && assignment.content.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                      child: Text(
                        assignment.content,
                        style: TextStyle(fontSize: 18, fontWeight: .w400, color: AppColors.secondaryText.adaptTo(context)),
                        softWrap: true,
                        maxLines: 5,
                      ),
                    ),

                  // Subject and date
                  Row(
                    spacing: 8,
                    children: [
                      if (assignment.subject.value != null) SubjectBadge(subject: assignment.subject.value!, size: 22),
                      Expanded(
                        child: Text(
                          assignment.type == AssignmentType.leave
                              ? "Prévu pour ${formatDate(assignment.dueDate, includeArticle: true)}"
                              : "${assignment.subject.value?.name}${widget.showDate ? "  •  ${formatDate(assignment.dueDate)}" : ""}",
                          style: TextStyle(fontSize: 18, fontWeight: .w400, color: AppColors.secondaryText.adaptTo(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      onTap: widget.ignoreTouch
          ? null
          : () => Navigator.push(context, CupertinoSheetRoute(builder: (context) => NewAssignmentPage(toEdit: assignment), enableDrag: false)),
    );
  }
}
