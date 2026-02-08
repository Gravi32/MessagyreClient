import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/assignment_card.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:uuid/uuid.dart';

class NewAssignmentPage extends StatefulWidget {
  final Assignment? toEdit;
  final DateTime? dueDateOverride;

  const NewAssignmentPage({super.key, this.toEdit, this.dueDateOverride});

  @override
  State<StatefulWidget> createState() => _NewAssignmentState();
}

class _NewAssignmentState extends State<NewAssignmentPage> {
  final globals = GlobalsService();
  final miscBox = Hive.box("Misc");
  final gradesBox = Hive.box<Grade>("Grades");

  late final editMode = widget.toEdit != null;

  late final subjectController = TextEditingController(text: subject == null ? null : SubjectHelper.toFrench(subject!));
  late final titleController = TextEditingController(text: widget.toEdit?.title);
  late final contentController = TextEditingController(text: widget.toEdit?.content);

  final subjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();
  final contentFocusNode = FocusNode();

  late Subject? subject = widget.toEdit?.subject;
  late DateTime dueDate = widget.toEdit?.dueDate.dateOnly() ?? widget.dueDateOverride?.dateOnly() ?? DateTime.now().add(const Duration(days: 1)).dateOnly();
  late bool isGraded = widget.toEdit?.isGraded ?? false;
  late bool isTest = widget.toEdit?.isTest ?? false;
  late bool addingToGradesPage = editMode ? widget.toEdit!.referenceId != null : true;
  late bool editsCalendar = editMode ? widget.toEdit!.calendarEventId != null : miscBox.get("EditsCalendar", defaultValue: true);

  final targetCalendar = ValueNotifier<Calendar?>(null);

  void confirmAssignment() {
    var assignment = widget.toEdit ?? Assignment();

    if (subject == null) return;

    assignment
      ..subject = subject ?? Subject.NotSet
      ..title = titleController.text.isEmpty ? null : titleController.text.trim()
      ..content = contentController.text.trim()
      ..dueDate = dueDate
      ..isGraded = isGraded
      ..isTest = isTest
      ..referenceId = addingToGradesPage ? widget.toEdit?.referenceId ?? Uuid().v4() : null
      ..calendarEventId = editsCalendar == false ? null : widget.toEdit?.calendarEventId;



    Navigator.of(context).pop((assignment: assignment, editsCalendar: editsCalendar));
  }

