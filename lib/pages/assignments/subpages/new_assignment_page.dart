import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
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
  final calendar = DeviceCalendarPlugin();
  final notifications = NotificationsService();

  late final editMode = widget.toEdit != null;

  late final subjectController = TextEditingController(text: subject?.name);
  late final titleController = TextEditingController(text: widget.toEdit?.title);
  late final contentController = TextEditingController(text: widget.toEdit?.content);
  late final ValueNotifier<bool> canSubmitNotifier;

  final subjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();
  final contentFocusNode = FocusNode();

  late AssignmentType mode = widget.toEdit?.type ?? AssignmentType.assignment;

  late Subject? subject = widget.toEdit?.subject.value;
  late DateTime dueDate = widget.toEdit?.dueDate.dateOnly() ?? widget.dueDateOverride?.dateOnly() ?? DateTime.now().add(const Duration(days: 1)).dateOnly();
  late int? notificationId = widget.toEdit?.notificationId;

  int daysBefore = 1;
  DateTime notificationTime = DateTime(2026, 1, 1, 17, 0);

  late bool addingToGradesPage = editMode ? widget.toEdit!.referenceId != null : true;
  late bool editsCalendar = editMode ? widget.toEdit!.calendarEventId != null : globals.persistent.getBool("EditsCalendar") ?? false;

  bool isMissingTitle = false;
  bool isMissingContent = false;
  bool isMissingSubject = false;

  final targetCalendar = ValueNotifier<Calendar?>(null);

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
      ..calendarEventId = editsCalendar ? assignment.calendarEventId : null
      ..notificationId = notificationId;

    if (assignment.referenceId != null) {
      final assignedGrade = database.grades.getByReferenceId(assignment.referenceId!);
      if (assignedGrade != null) {
        assignedGrade.subject.value = assignment.subject.value;
        await database.grades.save(assignedGrade);
      }
    }

    if (editsCalendar) {
      final permissionResult = await calendar.hasPermissions();
      if (!permissionResult.isSuccess || permissionResult.data != true) {
        final requestResult = await calendar.requestPermissions();
        if (!requestResult.isSuccess || requestResult.data != true) return;
      }

      final timeZone = getLocation("Europe/Zurich");

      final event = Event(
        targetCalendar.value!.id,
        eventId: assignment.calendarEventId,
        title: "Devoir ${assignment.subject.value?.name.withPreposition(lowercase: true)}",
        start: TZDateTime.from(assignment.dueDate, timeZone),
        end: TZDateTime.from(assignment.dueDate.add(const Duration(minutes: 45)), timeZone),
        allDay: true,
        description: assignment.content,
      );

      final result = await calendar.createOrUpdateEvent(event);
      assignment.calendarEventId = result?.data ?? assignment.calendarEventId;
    }

    await database.assignments.save(assignment);

    final stableId = effectiveReferenceId.hashCode.remainder(100000);

    try {
      if (notificationId != null) {
        final scheduledDate = dueDate.subtract(Duration(days: daysBefore)).copyWith(hour: notificationTime.hour, minute: notificationTime.minute);

        final targetForService = scheduledDate.add(const Duration(days: 1));

        await notifications.scheduleAssignmentNotification(
          notificationId: stableId,
          title: assignment.title ?? "Devoir ${assignment.subject.value?.name.withPreposition(lowercase: true) ?? 'sans titre'}",
          body: assignment.content,
          dueDate: targetForService,
        );
      } else {
        await notifications.cancel(stableId);
      }
    } catch (e) {
      debugPrint("Notification Error: $e");
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void showNotificationOptionsPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 300,
            color: AppColors.tertiaryBackground.adaptTo(context),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(child: const Text("OK", style: TextStyle(fontWeight: FontWeight.w600)), onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(initialItem: daysBefore),
                          onSelectedItemChanged: (int index) => setState(() => daysBefore = index),
                          children: List<Widget>.generate(8, (int index) {
                            return Center(
                              child: Text(
                                index == 0
                                    ? "Le jour même"
                                    : index == 1
                                    ? "1 jour avant"
                                    : "$index jours avant",
                                style: TextStyle(fontSize: 18, color: AppColors.text.adaptTo(context)),
                              ),
                            );
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: true,
                          initialDateTime: notificationTime,
                          onDateTimeChanged: (DateTime newTime) {
                            setState(() => notificationTime = newTime);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void showSubjectPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => CustomSubjectPicker(
            onSubjectSelected: (selectedSubject) {
              setState(() => subject = selectedSubject as Subject);
            },
          ),
    );
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

  void unfocusFields() {
    subjectFocusNode.unfocus();
    titleFocusNode.unfocus();
    contentFocusNode.unfocus();
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

        return CupertinoAlertDialog(
          title: const Text("Informations manquantes"),
          content: CustomText("Vous n'oubliez pas quelque chose ?\nPour créer ce devoir entrez ${missingInfos.join(" et ")} !", textAlign: TextAlign.center),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {});
              },
            ),
          ],
        );
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

    globals.getTargetCalendar().then((retreivedCalendar) => targetCalendar.value = retreivedCalendar);
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
    return GestureDetector(
      onTap: unfocusFields,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.transparent,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Annuler", style: TextStyle(color: AppColors.text.adaptTo(context))),
          ),
          trailing: ValueListenableBuilder<bool>(
            valueListenable: canSubmitNotifier,
            builder:
                (context, canBeSubmitted, _) => CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: canBeSubmitted ? confirmAssignment : showMissingInfoPopup,
                  child: Text(
                    editMode ? "Terminé" : "Ajouter",
                    style: TextStyle(
                      color: canBeSubmitted ? AppColors.text.adaptTo(context) : AppColors.inactive.adaptTo(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
          ),
        ),
        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
        child: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  "Nouveau ${mode == AssignmentType.assignment
                      ? "devoir"
                      : mode == AssignmentType.test
                      ? "test"
                      : "congé"}",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
              ),

              CupertinoSlidingSegmentedControl<AssignmentType>(
                groupValue: mode,
                backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                thumbColor: adaptiveColor(AppColors.background.adaptTo(context), AppColors.text.adaptTo(context).withAlpha(20)),
                children: const {
                  AssignmentType.assignment: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text("Devoir", style: TextStyle(fontSize: 16)),
                  ),
                  AssignmentType.test: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Text("Test", style: TextStyle(fontSize: 16))),
                  AssignmentType.leave: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text("Congé", style: TextStyle(fontSize: 16)),
                  ),
                },
                onValueChanged: updateMode,
              ),

              CupertinoListSection.insetGrouped(
                backgroundColor: AppColors.transparent,
                header: const SizedBox(),
                margin: EdgeInsets.zero,
                footer:
                    mode == AssignmentType.leave
                        ? null
                        : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Merci de remplir les champs obligatoires *",
                            style: TextStyle(fontSize: 14, color: canSubmitNotifier.value ? AppColors.secondaryText.adaptTo(context) : AppColors.yellow),
                          ),
                        ),
                children: [
                  if (mode == AssignmentType.test)
                    CupertinoListTile.notched(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: const HugeIcon(icon: HugeIcons.strokeRoundedSubtitle),

                      title: CupertinoTextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
                        decoration: const BoxDecoration(),
                        placeholder: "Titre ${mode == AssignmentType.test ? "*" : ""}",
                        minLines: 1,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                        placeholderStyle: TextStyle(
                          color: isMissingTitle ? AppColors.red : AppColors.placeholderText.adaptTo(context),
                          fontWeight: FontWeight.w400,
                        ),
                        onTap: () => setState(() => isMissingTitle = false),
                        onTapOutside: (event) => titleFocusNode.unfocus(),
                      ),
                      trailing:
                          isMissingTitle
                              ? const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                              : Opacity(
                                opacity: .5,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                              ),
                    ),

                  CupertinoListTile.notched(
                    backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

                    title: CupertinoTextField(
                      controller: contentController,
                      focusNode: contentFocusNode,
                      decoration: const BoxDecoration(),
                      placeholder: switch (mode) {
                        AssignmentType.assignment => "Ce que vous devez faire... *",
                        AssignmentType.test => "Si vous voulez, entrez une déscription du test...",
                        AssignmentType.leave => "Motif, période ou durée du congé...",
                      },
                      minLines: mode == AssignmentType.test ? 4 : 5,
                      maxLines: 10,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                      placeholderStyle: TextStyle(
                        color: isMissingContent ? AppColors.red : AppColors.placeholderText.adaptTo(context),
                        fontWeight: FontWeight.w400,
                      ),
                      onTap: () => setState(() => isMissingContent = false),
                      onTapOutside: (event) => contentFocusNode.unfocus(),
                    ),
                    trailing:
                        isMissingContent
                            ? const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                            : Opacity(
                              opacity: .5,
                              child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                            ),
                  ),

                  if (mode != AssignmentType.leave)
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      onTap: () => subjectFocusNode.requestFocus(),
                      leading: const HugeIcon(icon: HugeIcons.strokeRoundedBookBookmark02),
                      trailing:
                          isMissingSubject
                              ? const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                              : Opacity(
                                opacity: .5,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                              ),
                      title: SubjectAutocomplete(
                        controller: subjectController,
                        focusNode: subjectFocusNode,
                        decoration: const BoxDecoration(),
                        padding: EdgeInsets.zero,
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
                ],
              ),

              CupertinoListSection.insetGrouped(
                backgroundColor: AppColors.transparent,
                header: Text("Date ${mode == AssignmentType.leave ? "" : "de remise"}"),
                margin: EdgeInsets.zero,
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    leading: const HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory),
                    trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.secondaryText.adaptTo(context)),
                    title: Text("Pour ${formatDate(dueDate, includeArticle: true)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: showDatePicker,
                  ),
                ],
              ),

              if (dueDate.difference(DateTime.now()).inDays >= 0)
                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.transparent,
                  header: const Text("Rappels"),
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: const HugeIcon(icon: HugeIcons.strokeRoundedNotification01),
                      title: Text("Envoyer une notification", style: TextStyle(color: AppColors.text.adaptTo(context))),
                      trailing: CupertinoSwitch(
                        value: notificationId != null,
                        onChanged: (value) {
                          setState(() {
                            notificationId = value ? 1 : null;
                          });
                        },
                      ),
                    ),
                    if (notificationId != null)
                      CupertinoListTile(
                        backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                        leading: const SizedBox(width: 24),
                        title: Text("M'avertir", style: TextStyle(color: AppColors.text.adaptTo(context))),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${daysBefore == 0
                                  ? "Le jour même"
                                  : daysBefore == 1
                                  ? "1 jour avant"
                                  : "$daysBefore jours avant"} à ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}",
                              style: TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                            ),
                            const SizedBox(width: 6),
                            HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.secondaryText.adaptTo(context), size: 18),
                          ],
                        ),
                        onTap: showNotificationOptionsPicker,
                      ),
                  ],
                ),

              CupertinoListSection.insetGrouped(
                backgroundColor: AppColors.transparent,
                margin: EdgeInsets.zero,
                children: [
                  if (mode == AssignmentType.test)
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge04),
                      title: Text("Suggérer dans la page des notes", style: TextStyle(color: AppColors.text.adaptTo(context))),
                      trailing: CupertinoSwitch(value: addingToGradesPage, onChanged: (value) => setState(() => addingToGradesPage = value)),
                    ),

                  ValueListenableBuilder(
                    valueListenable: targetCalendar,
                    builder:
                        (context, newTargetCalendar, _) => CupertinoListTile(
                          backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                          leading: const HugeIcon(icon: HugeIcons.strokeRoundedCalendarAdd01),
                          title: Text("${editMode ? "Syncroniser avec le" : "Ajouter au"} calendrier du téléphone"),
                          trailing: CupertinoSwitch(
                            value: editsCalendar,
                            onChanged:
                                (value) => setState(() {
                                  editsCalendar = value;
                                }),
                          ),
                          subtitle: Text(
                            newTargetCalendar == null ? "votre calendrier prédefini." : "Calendrier: ${newTargetCalendar.name}",
                            style: TextStyle(color: AppColors.tertiaryText.adaptTo(context), fontSize: 16),
                          ),
                        ),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                backgroundColor: AppColors.transparent,
                header: const SizedBox.shrink(),
                margin: EdgeInsets.zero,
                children: [
                  if (widget.toEdit != null)
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: const HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: AppColors.red),
                      title: Text("Supprimer ${mode == AssignmentType.test ? "ce test" : "cette note"}", style: const TextStyle(color: AppColors.red)),
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (_) => CupertinoAlertDialog(
                                title: Text("Supprimer ce ${mode == AssignmentType.test ? "test" : "note"}"),
                                content: Text("Êtes-vous sûr de vouloir supprimer ${mode == AssignmentType.test ? "ce test" : "cette note"} ?"),
                                actions: [
                                  CupertinoDialogAction(child: const Text("Annuler"), onPressed: () => Navigator.pop(context)),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text("Supprimer"),
                                    onPressed: () {
                                      if (widget.toEdit?.referenceId != null) {
                                        notifications.cancel(widget.toEdit!.referenceId!.hashCode.remainder(100000));
                                      }
                                      database.assignments.delete(widget.toEdit!);
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop(widget.toEdit);
                                    },
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
