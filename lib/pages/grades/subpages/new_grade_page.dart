import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:in_app_review/in_app_review.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/assignment_tile.dart';
import 'package:messagyre_client/utility/widgets/autocomplete_field.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/field.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/grade_picker.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class NewGradePage extends StatefulWidget {
  final Grade? toEdit;
  final Assignment? toReference;
  final Subject? subject;
  final String? groupName;

  const NewGradePage({super.key, this.toEdit, this.toReference, this.subject, this.groupName});

  @override
  State<StatefulWidget> createState() => _NewGradePageState();
}

class _NewGradePageState extends State<NewGradePage> {
  final database = DatabaseService();

  late final editMode = widget.toEdit != null;

  late var allAssignments = database.assignments.getAll();
  late var allGrades = database.grades.getAll();

  late Subject? subject = widget.toEdit?.subject.value ?? widget.subject;
  late double grade = widget.toEdit?.grade ?? 4;
  late DateTime date = widget.toEdit?.date ?? DateTime.now();
  late double weight = widget.toEdit?.weight ?? 1;
  late String? groupName = widget.toEdit?.groupName ?? widget.groupName;
  late String? referenceId = widget.toEdit?.referenceId;

  late final titleController = TextEditingController(text: widget.toEdit?.title);
  late final subjectController = TextEditingController(text: subject?.name ?? referencedAssignment?.subject.value?.name);
  late final detailsController = TextEditingController(text: widget.toEdit?.details);
  final titleFocusNode = FocusNode();
  final subjectFocusNode = FocusNode();

  late bool isInGroup = groupName != null;

  bool isValuePickerExpanded = false;
  bool isReferenceTileExpanded = false;
  bool isMissingTitle = false;
  bool isMissingSubject = false;
  late Assignment? referencedAssignment = database.assignments.getAll().firstWhereOrNull((assignment) => assignment.referenceId == widget.toEdit?.referenceId);
  double? customWeight;

  void confirmGrade() async {
    if (titleController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (_) =>
            Dialog(title: "Titre requis", content: "Veuillez entrer un titre pour la note.", options: {"OK": () => setState(() => isMissingTitle = true)}),
      );
      return;
    }

    if (subject == null) {
      showCupertinoDialog(
        context: context,
        builder: (_) =>
            Dialog(title: "Branche requise", content: "Veuillez entrer la branche de la note.", options: {"OK": () => setState(() => isMissingSubject = true)}),
      );
      return;
    }

    var newGrade = widget.toEdit ?? Grade();

    newGrade
      ..title = titleController.text
      ..grade = grade
      ..weight = weight
      ..subject.value = subject!
      ..date = date
      ..details = detailsController.text
      ..groupName = groupName
      ..referenceId = referenceId;

    if (allGrades.length == 3 && await InAppReview.instance.isAvailable()) {
      InAppReview.instance.requestReview();
    }

    database.grades.save(newGrade);

