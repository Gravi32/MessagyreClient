import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:settings_ui/settings_ui.dart';

class NewGrade extends StatefulWidget {
  final Grade? toEdit;

  const NewGrade({super.key, this.toEdit});

  @override
  State<StatefulWidget> createState() => _NewGradeState();
}

class _NewGradeState extends State<NewGrade> {
  late final editMode = widget.toEdit != null;

  late final titleController = TextEditingController(
    text: widget.toEdit?.title,
  );
  late final detailsController = TextEditingController(
    text: widget.toEdit?.details,
  );

  late Subject subject = widget.toEdit?.subject ?? Subject.Maths;
  late double grade = widget.toEdit?.grade ?? 4;
  late DateTime date = widget.toEdit?.date ?? DateTime.now();
  late double weight = widget.toEdit?.weight ?? 1;

  void confirmGrade() {
    var grade = widget.toEdit ?? Grade();

    grade
      ..title = titleController.text
      ..subject = subject
      ..date = date
      ..details = detailsController.text;

    Navigator.of(context).pop(grade);
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

    DateTime initial = date;

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
              onDateTimeChanged: (value) => setState(() => date = value),
            ),
          ),
    );
  }

  Widget buildGradePicker() {
    final grades = List.generate(11, (i) => i * .5 + 1);
    final controller = FixedExtentScrollController(initialItem: grades.indexOf(grade));

    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotatedBox(
            quarterTurns: -1,
            child: ListWheelScrollView.useDelegate(
              controller: controller,
              itemExtent: 60,
              diameterRatio: 2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged:
                  (index) => setState(() => grade = grades[index]),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: grades.length,
                builder: (context, index) {
                  final thisGrade = grades[index];
                  final isWhole = thisGrade % 1 == 0;
                  final display =
                      isWhole
                          ? thisGrade.toInt().toString()
                          : thisGrade.toStringAsFixed(1);

                  final isSelected = grade == thisGrade;

                  return RotatedBox(
                    quarterTurns: 1,
                    child: Center(
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 22,
                          color:
                              isSelected
                                  ? CupertinoColors.label.resolveFrom(context)
                                  : CupertinoColors.inactiveGray.resolveFrom(
                                    context,
                                  ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: Navigator.of(context).pop,
          child: Text("Annuler"),
        ),
        middle: Text(editMode ? "Modifier la note" : "Nouvelle note"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: titleController.text.isNotEmpty ? confirmGrade : null,
          child: Text(
            editMode ? "Terminé" : "Ajouter",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),

      child: SafeArea(
        child: SettingsList(
          platform: DevicePlatform.iOS,
          sections: [
            SettingsSection(
              title: Column(
                children: [
                  CupertinoTextField(
                    controller: titleController,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.zero,
                    placeholder: "Test de Cryptographie 1",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.placeholderText.resolveFrom(
                        context,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
              tiles: [
                SettingsTile(title: buildGradePicker()),

                SettingsTile(
                  title: Text(
                    "Branche",
                    style: TextStyle(
                      color: CupertinoColors.inactiveGray.resolveFrom(context),
                    ),
                  ),
                  value: Text(
                    SubjectHelper.toFrench(subject),
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: (context) => showSubjectPicker(),
                ),

                SettingsTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Valeur",
                            style: TextStyle(
                              color: CupertinoColors.inactiveGray.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                          Text((switch (weight) {
                            0 => "Zéro",
                            .5 => "Moitié",
                            1 => "Note entière",
                            _ => weight.toString(),
                          })),
                        ],
                      ),
                      CupertinoSlider(
                        value: weight,
                        divisions: 4,
                        onChanged:
                            (newWeight) => setState(() => weight = newWeight),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SettingsSection(
              tiles: [
                SettingsTile(
                  title: Text(
                    "Date de reception",
                    style: TextStyle(
                      color: CupertinoColors.inactiveGray.resolveFrom(context),
                    ),
                  ),
                  value: Text(
                    formatDate(date).capitalize(),
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: (context) => showDatePicker(),
                ),
              ],
            ),

            SettingsSection(
              title: Text("Informations facultatives"),
              tiles: [
                SettingsTile(
                  title: CupertinoTextField(
                    controller: detailsController,
                    decoration: BoxDecoration(),
                    padding: EdgeInsets.zero,
                    textAlignVertical: TextAlignVertical.top,
                    minLines: 1,
                    maxLines: 15,
                    placeholder: "Ajoutez des informations supplémentaires...",
                  ),
                ),

                SettingsTile.navigation(
                  leading: Icon(CupertinoIcons.photo_on_rectangle),
                  title: Text("Ajouter des photos")
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}