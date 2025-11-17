import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/custom_subject_picker.dart';
import 'package:messagyre_client/utility/widgets/dismissable_text_field.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';

class NewGrade extends StatefulWidget {
  final Grade? toEdit;
  final Subject? subject;
  final VoidCallback? onDelete;
  final List<String> existingGroupNames;
  final String? groupName;

  const NewGrade({super.key, this.toEdit, this.subject, this.onDelete, this.existingGroupNames = const [], this.groupName});

  @override
  State<StatefulWidget> createState() => _NewGradeState();
}

class _NewGradeState extends State<NewGrade> {
  late final editMode = widget.toEdit != null;

  late Subject? subject = widget.toEdit?.subject ?? widget.subject;
  late double grade = widget.toEdit?.grade ?? 4;
  late DateTime date = widget.toEdit?.date ?? DateTime.now();
  late double weight = widget.toEdit?.weight ?? 1;
  late String? groupName = widget.toEdit?.groupName ?? widget.groupName;

  late final titleController = TextEditingController(text: widget.toEdit?.title);
  late final subjectController = TextEditingController(text: SubjectHelper.toFrenchOrNull(subject));
  late final detailsController = TextEditingController(text: widget.toEdit?.details);

  late bool isInGroup = groupName != null;

  late List<String> groupNames = List.from(widget.existingGroupNames);