    final mountedContext = context;
    if (mountedContext.mounted) Navigator.of(mountedContext).pop();
  }

  void showDatePicker() {
    final pins = <DateTime, List<Color>>{};

    for (var grade in allGrades) {
      final date = grade.date.dateOnly();
      (pins[date] ??= []).add(grade.subject.value?.color ?? AppColors.grey);
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CustomDatePicker(initialDate: date, allowFuture: false, onDateSelected: (newDate) => setState(() => date = newDate), pins: pins),
    );
  }

  void referenceAssignment(Assignment target) {
    setState(() => referenceId = target.referenceId);
    referencedAssignment = target;
    referenceId = target.referenceId;
    subject = target.subject.value;

    titleController.text = target.title ?? target.content;
    subjectController.value = TextEditingValue(text: target.subject.value?.name ?? "");

    titleFocusNode.unfocus();
    subjectFocusNode.unfocus();
  }

  List<Assignment> getPlannedGrades() {
    return allAssignments
        .where(
          (assignment) =>
              assignment.referenceId != null &&
              assignment.type == AssignmentType.test &&
              !allGrades.any((grade) => grade.referenceId == assignment.referenceId) &&
              assignment.dueDate.isBefore(DateTime.now()),
        )
        .toList();
  }

  List<String> getGroups() {
    final resultList = <String>[];

    if (groupName != null && subject != null) resultList.add(groupName!);

    for (var storedGrade in allGrades) {
      if (storedGrade.groupName == null || storedGrade.subject.value?.code != subject?.code || resultList.contains(storedGrade.groupName!)) {
        continue;
      }
      resultList.add(storedGrade.groupName!);
    }

    return resultList;
  }

  @override
  void initState() {
    super.initState();

    if (widget.toReference != null) WidgetsBinding.instance.addPostFrameCallback((_) => referenceAssignment(widget.toReference!));
  }

  @override
  void dispose() {
    titleController.dispose();
    subjectController.dispose();
    detailsController.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    allGrades = database.grades.getAll();
    allAssignments = database.assignments.getAll();

    if (referencedAssignment == null) referenceId = null;

    return Page.scrollable(
      context,
      spacing: 10,
      topBar: TopBar.form(
        context,
        title: "${editMode ? "Modifier la" : "Nouvelle"} note",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedTick02, onTap: confirmGrade),
      ),

      children: [
        Row(
          spacing: 14,
          children: [
            GradeDisplay(grade: grade, size: 50, weight: weight),
            Expanded(
              child: RoundContainer(
                height: 50,
                padding: .symmetric(horizontal: 16),
                child: Center(
                  child: AutocompleteField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    decoration: BoxDecoration(),
                    padding: .zero,
                    placeholder: "Titre*",
                    placeholderStyle: TextStyle(color: isMissingTitle ? AppColors.red : AppColors.placeholderText.adaptTo(context)),
                    forceValid: false,
                    suffix: isMissingTitle
                        ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                        : CustomIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.placeholderText.adaptTo(context), strokeWidth: 1),

                    suffixMode: .notEditing,
                    style: TextStyle(fontSize: 26, fontWeight: .w500),
                    items: getPlannedGrades(),
                    header: Padding(padding: .only(left: 16, right: 10, top: 8, bottom: 8), child: Text("Depuis la page des devoirs :")),
                    itemBuilder: (assignment, query) {
                      if (assignment is! Assignment) return SizedBox.shrink();
                      return AssignmentTile(assignment: assignment, enabled: false, padding: .zero);
                    },
                    onSelected: (assignment) {
                      if (assignment is! Assignment) return;
                      referenceAssignment(assignment);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),

        if (referenceId != null)
          ListSection(
            margin: .only(top: 10),
            children: [
              ListTile.simple(
                context,
                onTap: () => setState(() => isReferenceTileExpanded = !isReferenceTileExpanded),
                icon: HugeIcons.strokeRoundedLink04,
                title: "Cette note est associée à un test.",
                trailing: CustomIcon(
                  icon: isReferenceTileExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                  color: AppColors.secondaryText.adaptTo(context),
                ),
              ),
              if (isReferenceTileExpanded) ...[
                ListTile(
                  buildChevron: false,
                  padding: .symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      // Preview Assignment Tile
                      RoundContainer(
                        padding: .zero,
                        child: AssignmentTile(assignment: referencedAssignment!, enabled: false),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "Le titre que vous avez entré correspond à celui de ce test, donc cette note va le représenter.\nVous pouvez changer le titre de la note sans la dissocier.",
                        style: TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                      ),
                    ],
                  ),
                ),
                ListTile.simple(
                  context,
                  title: "Dissocier",
                  icon: HugeIcons.strokeRoundedUnlink04,
                  isDestructive: true,
                  buildChevron: false,
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => Dialog.confirm(
                        content: "Dissocier la note du test ?\nVous pourrez la réassocier plus tard.",
                        onConfirm: () {
                          setState(() {
                            referenceId = null;
                            isReferenceTileExpanded = false;
                          });
                          referencedAssignment = null;
                        },
                        isDestructive: true,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

        ListSection(
          margin: .only(top: 10),
          children: [
            ListTile(
              buildChevron: false,
              padding: .symmetric(horizontal: 16, vertical: 14),
              child: GradePicker(grade: grade, onGradeChanged: (newGrade) => setState(() => grade = newGrade)),
            ),
            ListTile(
              buildChevron: false,
              padding: .symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text("Valeur", style: AppStyles.secondaryHeader(context)),

                  SingleChildScrollView(
                    scrollDirection: .horizontal,
                    padding: .only(top: 6),
                    child: Row(
                      mainAxisAlignment: .center,
                      spacing: 6,
                      children: [
                        ...fractions.keys
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
                            .reversed,
                      ],
                    ),
                  ),

                  AnimatedSize(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: isValuePickerExpanded
                        ? Column(
                            crossAxisAlignment: .stretch,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: .horizontal,
                                padding: .symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: .center,
                                  spacing: 6,
                                  children: [
                                    for (var value = 0.05; value < 1.0; value += 0.05)
                                      if (!fractions.keys.contains(value))
                                        WeightButton(
                                          value: value,
                                          selectedWeight: weight,
                                          label: "${(value * 100).round()}%",
                                          onTap: () {
                                            setState(() => weight = value);
                                            HapticFeedback.selectionClick();
                                          },
                                        ),
                                  ],
                                ),
                              ),

                              Button(
                                onTap: () => showCupertinoDialog(
                                  context: context,
                                  builder: (_) {
                                    final controller = TextEditingController(text: customWeight?.removeTrailingZero());
                                    return Dialog.entry(
                                      title: "Valeur personnalisée",
                                      placeholder: "x${weight.toStringAsFixed(2)}",
                                      controller: controller,
                                      keyboardType: .number,
                                      onConfirm: () {
                                        final newValue = double.tryParse(controller.text.trim().replaceAll(',', '.'));

                                        setState(() {
                                          customWeight = newValue;
                                          weight = newValue ?? 1;
                                        });
                                      },
                                    );
                                  },
                                ),
                                color: (weight == customWeight ? AppColors.tertiaryBackground : AppColors.secondaryBackground).adaptTo(context),
                                padding: const .symmetric(horizontal: 16, vertical: 12),
                                transparent: true,
                                rawChild: Row(
                                  spacing: 10,
                                  mainAxisAlignment: .spaceBetween,
                                  children: [
                                    Text(
                                      "Valeur personnalisée",
                                      style: weight == customWeight ? AppStyles.primaryText(context) : AppStyles.tertiaryText(context),
                                    ),

                                    Text(
                                      customWeight == null ? "Ajouter" : "x${customWeight?.removeTrailingZero()}",
                                      style: weight == customWeight ? AppStyles.secondaryHeader(context) : AppStyles.tertiaryText(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : SizedBox.shrink(),
                  ),

                  GestureDetector(
                    onTap: () => setState(() => isValuePickerExpanded = !isValuePickerExpanded),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: .only(top: 12),
                      child: Row(
                        mainAxisAlignment: .center,
                        spacing: 2,
                        children: [
                          Text(isValuePickerExpanded ? "Voir moins" : "Voir plus", style: AppStyles.footer(context)),
                          CustomIcon(
                            icon: isValuePickerExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                            color: AppColors.tertiaryText.adaptTo(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        ListSection(
          footer: referenceId != null
              ? "La branche ne peut pas etre changé parce que cette note est associé à un test."
              : "Merci de remplir les champs obligatoires *",
          children: [
            ListTile(
              onTap: () => subjectFocusNode.requestFocus(),
              leading: CustomIcon(icon: HugeIcons.strokeRoundedBookBookmark02, color: referenceId == null ? null : AppColors.inactive.adaptTo(context)),
              trailing: isMissingSubject ? const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18) : null,
              enabled: referenceId == null,
              child: SubjectAutocomplete(
                controller: subjectController,
                focusNode: subjectFocusNode,
                padding: .zero,
                placeholder: "Entrez une branche *",
                placeholderStyle: isMissingSubject ? const TextStyle(color: AppColors.red) : null,
                onSubjectSelected: (selectedSubject) {
                  subjectFocusNode.unfocus();
                  setState(() {
                    subject = selectedSubject;
                    isMissingSubject = false;
                  });
                },
                forceValid: true,
                enabled: referenceId == null,
              ),
            ),
          ],
        ),

        if (subject != null)
          ListSection(
            title: "Groupe",
            margin: .only(top: 16),
            footer: isInGroup ? null : "Toutes les notes d'un même groupe seront considérées et calculées comme une seule note.",

            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedSelect01,
                title: "Fait partie d'un groupe",
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
                ...getGroups().map((existingGroupName) {
                  return ListTile.simple(
                    context,
                    icon: groupName == existingGroupName ? HugeIcons.strokeRoundedTick02 : null,
                    title: existingGroupName,
                    buildChevron: false,
                    onTap: () => setState(() {
                      groupName = existingGroupName;
                    }),
                  );
                }),
                ListTile.simple(
                  context,
                  title: "Créer un nouveau groupe",
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) {
                        final controller = TextEditingController();

                        return Dialog.entry(
                          title: "Nouveau groupe",
                          placeholder: "Nom du groupe (TP, Vocs, ...)",
                          controller: controller,
                          onConfirm: () {
                            final newName = controller.text.trim();
                            try {
                              if (newName.isNotEmpty) setState(() => groupName = newName);
                            } catch (e) {
                              debugPrint("Error adding group: $e");
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),

        ListSection(
          title: "Autres",
          margin: .only(top: 16),
          children: [
            ListTile.simple(
              context,
              icon: HugeIcons.strokeRoundedCalendar04,
              trailing: CupertinoListTileChevron(),
              title: "Reçu ${formatDate(date, includeArticle: true)}",
              onTap: showDatePicker,
            ),
          ],
        ),

        Field(placeholder: "Notes supplémentaires...", controller: detailsController, minLines: 3, maxLines: 5),

        if (editMode)
          ListSection(
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedDelete04,
                title: "Supprimer la note",
                isDestructive: true,
                onTap: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => Dialog.confirm(
                      content: "Êtes-vous sûr de vouloir supprimer cette note ?",
                      onConfirm: () {
                        allGrades.remove(widget.toEdit);
                        database.grades.delete(widget.toEdit!);
                        Navigator.of(context).pop(widget.toEdit);
                      },
                      isDestructive: true,
                    ),
                  );
                },
              ),
            ],
          ),
      ],
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

    return IntrinsicWidth(
      child: Button(
        onTap: onTap,
        padding: .symmetric(horizontal: 16, vertical: 12),
        transparent: true,
        color: (isSelected ? AppColors.tertiaryBackground : AppColors.secondaryBackground).adaptTo(context),
        text: label,
      ),
    );
  }
}
