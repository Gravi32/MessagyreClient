import 'package:messagyre_client/utility/widgets/app_icon.dart';
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
import 'package:messagyre_client/database/models/assignments/assignment_share.dart';
import 'package:messagyre_client/pages/assignments/subpages/edit_shared_assignment_sheet.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/widgets/basics/action_sheet.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
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
                  child: const AppIcon(icon: AppIcons.done, color: AppColors.white, size: 16, strokeWidth: 2.5),
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
              child: AppIcon(
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

/// An assignment shared by a classmate. Touching it adds it to mine; its author and the class's delegates can also
/// change or remove it ([onChanged] then reloads the list).
class SharedAssignmentTile extends ListTile {
  final SharedAssignment assignment;
  final VoidCallback? onChanged;

  const SharedAssignmentTile({super.key, required this.assignment, this.onChanged}) : super(buildChevron: false);

  @override
  State<SharedAssignmentTile> createState() => _SharedAssignmentTileState();
}

class _SharedAssignmentTileState extends State<SharedAssignmentTile> {
  bool isWorking = false;

  AssignmentShare get share => AssignmentShare(
    type: widget.assignment.type,
    title: widget.assignment.title,
    content: widget.assignment.content,
    dueDate: widget.assignment.dueDate.toLocal().dateOnly(),
  );

  /// Already in my assignments (false when the database can't be read, as in the widget tests)
  bool get isAdded {
    try {
      return DatabaseService().assignments.getAll().any(share.isSameAs);
    } catch (_) {
      return false;
    }
  }

  void showError(String message) =>
      showCupertinoDialog(context: context, builder: (_) => Dialog(title: AppStrings.errorTitle, content: message));

  Future<void> showActions() async {
    final choice = await ActionSheet.show<String>(
      context,
      message: widget.assignment.displayTitle,
      actions: [
        if (!isAdded) const SheetAction("Ajouter à mes devoirs", icon: AppIcons.add, value: "add"),
        if (widget.assignment.canEdit) const SheetAction("Modifier", icon: AppIcons.edit, value: "edit"),
        if (widget.assignment.canEdit) const SheetAction("Supprimer pour toute la classe", icon: AppIcons.delete, value: "delete", isDestructive: true),
      ],
    );
    if (!mounted) return;

    switch (choice) {
      case "add":
        await showCupertinoSheet(context: context, builder: (context) => NewAssignmentPage(prefill: share), enableDrag: false);
        if (mounted) setState(() {});
      case "edit":
        final saved = await showCupertinoModalPopup<bool>(context: context, builder: (_) => EditSharedAssignmentSheet(assignment: widget.assignment));
        if (saved == true) widget.onChanged?.call();
      case "delete":
        showCupertinoDialog(
          context: context,
          builder: (_) => Dialog.confirm(
            content: "Supprimer ce devoir partagé ? Il disparaîtra pour toute la classe (ceux qui l'ont ajouté à leurs devoirs le gardent).",
            isDestructive: true,
            onConfirm: remove,
          ),
        );
    }
  }

  Future<void> remove() async {
    setState(() => isWorking = true);
    final response = await NetworkService().post("/shared/assignments/remove", {"ID": widget.assignment.id});
    if (!mounted) return;
    setState(() => isWorking = false);
    if (response.statusCode == 200 || response.statusCode == 404) {
      widget.onChanged?.call();
    } else {
      showError(
        response.statusCode == 403 ? "Seuls son auteur, le délégué et le vice-délégué de la classe peuvent supprimer ce devoir." : AppStrings.errorFor(response),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final tag = assignmentTypeTag(assignment.type);
    final author = assignment.authorUsername;

    return ListTile(
      buildChevron: false,
      isLoading: isWorking,
      onTap: showActions,
      trailing: isAdded ? AppIcon(icon: AppIcons.done, size: 18, color: AppColors.tertiaryText.adaptTo(context)) : null,
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
            [
              formatDate(assignment.dueDate),
              if (author != null && author.isNotEmpty) AppStrings.sharedBy(Account.getDefaultDisplayName(author)),
              if (assignment.editedBy != null && assignment.editedBy != author) "modifié par ${Account.getDefaultDisplayName(assignment.editedBy!)}",
            ].join(" · "),
            style: AppStyles.footnote(context),
          ),
        ],
      ),
    );
  }
}
