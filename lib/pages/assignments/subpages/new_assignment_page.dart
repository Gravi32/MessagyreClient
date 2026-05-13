import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/assignments/subpages/notification_date_picker.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/segmented_control.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';
import 'package:uuid/uuid.dart';

class NewAssignmentPage extends StatefulWidget {
  final Assignment? toEdit;
  final DateTime? dueDateOverride;

  const NewAssignmentPage({super.key, this.toEdit, this.dueDateOverride});

  @override
  State<StatefulWidget> createState() => _NewAssignmentPageState();
}

class _NewAssignmentPageState extends State<NewAssignmentPage> {
  final globals = GlobalsService();
  final database = DatabaseService();
  final notifications = NotificationsService();

  late final editMode = widget.toEdit != null;

  late final subjectController = TextEditingController(text: subject?.name);
  late final titleController = TextEditingController(text: widget.toEdit?.title);
  late final contentController = TextEditingController(text: widget.toEdit?.content);
  late final ValueNotifier<bool> canSubmitNotifier;

  final notificationDayOptions = {
    30: "1 mois avant",
    7: "1 semaine avant",
    3: "3 jours avant",
    2: "2 jours avant",
    1: "1 jour avant",
    0: "Le jour même",
    -1: "Jamais",
  };

  final subjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();
  final contentFocusNode = FocusNode();

  late AssignmentType mode = widget.toEdit?.type ?? AssignmentType.assignment;
  late Subject? subject = widget.toEdit?.subject.value;
  late DateTime dueDate = widget.toEdit?.dueDate.dateOnly() ?? widget.dueDateOverride?.dateOnly() ?? DateTime.now().add(const Duration(days: 2)).dateOnly();
  late DateTime? notificationDate =
      widget.toEdit?.notificationDate ??
      (editMode
          ? null
          : (globals.persistent.getBool("ScheduleAssignmentNotificationsByDefault") ?? true ? dueDate.add(const Duration(days: -1)).copyWith(hour: 17) : null));

  late bool addingToGradesPage = editMode ? widget.toEdit!.referenceId != null : true;

  bool isMissingTitle = false;
  bool isMissingContent = false;
  bool isMissingSubject = false;

  bool get isNotificationPossible => dueDate.difference(DateTime.now()).inDays >= 0;

  String formatAssignmentType(AssignmentType type) {
    return switch (type) {
      AssignmentType.assignment => "devoir",
      AssignmentType.test => "test",
      AssignmentType.leave => "congé",
    };
  }

  void confirmAssignment() async {
    final assignment = widget.toEdit ?? Assignment();
    final effectiveReferenceId = assignment.referenceId ?? const Uuid().v4();

    assignment
      ..subject.value = subject
      ..title = titleController.text.isEmpty ? null : titleController.text.trim()
      ..content = mode == AssignmentType.leave && contentController.text.trim().isEmpty ? "Congé sans titre" : contentController.text.trim()
      ..dueDate = dueDate
      ..type = mode
      ..referenceId = addingToGradesPage ? effectiveReferenceId : null
      ..notificationDate = notificationDate;

    if (assignment.referenceId != null) {
      final assignedGrade = database.grades.getByReferenceId(assignment.referenceId!);
      if (assignedGrade != null) {
        assignedGrade.subject.value = assignment.subject.value;
        await database.grades.save(assignedGrade);
      }
    }

    await database.assignments.save(assignment);

    final stableId = effectiveReferenceId.hashCode.remainder(100000);

    if (notificationDate != null && notificationDate?.isAfter(DateTime.now()) == true) {
      await notifications.scheduleAssignmentNotification(
        notificationId: stableId,
        title: "📅 Rappel",
        subtitle:
            assignment.title ??
            "${formatAssignmentType(assignment.type).capitalize()} ${assignment.subject.value?.name.withPreposition(lowercase: true) ?? ""} à venir !",
        body: (assignment.type == AssignmentType.assignment ? assignment.content : formatDate(assignment.dueDate, includeArticle: true)).capitalize(),
        dueDate: notificationDate!,
      );
    } else {
      await notifications.cancel(stableId);
    }

    await globals.persistent.setBool("ScheduleAssignmentNotificationsByDefault", notificationDate != null);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void showDatePicker() {
    final pins = <DateTime, List<Color>>{};
    for (var assignment in database.assignments.getAll()) {
      final date = assignment.dueDate.dateOnly();
      (pins[date] ??= []).add(assignment.subject.value?.color ?? AppColors.grey);
    }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CustomDatePicker(initialDate: dueDate, onDateSelected: (newDate) => setState(() => dueDate = newDate), pins: pins),
    );
  }

  void showMissingInfoPopup() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        final missingInfos = [];
        if (subject == null) {
          missingInfos.add("la *branche*");
          isMissingSubject = true;
        }
        if (mode == AssignmentType.test && titleController.text.isEmpty) {
          missingInfos.add("un *titre*");
          isMissingTitle = true;
        }
        if (mode == AssignmentType.assignment && contentController.text.isEmpty) {
          missingInfos.add("une *description*");
          isMissingContent = true;
        }

