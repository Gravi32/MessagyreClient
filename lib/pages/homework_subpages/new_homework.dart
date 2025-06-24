import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:settings_ui/settings_ui.dart';

class NewHomework extends StatefulWidget {
  const NewHomework({super.key});

  @override
  State<StatefulWidget> createState() => _NewHomeworkState();
}

class _NewHomeworkState extends State<NewHomework> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  Subject subject = Subject.Maths;
  DateTime dueDate = DateTime.now().add(Duration(days: 1));
  bool isGraded = false;

  void createHomework() {
    var newHomework = Homework();

    newHomework
      ..title = titleController.text
      ..subject = subject
      ..dueDate = dueDate
      ..isGraded = isGraded
      ..description = descriptionController.text;

    Navigator.of(context).pop(newHomework);
  }

  void showSubjectPicker() {
    final controller = FixedExtentScrollController(initialItem: subject.index);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: CupertinoPicker.builder(
              itemExtent: 60,
              childCount: Subject.values.length,
              scrollController: controller,
              onSelectedItemChanged:
                  (value) => setState(() {
                    subject = Subject.values[value];
                  }),
              itemBuilder: (context, index) {
                return Center(
                  child: Text(SubjectHelper.toFrench(Subject.values[index])),
                );
              },
            ),
          ),
    );
  }

  void showDatePicker() {
    final now = DateTime.now();

    final endSchoolYear = now.month >= 9 ? now.year + 1 : now.year;
    final schoolEndDate = DateTime(endSchoolYear, 6, 6);

    DateTime initial = dueDate;

    if (initial.isBefore(now)) {
      initial = now;
    } else if (initial.isAfter(schoolEndDate)) {
      initial = schoolEndDate;
    }

    if (now.isAfter(schoolEndDate)) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: Text("Année scolaire terminée"),
              content: Text(
                "Ce n'est plus possible d'ajouter de devoirs pour cette année scolaire.",
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text("OK"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 250,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              minimumDate: now,
              maximumDate: schoolEndDate,
              minimumYear: now.year,
              maximumYear: schoolEndDate.year,
              onDateTimeChanged: (value) => setState(() => dueDate = value),
            ),
          ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: Navigator.of(context).pop,
          child: Text("Annuler"),
        ),
        middle: Text("Nouveau devoir"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: createHomework,
          child: Text("Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),

      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Text("Informations principales"),
              tiles: [
                SettingsTile(
                  leading: Icon(CupertinoIcons.textformat),
                  title: CupertinoTextField(
                    controller: titleController,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.zero,
                    placeholder: "Titre",
                  ),
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
    );
  }
}
