import 'package:hugeicons/hugeicons.dart';
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
    final subject = assignment.subject.value;
    final isTest = assignment.type == AssignmentType.test;

    final details = assignment.type == AssignmentType.leave
        ? "Prévu pour ${formatDate(assignment.dueDate, includeArticle: true)}"
        : [?subject?.name, if (widget.showDate) formatDate(assignment.dueDate)].join(" · ");

    return ListTile(
      key: ValueKey(assignment.id),
      enabled: widget.enabled,
      buildChevron: false,
      padding: widget.padding ?? const .fromLTRB(AppSpacing.l, AppSpacing.m + 2, AppSpacing.l, AppSpacing.m + 2),
      onTap: () => showCupertinoSheet(
        context: context,
        builder: (context) => NewAssignmentPage(toEdit: assignment),
        enableDrag: false,
      ),
      // A circle to tick for an assignment, a coloured mark for a test or a leave
      leading: assignment.type == AssignmentType.assignment
          ? CupertinoButton(
              padding: .zero,
              minimumSize: .zero,
              onPressed: widget.enabled
                  ? () async {
                      setState(() => isDone = !isDone);
                      await database.assignments.markDone(assignment, isDone);
                    }
                  : null,
              child: AnimatedContainer(
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                width: 26,
                height: 26,
                alignment: .center,
                decoration: BoxDecoration(
                  shape: .circle,
                  color: isDone ? AppColors.green : AppColors.transparent,
                  border: .all(color: isDone ? AppColors.green : AppColors.quaternaryText.adaptTo(context), width: 1.8),
                ),
                child: AnimatedOpacity(
                  duration: AppDurations.fast,
                  opacity: isDone ? 1 : 0,
                  child: const HugeIcon(icon: AppIcons.done, color: AppColors.white, size: 16, strokeWidth: 2.5),
                ),
              ),
            )
          : Container(
              width: 26,
              height: 26,
              alignment: .center,
              decoration: BoxDecoration(
                shape: .circle,
                color: (isTest ? AppColors.red : AppColors.orange).withValues(alpha: AppColors.isDark(context) ? .22 : .14),
              ),
              child: HugeIcon(
                icon: isTest ? HugeIcons.strokeRoundedAlert02 : HugeIcons.strokeRoundedSun03,
                size: 15,
                strokeWidth: 2,
                color: isTest ? AppColors.red : AppColors.orange,
              ),
            ),
      child: Opacity(
        opacity: widget.dim ? .55 : 1,
        child: Column(
          crossAxisAlignment: .start,
          spacing: 3,
          children: [
            if (isTest)
              Text(
                AppStrings.tagTest.toUpperCase(),
                style: AppStyles.caption(context).copyWith(color: AppColors.red, fontWeight: .w700, letterSpacing: .6),
              ),
            AnimatedLineThrough(
              isCrossed: switch (assignment.type) {
                AssignmentType.assignment => isDone,
                AssignmentType.test => widget.dim,
                AssignmentType.leave => false,
              },
              color: AppColors.tertiaryText.adaptTo(context),
              duration: animationDuration,
              child: Text(
                isTest ? (assignment.title ?? AppStrings.untitledTest) : assignment.content,
                style: AppStyles.strongText(context).copyWith(color: isDone ? AppColors.tertiaryText.adaptTo(context) : null),
                softWrap: true,
                maxLines: 2,
                overflow: .ellipsis,
              ),
            ),
            if (isTest && assignment.content.isNotEmpty)
              Text(assignment.content, style: AppStyles.subheadline(context), softWrap: true, maxLines: 3, overflow: .ellipsis),
            if (details.isNotEmpty)
              Padding(
                padding: const .only(top: 2),
                child: Row(
                  spacing: AppSpacing.s - 2,
                  children: [
                    if (subject != null) SubjectBadge(subject: subject, size: 16),
                    Expanded(
                      child: Text(details, maxLines: 1, overflow: .ellipsis, style: AppStyles.footnote(context)),
                    ),
                  ],
                ),
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
                child: Text(assignment.displayTitle, style: AppStyles.strongText(context), softWrap: true, maxLines: 2, overflow: .ellipsis),
              ),
            ],
          ),
          if (assignment.type == AssignmentType.test && assignment.content.isNotEmpty)
            Text(assignment.content, style: AppStyles.subheadline(context), softWrap: true, maxLines: 3, overflow: .ellipsis),
          Text(
            [formatDate(assignment.dueDate), if (author != null && author.isNotEmpty) AppStrings.sharedBy(Account.getDefaultDisplayName(author))].join(" · "),
            style: AppStyles.footnote(context),
          ),
        ],
      ),
    );
  }
}