  void confirmGrade() {
    if (titleController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: Text("Titre requis"),
              content: Text("Veuillez entrer un titre pour la note."),
              actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(dialogContext))],
            ),
      );
      return;
    }

    if (subject == null) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: Text("Branche requise"),
              content: Text("Veuillez entrer la branche de la note."),
              actions: [CupertinoDialogAction(child: Text("OK"), onPressed: () => Navigator.pop(dialogContext))],
            ),
      );
      return;
    }

    var gradeData = widget.toEdit ?? Grade();

    gradeData
      ..title = titleController.text
      ..grade = grade
      ..weight = weight
      ..subject = subject!
      ..date = date
      ..details = detailsController.text
      ..groupName = groupName;

    Navigator.of(context).pop(gradeData);
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
      builder: (_) => CustomDatePicker(initialDate: date, allowFuture: false, onDateSelected: (newDate) => setState(() => date = newDate)),
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
              onSelectedItemChanged: (index) {
                setState(() => grade = grades[index]);
                HapticFeedback.selectionClick();
              },
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: grades.length,
                builder: (context, index) {
                  final thisGrade = grades[index];
                  final isWhole = thisGrade % 1 == 0;
                  final display = isWhole ? thisGrade.toInt().toString() : thisGrade.toStringAsFixed(1);
                  final isSelected = grade == thisGrade;

                  return RotatedBox(
                    quarterTurns: 1,
                    child: Center(
                      child: Text(
                        display,
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 22,
                          color: isSelected ? CupertinoColors.label.resolveFrom(context) : CupertinoColors.tertiaryLabel.resolveFrom(context),
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
                decoration: BoxDecoration(color: CupertinoColors.systemGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
    subjectController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      navigationBar: CupertinoNavigationBar(
        border: null,
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: Navigator.of(context).pop, child: Text("Annuler")),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: confirmGrade,
          child: Text(editMode ? "Terminé" : "Ajouter", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          children: [
            Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DismissableTextField(
                  controller: titleController,
                  decoration: const BoxDecoration(),
                  padding: EdgeInsets.zero,
                  placeholder: "Titre",
                  prefix: Padding(
                    padding: EdgeInsetsGeometry.only(right: 10),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge04, color: CupertinoColors.placeholderText.resolveFrom(context)),
                  ),
                  suffix: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.placeholderText.resolveFrom(context)),
                  suffixMode: OverlayVisibilityMode.notEditing,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                  placeholderStyle: TextStyle(color: CupertinoColors.placeholderText.resolveFrom(context), fontWeight: FontWeight.w500),
                ),

                Container(
                  decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildGradePicker(),
                      Divider(thickness: .25, color: CupertinoColors.separator.resolveFrom(context)),
                      Text("Valeur", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children:
                              fractions.keys
                                  .map((key) {
                                    return WeightButton(
                                      value: key,
                                      selectedWeight: weight,
                                      label: fractions[key] ?? "?",
                                      onTap: () {
                                        setState(() => weight = key);
                                        HapticFeedback.selectionClick();
                                      },
                                    );
                                  })
                                  .toList()
                                  .reversed
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                CupertinoListSection.insetGrouped(
                  header: Text("Branche"),
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedBookBookmark02, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      trailing: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                      title: SubjectAutocomplete(
                        controller: subjectController,
                        decoration: const BoxDecoration(),
                        padding: EdgeInsets.zero,
                        placeholder: "Entrez une branche",
                        onSelected: (selectedSubject) => setState(() => subject = selectedSubject),
                        forceValid: true,
                      ),
                    ),
                  ],
                ),

                CupertinoListSection.insetGrouped(
                  header: Text("Groupe"),
                  margin: EdgeInsets.zero,
                  footer: Padding(
                    padding: EdgeInsetsGeometry.only(top: 6),
                    child: Text(
                      "Toutes les notes d'un même groupe seront considérées et calculées comme une seule note.",
                      style: TextStyle(fontSize: 14, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                    ),
                  ),
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedSelect01, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      title: Text("Fait partie d'un groupe"),
                      trailing: CupertinoSwitch(
                        value: isInGroup,
                        onChanged: (value) {
                          setState(() {
                            isInGroup = value;
                            if (!value) {
                              groupName = null;
                            }
                          });
                        },
                      ),
                    ),
                    if (isInGroup) ...[
                      ...groupNames.map((name) {
                        return CupertinoListTile(
                          title: Text(name),
                          onTap:
                              () => setState(() {
                                groupName = name;
                              }),
                          trailing:
                              groupName == name
                                  ? HugeIcon(icon: HugeIcons.strokeRoundedTick02, color: CupertinoTheme.of(context).primaryColor.withBrightness(.5))
                                  : null,
                        );
                      }),
                      CupertinoListTile(
                        title: Row(
                          children: [
                            HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: CupertinoColors.label.resolveFrom(context)),
                            const SizedBox(width: 10),
                            Text("Ajouter un groupe"),
                          ],
                        ),
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder: (dialogContext) {
                              final controller = TextEditingController();
                              return CupertinoAlertDialog(
                                title: Row(
                                  spacing: 8,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    HugeIcon(icon: HugeIcons.strokeRoundedSelect01, color: CupertinoTheme.of(context).primaryColor.withBrightness(.25)),
                                    Text("Nouveau groupe"),
                                  ],
                                ),
                                content: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    SizedBox(
                                      height: 40,
                                      child: DismissableTextField(
                                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        decoration: BoxDecoration(color: CupertinoColors.systemGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                        controller: controller,
                                        placeholder: "Nom du groupe",
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: Text("Annuler", style: TextStyle(color: CupertinoColors.label.resolveFrom(context))),
                                    onPressed: () => Navigator.pop(dialogContext),
                                  ),
                                  CupertinoDialogAction(
                                    isDefaultAction: true,
                                    child: Text("Ajouter", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.25))),
                                    onPressed: () {
                                      final newName = controller.text.trim();
                                      try {
                                        if (newName.isNotEmpty && !groupNames.contains(newName)) {
                                          setState(() {
                                            groupNames.add(newName);
                                            groupName = newName;
                                          });
                                        }
                                      } catch (e) {
                                        debugPrint("Error adding group: $e");
                                      }
                                      Navigator.pop(dialogContext);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),

                CupertinoListSection.insetGrouped(
                  header: Text("Date de reception"),
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedWorkHistory, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                      title: Text("Reçu ${formatDate(date, includeArticle: true)}"),
                      onTap: showDatePicker,
                    ),
                  ],
                ),

                CupertinoListSection.insetGrouped(
                  header: Text("Informations facultatives"),
                  margin: EdgeInsets.zero,
                  children: [
                    CupertinoListTile(
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedMoreHorizontal, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      trailing: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                      title: StatefulBuilder(
                        builder: (context, setInnerState) {
                          final focusNode = FocusNode();
                          bool hasFocus = false;
                          focusNode.addListener(() {
                            setInnerState(() {
                              hasFocus = focusNode.hasFocus;
                            });
                          });
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              DismissableTextField(
                                controller: detailsController,
                                focusNode: focusNode,
                                decoration: BoxDecoration(),
                                padding: EdgeInsets.symmetric(vertical: 10),
                                textAlignVertical: TextAlignVertical.top,
                                minLines: 1,
                                maxLines: 15,
                                placeholder: "Notes supplémentaires...",
                              ),
                              if (hasFocus)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: CupertinoButton(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    onPressed: () => focusNode.unfocus(),
                                    child: Text("Fermer", style: TextStyle(color: CupertinoTheme.of(context).primaryColor, fontSize: 14)),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    // TODO
                    // CupertinoListTile(
                    //   leading: HugeIcon(icon: HugeIcons.strokeRoundedImageAdd02, color: CupertinoColors.inactiveGray.resolveFrom(context)),
                    //   title: Text("Ajouter des photos", style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context))),
                    // ),
                  ],
                ),

                if (editMode)
                  CupertinoListSection.insetGrouped(
                    header: Text("Autres"),
                    margin: EdgeInsets.zero,
                    children: [
                      CupertinoListTile(
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: CupertinoColors.destructiveRed.resolveFrom(context)),
                        title: Text("Supprimer la note", style: TextStyle(color: CupertinoColors.destructiveRed.resolveFrom(context))),
                        onTap: () {
                          showCupertinoDialog(
                            context: context,
                            builder:
                                (_) => CupertinoAlertDialog(
                                  title: Text("Supprimer la note"),
                                  content: Text("Êtes-vous sûr de vouloir supprimer cette note ?"),
                                  actions: [
                                    CupertinoDialogAction(child: Text("Annuler"), onPressed: () => Navigator.pop(context)),
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
          ],
        ),
      ),
    );
  }
}

class WeightButton extends StatelessWidget {
  final double value;
  final double selectedWeight;
  final String label;
  final VoidCallback onTap;

  const WeightButton({super.key, required this.value, required this.selectedWeight, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedWeight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(isSelected ? .1 : .05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isSelected ? CupertinoColors.label.resolveFrom(context) : CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}
