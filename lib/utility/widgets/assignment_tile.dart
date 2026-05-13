import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class AssignmentTile extends ListTile {
  final Assignment assignment;
  final bool showDate;
  final bool dim;

  const AssignmentTile({super.key, required this.assignment, this.showDate = true, this.dim = false, super.enabled, super.padding});

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

    if (oldWidget.assignment.isMarkedAsDone != widget.assignment.isMarkedAsDone && widget.assignment.isMarkedAsDone != isDone) {
      setState(() => isDone = widget.assignment.isMarkedAsDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(assignment.id),
      enabled: widget.enabled,
      buildChevron: widget.enabled,
      padding: widget.padding,
      onTap: () => showCupertinoSheet(
        context: context,
        builder: (context) => NewAssignmentPage(toEdit: assignment),
        enableDrag: false,
      ),
      trailing: assignment.type == .assignment
          ? Button.icon(
              context,
              size: 50,
              icon: HugeIcons.strokeRoundedTick02,
              color: AppColors.tertiaryBackground.adaptTo(context),
              iconColor: isDone ? AppColors.green : AppColors.tertiaryBackground.adaptTo(context),
              enabled: widget.enabled,
              onTap: () async {
                isDone = !isDone;
                assignment.isMarkedAsDone = isDone;
                await database.assignments.save(assignment);
              },
            )
          : null,

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
                      borderRadius: .circular(24),
                    ),
                    padding: .all(4),
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
                      borderRadius: .circular(24),
                    ),
                    padding: .all(4),
                    child: Text(
                      "CONGÉ",
                      style: TextStyle(fontSize: 14, letterSpacing: .3, fontWeight: .w900, color: AppColors.white),
                    ),
                  ),

                // Title
                Expanded(
                  child: AnimatedLineThrough(
                    isCrossed: switch (assignment.type) {
                      .assignment => isDone,
                      .test => widget.dim,
                      .leave => false,
                    },
                    color: AppColors.text.adaptTo(context),
                    duration: animationDuration,
                    child: Text(
                      switch (assignment.type) {
                        .assignment => assignment.content,
                        .test => assignment.title ?? "Test sans titre",
                        .leave => assignment.content,
                      },
                      style: AppStyles.secondaryHeader(context).copyWith(color: assignment.type == .test ? AppColors.red : null),
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),

            // Description
            if (assignment.type == .test && assignment.content.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                child: Text(assignment.content, style: AppStyles.primaryText(context), softWrap: true, maxLines: 5),
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
                    style: AppStyles.primaryText(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
