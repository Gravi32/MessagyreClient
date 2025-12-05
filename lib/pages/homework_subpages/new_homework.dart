import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:messagyre_client/utility/widgets/homework_card.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:uuid/uuid.dart';

class NewHomework extends StatefulWidget {
  final Homework? toEdit;
  final DateTime? dueDateOverride;

  const NewHomework({super.key, this.toEdit, this.dueDateOverride});

  @override
  State<StatefulWidget> createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  final data = Data();
  final miscBox = Hive.box("Misc");

  late final editMode = widget.toEdit != null;

  late final subjectController = TextEditingController(text: subject == null ? null : SubjectHelper.toFrench(subject!));
  late final contentController = TextEditingController(text: widget.toEdit?.content);

  final subjectFocusNode = FocusNode();
  final contentFocusNode = FocusNode();

  late Subject? subject = widget.toEdit?.subject;
  late DateTime dueDate = widget.toEdit?.dueDate.dateOnly() ?? widget.dueDateOverride?.dateOnly() ?? DateTime.now().add(const Duration(days: 1)).dateOnly();
  late bool isGraded = widget.toEdit?.isGraded ?? false;
  late bool isTest = widget.toEdit?.isTest ?? false;
  late bool addingToGradesPage = editMode ? widget.toEdit!.referenceId != null : true;
  late bool editsCalendar = editMode ? widget.toEdit!.calendarEventId != null : miscBox.get("EditsCalendar", defaultValue: true);

  final targetCalendar = ValueNotifier<Calendar?>(null);

  void confirmHomework() {
    var homework = widget.toEdit ?? Homework();

    if (subject == null) return;

    homework
      ..subject = subject ?? Subject.NotSet
      ..content = contentController.text.trim()
      ..dueDate = dueDate
      ..isGraded = isGraded
      ..isTest = isTest
      ..referenceId = addingToGradesPage ? Uuid().v4() : null
      ..calendarEventId = editsCalendar == false ? null : widget.toEdit?.calendarEventId;

    Navigator.of(context).pop((homework: homework, editsCalendar: editsCalendar));
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
    contentFocusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();
    subjectController.addListener(() => setState(() {}));
    contentController.addListener(() => setState(() {}));
    data.getTargetCalendar().then((retreivedCalendar) => targetCalendar.value = retreivedCalendar);
  }

  @override
  void dispose() {
    subjectController.dispose();
    contentController.dispose();
    subjectFocusNode.dispose();
    contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewHomework =
        Homework()
          ..subject = subject ?? Subject.NotSet
          ..content = contentController.text.trim()
          ..dueDate = dueDate
          ..isGraded = isGraded
          ..isTest = isTest;

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
            onPressed: contentController.text.isNotEmpty ? confirmHomework : null,
            child: Text(
              editMode ? "Terminé" : "Ajouter",
              style: TextStyle(
                color: contentController.text.isEmpty ? CupertinoColors.secondaryLabel : CupertinoColors.label.resolveFrom(context),
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
              // Preview HomeworkCard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                child: HomeworkCard(
                  homework: previewHomework,
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
                        child: HugeIcon(icon: HugeIcons.strokeRoundedBookBookmark02, color: CupertinoColors.placeholderText.resolveFrom(context)),
                      ),
                      suffix: Opacity(
                        opacity: .25,
                        child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.placeholderText.resolveFrom(context)),
                      ),
                      suffixMode: OverlayVisibilityMode.notEditing,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                      placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w500),
                      onSelected: (selectedSubject) => setState(() => subject = selectedSubject),
                    ),
                    SizedBox(height: 12),
                    CupertinoTextField(
                      controller: contentController,
                      focusNode: contentFocusNode,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                        border: Border.all(width: 0, color: CupertinoColors.separator.resolveFrom(context)),
                      ),
                      placeholder: isTest ? "Nom ou description du test..." : "Ce que je dois faire...",
                      minLines: 5,
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
                    leading: HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                    trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                    title: Text(formatDate(dueDate).capitalize()),
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
                      color: isTest ? CupertinoColors.inactiveGray.resolveFrom(context) : adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white),
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
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedCalendar04, color: adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white)),
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
