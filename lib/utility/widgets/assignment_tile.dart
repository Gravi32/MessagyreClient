import 'package:animated_line_through/animated_line_through.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/shared_assignment.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/tag.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

/// The tag in front of a test or a leave
Widget? assignmentTypeTag(AssignmentType type) => switch (type) {
  AssignmentType.test => const Tag(text: AppStrings.tagTest, color: AppColors.red),
  AssignmentType.leave => const Tag(text: AppStrings.tagLeave, color: AppColors.orange),
  AssignmentType.assignment => null,
};

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
  static const animationDuration = Duration(milliseconds: 500);

  // The tile's assignment can be replaced by a newer copy from the database: always read it from the widget
  Assignment get assignment => widget.assignment;

  late bool isDone = widget.assignment.isMarkedAsDone;

  @override
  void didUpdateWidget(covariant AssignmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assignment.isMarkedAsDone != isDone) isDone = widget.assignment.isMarkedAsDone;
  }

  @override
  Widget build(BuildContext context) {
    final tag = assignmentTypeTag(assignment.type);
    final subject = assignment.subject.value;

    final details = assignment.type == AssignmentType.leave
        ? "Prévu pour ${formatDate(assignment.dueDate, includeArticle: true)}"
        : [?subject?.name, if (widget.showDate) formatDate(assignment.dueDate)].join("  •  ");

    return ListTile(
      key: ValueKey(assignment.id),
      enabled: widget.enabled,
      buildChevron: widget.enabled,
      padding: widget.padding,
      onTap: () => showCupertinoSheet(context: context, builder: (context) => NewAssignmentPage(toEdit: assignment), enableDrag: false),
      trailing: assignment.type == AssignmentType.assignment
          ? Button.icon(
              context,
              size: AppSizes.control,
              icon: AppIcons.done,
              color: AppColors.tertiaryBackground.adaptTo(context),
              iconColor: isDone ? AppColors.green : AppColors.tertiaryBackground.adaptTo(context),
              enabled: widget.enabled,
              onTap: () async {
                setState(() => isDone = !isDone);
                await database.assignments.markDone(assignment, isDone);
              },
            )
          : null,
      child: Opacity(
        opacity: widget.dim ? .6 : 1,
        child: Column(
          crossAxisAlignment: .start,
          spacing: AppSpacing.s,
          children: [
            Row(
              spacing: AppSpacing.s + 2,
              children: [
                ?tag,
                Expanded(
                  child: AnimatedLineThrough(
                    isCrossed: switch (assignment.type) {
                      AssignmentType.assignment => isDone,
                      AssignmentType.test => widget.dim,
                      AssignmentType.leave => false,
                    },
                    color: AppColors.text.adaptTo(context),
                    duration: animationDuration,
                    child: Text(
                      assignment.type == AssignmentType.test ? (assignment.title ?? AppStrings.untitledTest) : assignment.content,
                      style: AppStyles.secondaryHeader(context).copyWith(color: assignment.type == AssignmentType.test ? AppColors.red : null),
                      softWrap: true,
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            if (assignment.type == AssignmentType.test && assignment.content.isNotEmpty)
              Text(assignment.content, style: AppStyles.primaryText(context), softWrap: true, maxLines: 5, overflow: .ellipsis),

            if (details.isNotEmpty)
              Row(
                spacing: AppSpacing.s,
                children: [
                  if (subject != null) SubjectBadge(subject: subject, size: 22),
                  Expanded(child: Text(details, style: AppStyles.secondaryText(context))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// An assignment shared by a classmate (read-only)
class SharedAssignmentTile extends ListTile {
  final SharedAssignment assignment;

  const SharedAssignmentTile({super.key, required this.assignment}) : super(buildChevron: false);

  @override
  State<SharedAssignmentTile> createState() => _SharedAssignmentTileState();
}

class _SharedAssignmentTileState extends State<SharedAssignmentTile> {
  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final tag = assignmentTypeTag(assignment.type);
    final author = assignment.authorUsername;

    return ListTile(
      buildChevron: false,
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.s,
        children: [
          Row(
            spacing: AppSpacing.s + 2,
            children: [
              ?tag,
              Expanded(
                child: Text(
                  assignment.displayTitle,
                  style: AppStyles.secondaryHeader(context).copyWith(color: assignment.type == AssignmentType.test ? AppColors.red : null),
                  softWrap: true,
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
              ),
            ],
          ),
          if (assignment.type == AssignmentType.test && assignment.content.isNotEmpty)
            Text(assignment.content, style: AppStyles.primaryText(context), softWrap: true, maxLines: 5, overflow: .ellipsis),
          Text(
            [formatDate(assignment.dueDate), if (author != null && author.isNotEmpty) AppStrings.sharedBy(Account.getDefaultDisplayName(author))].join("  •  "),
            style: AppStyles.secondaryText(context),
          ),
        ],
      ),
    );
  }
}
