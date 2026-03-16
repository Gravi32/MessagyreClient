import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
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
  late bool addingToGradesPage = editMode ? widget.toEdit!.referenceId != null : true;
  late bool editsCalendar = editMode ? widget.toEdit!.calendarEventId != null : true; // miscBox.get("EditsCalendar", defaultValue: true);

  bool isMissingTitle = false;
  bool isMissingContent = false;
  bool isMissingSubject = false;

  final targetCalendar = ValueNotifier<Calendar?>(null);

  void confirmAssignment() async {
    final assignment = widget.toEdit ?? Assignment();

    assignment
      ..subject.value = subject
      ..title = titleController.text.isEmpty ? null : titleController.text.trim()
      ..content = mode == AssignmentType.leave && contentController.text.trim().isEmpty ? "Congé sans titre" : contentController.text.trim()
      ..dueDate = dueDate
      ..type = mode
      ..referenceId = addingToGradesPage ? assignment.referenceId ?? const Uuid().v4() : null
      ..calendarEventId = editsCalendar ? assignment.calendarEventId : null;

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

    if (!mounted) return;
    Navigator.of(context).pop();
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

  //(subject != null && subject != Subject.NotSet) && ((isTest || isGraded) ? titleController.text.isNotEmpty : contentController.text.isNotEmpty);

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
          title: Text("Informations manquantes"),
          content: CustomText("Vous n'oubliez pas quelque chose ?\nPour créer ce devoir entrez ${missingInfos.join(" et ")} !", textAlign: TextAlign.center),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
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
            padding: EdgeInsets.symmetric(horizontal: 10),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  "Nouveau ${mode == AssignmentType.assignment
                      ? "devoir"
                      : mode == AssignmentType.test
                      ? "test"
                      : "congé"}",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                ),
              ),

              // Mode Switcher
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
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "Merci de remplir les champs obligatoires *",
                            style: TextStyle(fontSize: 14, color: canSubmitNotifier.value ? AppColors.secondaryText.adaptTo(context) : AppColors.yellow),
                          ),
                        ),
                children: [
                  // Title Tile
                  if (mode == AssignmentType.test)
                    CupertinoListTile.notched(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedSubtitle),

                      title: CupertinoTextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
                        decoration: BoxDecoration(),
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
                              ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                              : Opacity(
                                opacity: .5,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                              ),
                    ),

                  // Description Tile
                  CupertinoListTile.notched(
                    backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),

                    title: CupertinoTextField(
                      controller: contentController,
                      focusNode: contentFocusNode,
                      decoration: BoxDecoration(),
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
                            ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                            : Opacity(
                              opacity: .5,
                              child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                            ),
                  ),

                  // Subject Tile
                  if (mode != AssignmentType.leave)
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      onTap: () => subjectFocusNode.requestFocus(),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedBookBookmark02),
                      trailing:
                          isMissingSubject
                              ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                              : Opacity(
                                opacity: .5,
                                child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                              ),
                      title: SubjectAutocomplete(
                        controller: subjectController,
                        focusNode: subjectFocusNode,
                        decoration: BoxDecoration(),
                        padding: EdgeInsets.zero,
                        placeholder: "Entrez une branche *",
                        placeholderStyle: isMissingSubject ? TextStyle(color: AppColors.red) : null,
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
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory),
                    trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: AppColors.secondaryText.adaptTo(context)),
                    title: Text("Pour ${formatDate(dueDate, includeArticle: true)}", style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: showDatePicker,
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                backgroundColor: AppColors.transparent,
                header: const Text("Autres"),

                margin: EdgeInsets.zero,
                children: [
                  if (mode == AssignmentType.test)
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge04),
                      title: Text("Ajouter à la page des notes", style: TextStyle(color: AppColors.text.adaptTo(context))),
                      trailing: CupertinoSwitch(value: addingToGradesPage, onChanged: (value) => setState(() => addingToGradesPage = value)),
                    ),
                  ValueListenableBuilder(
                    valueListenable: targetCalendar,
                    builder:
                        (context, newTargetCalendar, _) => CupertinoListTile(
                          backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                          leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendarAdd01),
                          title: Text("${editMode ? "Syncroniser avec le" : "Ajouter au"} calendrier du téléphone"),
                          trailing: CupertinoSwitch(
                            value: editsCalendar,
                            onChanged:
                                (value) => setState(() {
                                  editsCalendar = value;
                                  // miscBox.put("EditsCalendar", value);
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
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: AppColors.red),
                      title: Text("Supprimer ${mode == AssignmentType.test ? "ce test" : "cette note"}", style: TextStyle(color: AppColors.red)),
                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (_) => CupertinoAlertDialog(
                                title: Text("Supprimer ce ${mode == AssignmentType.test ? "test" : "note"}"),
                                content: Text("Êtes-vous sûr de vouloir supprimer ${mode == AssignmentType.test ? "ce test" : "cette note"} ?"),
                                actions: [
                                  CupertinoDialogAction(child: Text("Annuler"), onPressed: () => Navigator.pop(context)),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: Text("Supprimer"),
                                    onPressed: () {
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