  void showSubjectPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => CustomSubjectPicker(
            onSubjectSelected: (selectedSubject) {
              setState(() => subject = selectedSubject);
            },
          ),
    );
  }

  void showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CustomDatePicker(initialDate: dueDate, onDateSelected: (newDate) => setState(() => dueDate = newDate)),
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
        final missingInfos = [
          if (subject == null || subject == Subject.NotSet) "la *branche*",
          if ((isTest || isGraded) && titleController.text.isEmpty) "un *titre*",
          if (!(isTest || isGraded) && contentController.text.isEmpty) "une *description*",
        ];

        return CupertinoAlertDialog(
          title: Text("Informations manquantes"),
          content: CustomText("Vous n'oubliez pas quelque chose ?\nPour créer ce devoir entrez ${missingInfos.join(" et ")} !", textAlign: TextAlign.center),
          actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(dialogContext))],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    subjectController.addListener(() => setState(() {}));
    titleController.addListener(() => setState(() {}));
    contentController.addListener(() => setState(() {}));
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
    final previewAssignment =
        Assignment()
          ..subject = subject ?? Subject.NotSet
          ..title = titleController.text.isEmpty ? null : titleController.text.trim()
          ..content = contentController.text.trim()
          ..dueDate = dueDate
          ..isGraded = isGraded
          ..isTest = isTest;

    final canBeSubmitted =
        (subject != null && subject != Subject.NotSet) && ((isTest || isGraded) ? titleController.text.isNotEmpty : contentController.text.isNotEmpty);

    return GestureDetector(
      onTap: unfocusFields,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Annuler", style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: canBeSubmitted ? confirmAssignment : showMissingInfoPopup,
            child: Text(
              editMode ? "Terminé" : "Ajouter",
              style: TextStyle(
                color: canBeSubmitted ? CupertinoColors.label.resolveFrom(context) : CupertinoColors.inactiveGray.resolveFrom(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        child: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              // Preview AssignmentCard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                child: AssignmentCard(
                  assignment: previewAssignment,
                  isPreview: true,
                  onCardTap: () {
                    if (subjectFocusNode.hasFocus || contentFocusNode.hasFocus) {
                      unfocusFields();
                    } else {
                      subjectController.text.isEmpty ? subjectFocusNode.requestFocus() : contentFocusNode.requestFocus();
                    }
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SubjectAutocomplete(
                      decoration: const BoxDecoration(),
                      padding: EdgeInsets.zero,
                      controller: subjectController,
                      focusNode: subjectFocusNode,
                      placeholder: "Branche",
                      prefix: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: HugeIcon(icon: HugeIcons.strokeRoundedBookBookmark02, color: CupertinoColors.label.resolveFrom(context)),
                      ),
                      suffix: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.placeholderText.resolveFrom(context)),
                      suffixMode: OverlayVisibilityMode.notEditing,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                      placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w500),
                      onSelected: (selectedSubject) => setState(() => subject = selectedSubject),
                    ),
                    SizedBox(height: 12),
                    if (isTest || isGraded) ...[
                      CupertinoTextField(
                        controller: titleController,
                        focusNode: titleFocusNode,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(width: 0, color: CupertinoColors.separator.resolveFrom(context)),
                        ),
                        placeholder: "Titre",
                        minLines: 1,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                        placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w400),
                        onTapOutside: (event) => titleFocusNode.unfocus(),
                      ),
                      SizedBox(height: 6),
                    ],
                    CupertinoTextField(
                      controller: contentController,
                      focusNode: contentFocusNode,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        border: Border.all(width: 0, color: CupertinoColors.separator.resolveFrom(context)),
                      ),
                      placeholder: isTest ? "Description du test..." : "Ce que je dois faire...",
                      minLines: isTest ? 4 : 5,
                      maxLines: 10,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                      placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w400),
                      onTapOutside: (event) => contentFocusNode.unfocus(),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 6),
                      child: Text(
                        "Écrivez les mots entre astérisques pour les mettre en gras",
                        style: TextStyle(color: CupertinoColors.quaternaryLabel.resolveFrom(context), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              CupertinoListSection.insetGrouped(
                header: const Text("Date de remise"),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  CupertinoListTile(
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, color: CupertinoColors.label.resolveFrom(context)),
                    trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                    title: Text("Pour ${formatDate(dueDate)}"),
                    onTap: showDatePicker,
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                header: const Text("Évaluation"),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  CupertinoListTile(
                    leading: HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkBadge04,
                      color: (isTest ? CupertinoColors.inactiveGray : CupertinoColors.label).resolveFrom(context),
                    ),
                    title: Text(
                      "Devoir noté",
                      style: TextStyle(color: isTest ? CupertinoColors.inactiveGray.resolveFrom(context) : CupertinoColors.label.resolveFrom(context)),
                    ),
                    trailing: CupertinoSwitch(value: isGraded, onChanged: isTest ? null : (value) => setState(() => isGraded = value)),
                  ),
                  CupertinoListTile(
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedTextCheck, color: CupertinoColors.label.resolveFrom(context)),
                    title: const Text("Test"),
                    trailing: CupertinoSwitch(
                      value: isTest,
                      onChanged:
                          (value) => setState(() {
                            isTest = value;
                            isGraded = false;
                          }),
                    ),
                  ),
                ],
              ),

              if (isGraded || isTest)
                CupertinoListSection.insetGrouped(
                  margin: const EdgeInsets.symmetric(horizontal: 10).add(EdgeInsetsGeometry.only(top: 10)),
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, color: CupertinoColors.label.resolveFrom(context)),
                      title: Text("Ajouter à la page des notes", style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
                      trailing: CupertinoSwitch(value: addingToGradesPage, onChanged: (value) => setState(() => addingToGradesPage = value)),
                    ),
                  ],
                ),

              ValueListenableBuilder(
                valueListenable: targetCalendar,
                builder:
                    (context, newTargetCalendar, _) => CupertinoListSection.insetGrouped(
                      header: const Text("Autres"),
                      footer:
                          editsCalendar && !editMode
                              ? Padding(
                                padding: EdgeInsetsGeometry.only(top: 6),
                                child: Text(
                                  "Un événement sera créé sur ${newTargetCalendar == null ? "votre calendrier prédefini." : "\"${newTargetCalendar.name}\"."} Vous pouvez changer de calendrier dans les réglages de votre dispositif.",
                                  style: TextStyle(color: CupertinoColors.tertiaryLabel.resolveFrom(context), fontSize: 16),
                                ),
                              )
                              : null,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        CupertinoListTile(
                          leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendarAdd01, color: CupertinoColors.label.resolveFrom(context)),
                          title: Text("${editMode ? "Syncroniser avec le" : "Ajouter au"} calendrier du téléphone"),
                          trailing: CupertinoSwitch(
                            value: editsCalendar,
                            onChanged:
                                (value) => setState(() {
                                  editsCalendar = value;
                                  miscBox.put("EditsCalendar", value);
                                }),
                          ),
                        ),
                      ],
                    ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
