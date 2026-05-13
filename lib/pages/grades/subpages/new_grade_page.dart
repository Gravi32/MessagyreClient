import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Dialog;
import 'package:in_app_review/in_app_review.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/assignment_tile.dart';
import 'package:messagyre_client/utility/widgets/autocomplete_field.dart';
import 'package:messagyre_client/utility/widgets/custom_date_picker.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/dismissable_text_field.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/grade_picker.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
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

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.transparent,
        border: null,
        leading: CupertinoButton(padding: .zero, onPressed: Navigator.of(context).pop, child: Text("Annuler")),
        trailing: CupertinoButton(
          padding: .zero,
          onPressed: confirmGrade,
          child: Text(editMode ? "Terminé" : "Ajouter", style: TextStyle(fontWeight: .bold)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: .symmetric(horizontal: 10, vertical: 20),
          children: [
            Column(
              spacing: 10,
              crossAxisAlignment: .stretch,
              children: [
                Padding(
                  padding: .only(bottom: 10),
                  child: Text("${editMode ? "Modifier la" : "Nouvelle"} note", style: TextStyle(fontSize: 28, fontWeight: .w600)),
                ),
                Row(
                  spacing: 14,
                  children: [
                    GradeDisplay(grade: grade, size: 50, weight: weight),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .stretch,
                        spacing: 2,
                        children: [
                          AutocompleteField(
                            controller: titleController,
                            focusNode: titleFocusNode,
                            decoration: BoxDecoration(),
                            padding: .zero,
                            placeholder: "Titre*",
                            placeholderStyle: TextStyle(
                              color: isMissingTitle ? AppColors.red : AppColors.placeholderText.adaptTo(context),
                              fontWeight: .w500,
                            ),
                            forceValid: false,
                            suffix: isMissingTitle
                                ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                                : CustomIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.placeholderText.adaptTo(context), strokeWidth: 1),

                            suffixMode: OverlayVisibilityMode.notEditing,
                            style: TextStyle(fontSize: 26, fontWeight: .w500),
                            items: getPlannedGrades(),
                            header: Padding(padding: .only(left: 16, right: 10, top: 8, bottom: 8), child: Text("Depuis la page des devoirs :")),
                            itemBuilder: (assignment, query) {
                              if (assignment is! Assignment) return SizedBox.shrink();
                              return Column(
                                spacing: 8,
                                children: [
                                  Align(
                                    alignment: .centerLeft,
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          if (assignment.subject.value != null)
                                            WidgetSpan(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: AppColors.red.withBrightness(-.25),
                                                  border: .all(color: AppColors.red),
                                                  borderRadius: .circular(6),
                                                ),
                                                padding: .all(2),
                                                child: Text(
                                                  "TEST",
                                                  style: TextStyle(fontSize: 14, letterSpacing: .3, fontWeight: .w900, color: AppColors.white),
                                                ),
                                              ),
                                            ),
                                          WidgetSpan(child: SizedBox(width: 10)),
                                          ...highlightSearchMatch(assignment.title ?? assignment.content, query, useCache: true),
                                        ],
                                        style: const TextStyle(fontWeight: .w400, fontSize: 20),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: .stretch,
                                    spacing: 4,
                                    children: [
                                      if (assignment.subject.value != null)
                                        Row(
                                          spacing: 8,
                                          children: [
                                            SubjectBadge(subject: assignment.subject.value!, size: 20),
                                            Text(
                                              "${assignment.subject.value!.name}  •  ${formatDate(assignment.dueDate)}",
                                              style: TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            },
                            onSelected: (assignment) {
                              if (assignment is! Assignment) return;
                              referenceAssignment(assignment);
                            },
                          ),
                          Text(
                            subject != null ? "Note ${subject!.name.withPreposition(lowercase: true)}" : "Pas de branche sélectionnée",
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: TextStyle(color: AppColors.quaternaryText.adaptTo(context), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (referenceId != null)
                  Container(
                    decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(10)),
                    margin: .only(top: 10),
                    padding: EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => isReferenceTileExpanded = !isReferenceTileExpanded),
                          child: Row(
                            spacing: 6,
                            children: [
                              CustomIcon(icon: HugeIcons.strokeRoundedLink04, size: 18, color: AppColors.secondaryText.adaptTo(context)),
                              Expanded(
                                child: Text("Cette note est associée à un devoir.", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                              ),
                              CustomIcon(
                                icon: isReferenceTileExpanded ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                                color: AppColors.secondaryText.adaptTo(context),
                              ),
                            ],
                          ),
                        ),

                        if (isReferenceTileExpanded && referencedAssignment != null) ...[
                          const SizedBox(height: 10),

                          // Preview Assignment Tile
                          Opacity(
                            opacity: .9,
                            child: CupertinoListSection.insetGrouped(
                              margin: .zero,
                              backgroundColor: AppColors.transparent,
                              children: [AssignmentTile(assignment: referencedAssignment!, enabled: false)],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Le titre que vous avez entré correspond à celui de ce devoir, donc cette note va le représenter.\nVous pouvez changer le titre de la note sans la dissocier.",
                            style: TextStyle(color: AppColors.secondaryText.adaptTo(context)),
                          ),
                          const SizedBox(height: 4),
                          Text("ID de réference: $referenceId", style: TextStyle(fontSize: 14, color: AppColors.quaternaryText.adaptTo(context))),
                          Divider(thickness: .25, color: AppColors.separator.adaptTo(context)),
                          GestureDetector(
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
                            child: Row(
                              spacing: 6,
                              mainAxisAlignment: .center,
                              children: [
                                CustomIcon(icon: HugeIcons.strokeRoundedUnlink04, color: AppColors.red),
                                Text("Dissocier", style: TextStyle(color: AppColors.red)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                Container(
                  decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(10)),
                  margin: .only(top: 10),
                  padding: EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 10),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      GradePicker(grade: grade, onGradeChanged: (newGrade) => setState(() => grade = newGrade)),
                      Divider(thickness: .25, color: AppColors.separator.adaptTo(context)),

                      Text("Valeur", style: TextStyle(color: AppColors.inactive.adaptTo(context))),

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

                                  GestureDetector(
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
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const .only(left: 16, top: 12, bottom: 12, right: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.grey.withAlpha((weight == customWeight ? .1 : .05).toByte()),
                                        borderRadius: .circular(8),
                                      ),
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Text(
                                            "Valeur personnalisée",
                                            style: TextStyle(
                                              color: weight == customWeight ? AppColors.text.adaptTo(context) : AppColors.tertiaryText.adaptTo(context),
                                            ),
                                          ),
                                          Spacer(),

                                          Text(
                                            customWeight == null ? "Ajouter" : "x${customWeight?.removeTrailingZero()}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: .w600,
                                              color: weight == customWeight ? AppColors.text.adaptTo(context) : AppColors.tertiaryText.adaptTo(context),
                                            ),
                                          ),
                                          CupertinoListTileChevron(),
                                        ],
                                      ),
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
                          margin: .only(top: 6),
                          child: Row(
                            mainAxisAlignment: .center,
                            children: [
                              Text(
                                isValuePickerExpanded ? "Voir moins" : "Voir plus",
                                style: TextStyle(color: AppColors.tertiaryText.adaptTo(context), fontSize: 15),
                              ),
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

                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.transparent,
                  header: Text("Branche", style: referenceId == null ? null : TextStyle(color: AppColors.inactive.adaptTo(context))),
                  footer: Padding(
                    padding: EdgeInsetsGeometry.only(top: 6),
                    child: referenceId != null
                        ? Text(
                            "La branche ne peut pas etre changé parce que cette note est associé à un devoir.",
                            style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context)),
                          )
                        : Text(
                            "Merci de remplir les champs obligatoires *",
                            style: TextStyle(
                              fontSize: 14,
                              color: titleController.text.isNotEmpty && subject != null ? AppColors.secondaryText.adaptTo(context) : AppColors.yellow,
                            ),
                          ),
                  ),
                  margin: .zero,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      onTap: () => subjectFocusNode.requestFocus(),
                      leading: CustomIcon(icon: HugeIcons.strokeRoundedBookBookmark02, color: referenceId == null ? null : AppColors.inactive.adaptTo(context)),
                      trailing: isMissingSubject
                          ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                          : CustomIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.placeholderText.adaptTo(context), strokeWidth: 1),
                      title: SubjectAutocomplete(
                        controller: subjectController,
                        focusNode: subjectFocusNode,
                        decoration: const BoxDecoration(),
                        padding: .zero,
                        placeholder: "Entrez une branche *",
                        placeholderStyle: isMissingSubject ? TextStyle(color: AppColors.red) : null,
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
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    header: Text("Groupe"),
                    margin: .zero,
                    footer: isInGroup
                        ? null
                        : Padding(
                            padding: EdgeInsetsGeometry.only(top: 6),
                            child: Text(
                              "Toutes les notes d'un même groupe seront considérées et calculées comme une seule note.",
                              style: TextStyle(fontSize: 14, color: AppColors.tertiaryText.adaptTo(context)),
                            ),
                          ),
                    children: [
                      CupertinoListTile(
                        backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                        leading: CustomIcon(icon: HugeIcons.strokeRoundedSelect01),
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
                    ],
                  ),

                if (isInGroup)
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    margin: .zero,
                    children: [
                      ...getGroups().map((existingGroupName) {
                        return CupertinoListTile.notched(
                          backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                          leading: groupName == existingGroupName ? CustomIcon(icon: HugeIcons.strokeRoundedTick02, color: AppColors.accent) : null,
                          title: Text(existingGroupName, style: TextStyle(fontWeight: .w600)),
                          onTap: () => setState(() {
                            groupName = existingGroupName;
                          }),
                        );
                      }),
                      CupertinoListTile(
                        backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                        leading: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
                        title: Text("Créer un nouveau groupe", style: TextStyle(color: AppColors.text.adaptTo(context))),
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
                  ),

                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.transparent,
                  header: Text("Date de reception"),
                  margin: .zero,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: CustomIcon(icon: HugeIcons.strokeRoundedWorkHistory),
                      trailing: CupertinoListTileChevron(),
                      title: Text("Reçu ${formatDate(date, includeArticle: true)}", style: TextStyle(fontWeight: .w600)),
                      onTap: showDatePicker,
                    ),
                  ],
                ),

                CupertinoListSection.insetGrouped(
                  backgroundColor: AppColors.transparent,
                  header: Text("Informations facultatives"),
                  margin: .zero,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: CustomIcon(icon: HugeIcons.strokeRoundedMoreHorizontal),
                      trailing: CustomIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.placeholderText.adaptTo(context), strokeWidth: 1),
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
                            alignment: .topRight,
                            children: [
                              DismissableTextField(
                                controller: detailsController,
                                focusNode: focusNode,
                                decoration: BoxDecoration(),
                                padding: .symmetric(vertical: 10),
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
                                    padding: .symmetric(horizontal: 8, vertical: 4),
                                    onPressed: () => focusNode.unfocus(),
                                    child: Text("Fermer", style: TextStyle(color: AppColors.accent, fontSize: 14)),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    // TODO
                    // CupertinoListTile(backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    //   leading: CustomIcon(icon: HugeIcons.strokeRoundedImageAdd02, color: AppColors.inactive.adaptTo(context)),
                    //   title: Text("Ajouter des photos", style: TextStyle(color: AppColors.inactive.adaptTo(context))),
                    // ),
                  ],
                ),

                if (editMode)
                  CupertinoListSection.insetGrouped(
                    backgroundColor: AppColors.transparent,
                    header: Text("Autres"),
                    margin: .zero,
                    children: [
                      CupertinoListTile(
                        backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                        leading: CustomIcon(icon: HugeIcons.strokeRoundedDelete04, color: AppColors.red),
                        title: Text("Supprimer la note", style: TextStyle(color: AppColors.red)),
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
        padding: const .symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppColors.grey.withAlpha((isSelected ? .1 : .05).toByte()), borderRadius: .circular(8)),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: .w600,
            color: isSelected ? AppColors.text.adaptTo(context) : AppColors.tertiaryText.adaptTo(context),
          ),
        ),
      ),
    );
  }
}
