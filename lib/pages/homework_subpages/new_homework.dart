import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:messagyre_client/utility/widgets/homework_card.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';

class NewHomework extends StatefulWidget {
  final Homework? toEdit;
  final DateTime? dueDateOverride;

  const NewHomework({super.key, this.toEdit, this.dueDateOverride});

  @override
  State<StatefulWidget> createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  final data = Data();

  late final editMode = widget.toEdit != null;

  late final subjectController = TextEditingController(text: SubjectHelper.toFrench(subject));
  late final contentController = TextEditingController(text: widget.toEdit?.content);

  late Subject subject = widget.toEdit?.subject ?? Subject.Maths;
  late DateTime dueDate = widget.toEdit?.dueDate ?? widget.dueDateOverride ?? DateTime.now().add(Duration(days: 1));
  late bool isGraded = widget.toEdit?.isGraded ?? false;
  late bool isTest = widget.toEdit?.isTest ?? false;

  void confirmHomework() {
    var homework = widget.toEdit ?? Homework();

    homework
      ..subject = subject
      ..content = contentController.text.trim()
      ..dueDate = dueDate
      ..isGraded = isGraded
      ..isTest = isTest;

    Navigator.of(context).pop(homework);
  }

  void showSubjectPicker() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => CustomSubjectPicker(
            initialSubject: subject,
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

  @override
  void initState() {
    super.initState();
    subjectController.addListener(() => setState(() {}));
    contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    subjectController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewHomework =
        Homework()
          ..subject = subject
          ..content = contentController.text.trim()
          ..dueDate = dueDate
          ..isGraded = isGraded
          ..isTest = isTest;

    return CupertinoPageScaffold(
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
          physics: ClampingScrollPhysics(),
          children: [
            // Preview HomeworkCard
            Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 10, vertical: 18), child: HomeworkCard(homework: previewHomework, isPreview: true)),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                spacing: 10,
                children: [
                  SubjectAutocomplete(
                    decoration: const BoxDecoration(),
                    padding: EdgeInsets.zero,
                    placeholder: "Branche",

                    prefix: Padding(
                      padding: EdgeInsetsGeometry.only(right: 10),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedBookBookmark02, color: CupertinoColors.placeholderText.resolveFrom(context)),
                    ),
                    suffix: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.placeholderText.resolveFrom(context)),
                    suffixMode: OverlayVisibilityMode.notEditing,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                    placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w500),

                    onSelected: (selectedSubject) => setState(() => subject = selectedSubject),
                  ),
                  CupertinoTextField(
                    controller: contentController,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      border: BoxBorder.all(width: 0, color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    placeholder: isTest ? "Nom ou description du test..." : "Ce que je dois faire...",
                    minLines: 5,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                    placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),

            CupertinoListSection.insetGrouped(
              header: Text("Date de remise"),
              margin: EdgeInsets.symmetric(horizontal: 10),
              children: [
                CupertinoListTile(
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: CupertinoColors.inactiveGray.resolveFrom(context),),
                  title: Text(formatDate(dueDate).capitalize()),
                  onTap: showDatePicker,
                ),
              ],
            ),

            CupertinoListSection.insetGrouped(
              header: Text("Évaluation"),
              margin: EdgeInsets.symmetric(horizontal: 10),
              children: [
                CupertinoListTile(
                  leading: HugeIcon(icon: 
                    HugeIcons.strokeRoundedCheckmarkBadge04,
                    color: isTest ? CupertinoColors.inactiveGray.resolveFrom(context) : adaptiveColor(CupertinoColors.tertiaryLabel, CupertinoColors.white),
                  ),
                  title: Text(
                    "Devoir noté",
                    style: TextStyle(color: isTest ? CupertinoColors.inactiveGray.resolveFrom(context) : CupertinoColors.label.resolveFrom(context)),
                  ),
                  trailing: CupertinoSwitch(value: isGraded, onChanged: isTest ? null : (value) => setState(() => isGraded = value)),
                ),
                CupertinoListTile(
                  leading: HugeIcon(icon: HugeIcons.strokeRoundedTextCheck,  color: CupertinoColors.label.resolveFrom(context)),
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
          ],
        ),
      ),
    );
  }
}