        return Dialog(title: "Informations manquantes", content: "Pour créer ce devoir entrez ${missingInfos.join(" et ")} !");
      },
    );
  }

  void updateMode(AssignmentType? newMode) {
    if (newMode == null) return;
    setState(() {
      mode = newMode;
      isMissingTitle = false;
      isMissingContent = false;
      isMissingSubject = false;
      updateCanSubmit();
    });
  }

  void updateCanSubmit() {
    canSubmitNotifier.value = switch (mode) {
      AssignmentType.assignment => subject != null && contentController.text.isNotEmpty,
      AssignmentType.test => subject != null && titleController.text.isNotEmpty,
      AssignmentType.leave => true,
    };
  }

  @override
  void initState() {
    super.initState();
    canSubmitNotifier = ValueNotifier(false);

    subjectController.addListener(updateCanSubmit);
    titleController.addListener(updateCanSubmit);
    contentController.addListener(updateCanSubmit);

    updateMode(mode);
  }

  @override
  void dispose() {
    subjectController.dispose();
    titleController.dispose();
    contentController.dispose();
    subjectFocusNode.dispose();
    titleFocusNode.dispose();
    contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.form(
        context,
        title:
            "${editMode ? "Modifier le" : "Nouveau"} ${mode == .assignment
                ? "devoir"
                : mode == .test
                ? "test"
                : "congé"}",
        trailing: ValueListenableBuilder<bool>(
          valueListenable: canSubmitNotifier,
          builder: (context, canBeSubmitted, _) =>
              Button.icon(context, icon: HugeIcons.strokeRoundedTick02, onTap: canBeSubmitted ? confirmAssignment : showMissingInfoPopup),
        ),
      ),
      child: ListView(
        children: [
          SegmentedControl<AssignmentType>(options: {"Devoir": .assignment, "Test": .test, "Congé": .leave}, onTap: updateMode, defaultIndex: mode.index),

          const SizedBox(height: 8),

          if (mode == .test)
            Field(
              margin: .only(top: 8),
              controller: titleController,
              focusNode: titleFocusNode,
              placeholder: "Titre ${mode == AssignmentType.test ? "*" : ""}",
              maxLines: 2,
              error: isMissingTitle ? "Entrez un titre" : null,
              onTap: () => setState(() => isMissingTitle = false),
            ),

          Field(
            margin: .only(top: 8),
            controller: contentController,
            focusNode: contentFocusNode,
            placeholder: switch (mode) {
              .assignment => "Ce que vous devez faire... *",
              .test => "Déscription du test...",
              .leave => "Motif, période ou durée du congé...",
            },
            minLines: mode == AssignmentType.test ? 3 : 5,
            maxLines: 10,
            onTap: () => setState(() => isMissingContent = false),
          ),

          ListSection(
            margin: .only(top: 24),
            footer: mode == .leave ? null : "Merci de remplir les champs obligatoires *",
            children: [
              if (mode != AssignmentType.leave)
                ListTile(
                  onTap: () => subjectFocusNode.requestFocus(),
                  leading: const CustomIcon(icon: HugeIcons.strokeRoundedBookBookmark02),
                  trailing: isMissingSubject ? const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18) : null,

                  child: SubjectAutocomplete(
                    controller: subjectController,
                    focusNode: subjectFocusNode,
                    decoration: const BoxDecoration(),
                    padding: .zero,
                    placeholder: "Entrez une branche *",
                    placeholderStyle: isMissingSubject ? const TextStyle(color: AppColors.red) : null,
                    onSubjectSelected: (selectedSubject) {
                      setState(() {
                        subject = selectedSubject;
                        isMissingSubject = false;
                      });
                      updateCanSubmit();
                    },
                    forceValid: true,
                  ),
                ),

              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedWorkHistory,
                trailing: Row(
                  mainAxisSize: .min,
                  children: [Text(formatDate(dueDate, includeArticle: true), style: TextStyle(color: AppColors.secondaryText.adaptTo(context)))],
                ),
                title: switch (mode) {
                  .assignment => "Délai du devoir",
                  .test => "Date du test",
                  .leave => "Date du congé",
                },
                onTap: showDatePicker,
              ),
            ],
          ),

          ListSection(
            margin: .only(top: 24),
            footer: isNotificationPossible ? null : "Ce devoir est situé dans le passé",
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedNotification01,
                title: notificationDate == null ? "Planifier une alerte" : "Alerte",

                onTap: () => showCupertinoModalPopup(
                  context: context,
                  builder: (context) => NotificationDatePicker(
                    notificationDate: notificationDate,
                    dueDate: dueDate,
                    notificationDayOptions: notificationDayOptions,
                    onNotificationDateChanged: (newDate) => setState(() => notificationDate = newDate),
                  ),
                ),
                trailing: isNotificationPossible
                    ? Row(
                        mainAxisSize: .min,
                        children: [
                          Text(
                            notificationDate == null
                                ? "Non"
                                : "${notificationDayOptions[dueDate.dateOnly().difference(notificationDate!.dateOnly()).inDays]}, à ${notificationDate?.hour == 0 && notificationDate?.minute == 0 ? "minuit" : "${notificationDate?.hour.toString().padLeft(2, "0")}h${notificationDate?.minute == 0 ? "" : notificationDate?.minute}"} ",
                            style: TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                          ),
                          CupertinoListTileChevron(),
                        ],
                      )
                    : null,
              ),

              if (mode == AssignmentType.test)
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedCheckmarkBadge04,
                  title: "Suggérer dans la page des notes",
                  trailing: CupertinoSwitch(value: addingToGradesPage, onChanged: (value) => setState(() => addingToGradesPage = value)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (widget.toEdit != null)
            ListSection(
              title: "Supprimer",
              margin: .zero,
              children: [
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedDelete04,
                  title: "Supprimer ce ${formatAssignmentType(mode)}",
                  isDestructive: true,
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => Dialog.confirm(
                        content: "Êtes-vous sûr de vouloir supprimer ce ${formatAssignmentType(mode)} ?",
                        onConfirm: () {
                          if (widget.toEdit?.referenceId != null) {
                            notifications.cancel(widget.toEdit!.referenceId!.hashCode.remainder(100000));
                          }
                          database.assignments.delete(widget.toEdit!);
                          Navigator.of(context).pop(widget.toEdit);
                        },
                        isDestructive: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
