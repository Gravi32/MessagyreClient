import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:messagyre_client/utility/widgets/homework_card.dart';
import 'package:settings_ui/settings_ui.dart';

class NewHomework extends StatefulWidget {
  final Homework? toEdit;

  const NewHomework({super.key, this.toEdit});

  @override
  State<StatefulWidget> createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  final data = Data();

  late final editMode = widget.toEdit != null;

  late final titleController = TextEditingController(text: widget.toEdit?.title);
  late final descriptionController = TextEditingController(text: widget.toEdit?.description);

  late Subject subject = widget.toEdit?.subject ?? Subject.Maths;
  late DateTime dueDate = widget.toEdit?.dueDate ?? DateTime.now().add(Duration(days: 1));
  late bool isGraded = widget.toEdit?.isGraded ?? false;
  late bool isTest = widget.toEdit?.isTest ?? false;

  void confirmHomework() {
    var homework = widget.toEdit ?? Homework();

    homework
      ..title = titleController.text
      ..subject = subject
      ..dueDate = dueDate
      ..isGraded = isGraded
      ..isTest = isTest
      ..description = descriptionController.text;

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
    titleController.addListener(() => setState(() {}));
    descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewHomework =
        Homework()
          ..title = titleController.text.isEmpty ? "Titre" : titleController.text
          ..description = descriptionController.text.isEmpty ? "Description" : descriptionController.text
          ..subject = subject
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
          onPressed: titleController.text.isNotEmpty ? confirmHomework : null,
          child: Text(editMode ? "Terminé" : "Ajouter", style: TextStyle(color: titleController.text.isEmpty ? CupertinoColors.secondaryLabel : CupertinoColors.label.resolveFrom(context), fontWeight: FontWeight.w600)),
        ),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: ListView(
          physics: ClampingScrollPhysics(),
          children: [
            // Preview HomeworkCard
            Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 18), child: HomeworkCard(homework: previewHomework, onTap: () {})),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                spacing: 10,
                children: [
                  CupertinoTextField(
                    controller: titleController,
                    decoration: const BoxDecoration(),
                    padding: EdgeInsets.zero,
                    placeholder: "Titre",

                    prefix: Padding(
                      padding: EdgeInsetsGeometry.only(right: 10),
                      child: Icon(CupertinoIcons.textbox, color: CupertinoColors.placeholderText.resolveFrom(context)),
                    ),
                    suffix: Icon(CupertinoIcons.pencil, color: CupertinoColors.placeholderText.resolveFrom(context)),
                    suffixMode: OverlayVisibilityMode.notEditing,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                    placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w500),
                  ),
                  CupertinoTextField(
                    controller: descriptionController,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      border: BoxBorder.all(width: 0, color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    placeholder: "Description",
                    minLines: 5,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                    placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),

            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  // Subject field
                  leading: Icon(CupertinoIcons.book, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  title: Text(SubjectHelper.toFrench(subject)),
                  onTap: showSubjectPicker,
                ),
                CupertinoListTile(
                  // Due date
                  leading: Icon(CupertinoIcons.calendar, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  title: Text(formatDate(dueDate).capitalize()),
                  onTap: showDatePicker,
                ),
                
              ],
            ),

            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  leading: Icon(CupertinoIcons.chart_bar_alt_fill, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                  title: const Text("Devoir noté"),
                  trailing: CupertinoSwitch(value: isGraded, onChanged: (value) => setState(() => isGraded = value)),
                ),
                if(isGraded) CupertinoListTile(
                  leading: Icon(CupertinoIcons.chart_bar_alt_fill, color: CupertinoColors.systemRed.resolveFrom(context)),
                  title: const Text("Test"),
                  trailing: CupertinoSwitch(value: isTest, onChanged: (value) => setState(() => isTest = value)),
                  
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget oldBuild(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: Navigator.of(context).pop, child: Text("Annuler")),
        middle: Text(editMode ? "Modifier le devoir" : "Nouveau devoir"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: titleController.text.isNotEmpty ? confirmHomework : null,
          child: Text(editMode ? "Terminé" : "Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      backgroundColor: CupertinoColors.transparent,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SettingsList(
            platform: DevicePlatform.iOS,
            sections: [
              SettingsSection(
                title: Text("Informations principales"),
                tiles: [
                  SettingsTile(
                    leading: Icon(CupertinoIcons.textformat),
                    title: CupertinoTextField(controller: titleController, decoration: BoxDecoration(), padding: EdgeInsets.zero, placeholder: "Titre"),
                  ),
                  SettingsTile(
                    leading: Icon(CupertinoIcons.book),
                    title: Text("Branche"),
                    value: Text(SubjectHelper.toFrench(subject)),
                    onPressed: (context) => showSubjectPicker(),
                  ),
                  SettingsTile(
                    leading: Icon(CupertinoIcons.calendar),
                    value: Text(formatDate(dueDate).capitalize()),
                    title: Text("Date de remise"),
                    onPressed: (context) => showDatePicker(),
                  ),
                ],
              ),
              SettingsSection(
                title: Text("Autres informations"),
                tiles: [
                  SettingsTile.switchTile(
                    leading: Icon(CupertinoIcons.chart_bar),
                    title: Text("Noté"),
                    initialValue: isGraded,
                    onToggle: (newValue) {
                      setState(() => isGraded = newValue);
                    },
                  ),
                  SettingsTile(
                    leading: Icon(CupertinoIcons.doc_text),
                    title: CupertinoTextField(
                      controller: descriptionController,
                      decoration: BoxDecoration(),
                      padding: EdgeInsets.zero,
                      textAlignVertical: TextAlignVertical.top,
                      minLines: 1,
                      maxLines: 15,
                      placeholder: "Description et liens",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
