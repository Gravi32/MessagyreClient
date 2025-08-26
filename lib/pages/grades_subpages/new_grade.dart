import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:settings_ui/settings_ui.dart';

class NewGrade extends StatefulWidget {
  final Grade? toEdit;
  final Subject? subject;
  final VoidCallback? onDelete;
  final List<String> existingGroupNames;
  final String? groupName;

  const NewGrade({
    super.key,
    this.toEdit,
    this.subject,
    this.onDelete,
    this.existingGroupNames = const [],
    this.groupName,
  });

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

  late Subject subject =
      widget.toEdit?.subject ?? widget.subject ?? Subject.Maths;
  late double grade = widget.toEdit?.grade ?? 4;
  late DateTime date = widget.toEdit?.date ?? DateTime.now();
  late double weight = widget.toEdit?.weight ?? 1;
  late String? groupName = widget.toEdit?.groupName ?? widget.groupName;

  late bool isInGroup = groupName != null;

  late List<String> groupNames = List.from(widget.existingGroupNames);

  void confirmGrade() {
    print("Confirming grade");

    if (titleController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: Text("Titre requis"),
              content: Text("Veuillez entrer un titre pour la note."),
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

    var gradeData = widget.toEdit ?? Grade();

    gradeData
      ..title = titleController.text
      ..grade = grade
      ..weight = weight
      ..subject = subject
      ..date = date
      ..details = detailsController.text
      ..groupName = groupName;

    Navigator.of(context).pop(gradeData);

    print("window popped");
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
      builder:
          (_) => CustomDatePicker(
            initialDate: date,
            allowFuture: false,
            onDateSelected: (newDate) => setState(() => date = newDate),
          ),
    );
  }

  Widget buildGradePicker() {
    final grades = List.generate(11, (i) => i * .5 + 1);
    final controller = FixedExtentScrollController(
      initialItem: grades.indexOf(grade),
    );

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
      resizeToAvoidBottomInset: true,
      navigationBar: CupertinoNavigationBar(
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: Navigator.of(context).pop,
          child: Text("Annuler"),
        ),
        middle: Text(editMode ? widget.toEdit!.title : "Nouvelle note"),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: confirmGrade,
          child: Text(
            editMode ? "Terminé" : "Ajouter",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
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
                        color: CupertinoColors.inactiveGray.resolveFrom(
                          context,
                        ),
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
                  SettingsTile.switchTile(
                    title: Text(
                      "Fait partie d'un groupe",
                      style: TextStyle(
                        color: CupertinoColors.inactiveGray.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    initialValue: isInGroup,
                    onToggle: (value) {
                      setState(() {
                        isInGroup = value;
                        if (!value) {
                          groupName = null;
                        }
                      });
                    },
                  ),

                  if (isInGroup) ...[
                    ...groupNames.map((name) {
                      return SettingsTile(
                        title: GestureDetector(
                          child: Text(name),
                          onTap:
                              () => setState(() {
                                groupName = name;
                              }),
                        ),
                        trailing:
                            groupName == name
                                ? Icon(CupertinoIcons.check_mark, size: 18)
                                : null,
                      );
                    }),

                    SettingsTile(
                      title: GestureDetector(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.add_circled, size: 20),
                            const SizedBox(width: 10),
                            Text("Ajouter un groupe"),
                          ],
                        ),
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (_) {
                              final controller = TextEditingController();
                              return CupertinoAlertDialog(
                                title: Text("Nouveau groupe"),
                                content: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    CupertinoTextField(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      controller: controller,
                                      placeholder: "Nom du groupe",
                                    ),
                                  ],
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text("Annuler"),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    child: Text("Ajouter"),
                                    onPressed: () {
                                      final newName = controller.text.trim();
                                      try {
                                        if (newName.isNotEmpty &&
                                            !groupNames.contains(newName)) {
                                          setState(() {
                                            groupNames.add(newName);
                                            groupName = newName;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint("Error adding group: $e");
                                      }
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),

              SettingsSection(
                tiles: [
                  SettingsTile(
                    title: Text(
                      "Date de réception",
                      style: TextStyle(
                        color: CupertinoColors.inactiveGray.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    value: Text(
                      formatDate(date)[0].toUpperCase() +
                          formatDate(date).substring(1),
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
                      placeholder:
                          "Ajoutez des informations supplémentaires...",
                    ),
                  ),
                  SettingsTile.navigation(
                    leading: Icon(CupertinoIcons.photo_on_rectangle),
                    title: Text("Ajouter des photos"),
                  ),
                ],
              ),

              if (editMode)
                SettingsSection(
                  tiles: [
                    SettingsTile(
                      leading: Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.destructiveRed.resolveFrom(
                          context,
                        ),
                      ),
                      title: Text(
                        "Supprimer la note",
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      onPressed: (context) {
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (_) => CupertinoAlertDialog(
                                title: Text("Supprimer la note"),
                                content: Text(
                                  "Êtes-vous sûr de vouloir supprimer cette note ?",
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text("Annuler"),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: Text("Supprimer"),
                                    onPressed: () {
                                      widget.toEdit?.delete();
                                      widget.onDelete?.call();
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
            ],
          ),
        ),
      ),
    );
  }
}
