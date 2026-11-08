import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:in_app_review/in_app_review.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
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
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/grade_picker.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';

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

  /// The usual weights; any other one goes through "Autre"
  static const commonWeights = [2.0, 1.5, 1.0, .75, .5, .25];

  static String weightLabel(double value) => value >= 1 ? "×${value.removeTrailingZero()}" : (fractions[value] ?? "${(value * 100).round()}%");

  /// The word under each usual weight
  static final weightNames = <double, String>{2.0: "Double", 1.5: "Une et demie", 1.0: "Normale", .75: "Trois quarts", .5: "Moitié", .25: "Quart"};

  /// What the chosen weight means, in a sentence (`*bold*` for CustomText)
  static String weightSentence(double value) {
    if (value == 1) return "Une note normale : elle compte *une fois* dans la moyenne.";
    if (value > 1) return "Elle compte *${value.removeTrailingZero()} fois* plus qu'une note normale.";
    return "Elle compte pour *${fractions[value] ?? "${(value * 100).round()}%"}* d'une note normale.";
  }

  /// A weight to choose: all the same size, the chosen one filled with the accent
  Widget buildWeightChip(String label, String? name, bool isSelected, VoidCallback onTap) {
    final text = AppColors.text.adaptTo(context);
    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .6,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        height: 58,
        width: double.infinity,
        padding: const .symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.tertiaryBackground.adaptTo(context),
          borderRadius: .circular(AppRadius.s),
          boxShadow: isSelected ? const [BoxShadow(color: Color.fromRGBO(90, 10, 98, 1), offset: Offset(0, 3))] : null,
        ),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text(
              label,
              maxLines: 1,
              style: AppStyles.strongText(context).copyWith(fontFamily: AppStyles.titleFontFamily, fontWeight: .w600, color: isSelected ? AppColors.white : text),
            ),
            if (name != null)
              FittedBox(
                fit: .scaleDown,
                child: Text(
                  name,
                  maxLines: 1,
                  style: AppStyles.caption(context).copyWith(
                    fontWeight: .w700,
                    color: isSelected ? AppColors.white.withValues(alpha: .85) : AppColors.secondaryText.adaptTo(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void chooseCustomWeight() {
    showCupertinoDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController(text: customWeight?.removeTrailingZero());
        return Dialog.entry(
          title: "Autre valeur",
          placeholder: "Ex. 0.4 ou 3",
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onConfirm: () {
            final newValue = double.tryParse(controller.text.trim().replaceAll(',', '.'));
            if (newValue == null || newValue <= 0) return;
            setState(() {
              customWeight = newValue;
              weight = newValue;
            });
          },
        );
      },
    );
  }

  Widget sectionTitle(String title) => Padding(
    padding: const .only(left: 4, bottom: AppSpacing.s, top: AppSpacing.xl),
    child: Text(title, style: AppStyles.section(context)),
  );

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
    final isCustomWeight = !commonWeights.contains(weight);

    return Page.scrollable(
      context,
      topBar: TopBar.form(
        context,
        title: "${editMode ? "Modifier la" : "Nouvelle"} note",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedTick02, onTap: confirmGrade),
      ),

      children: [
        // The grade, big, and the ruler to choose it, on the icon's gradient with its Gymnase
        BrandCard(
          padding: const .fromLTRB(AppSpacing.l, AppSpacing.xl, AppSpacing.l, AppSpacing.m),
          markScale: .95,
          child: Column(
            spacing: AppSpacing.l,
            children: [
              GradeDisplay(grade: grade, size: 96, weight: weight, onAccent: true),
              GradePicker(grade: grade, onAccent: true, onGradeChanged: (newGrade) => setState(() => grade = newGrade)),
            ],
          ),
        ),

        sectionTitle("Infos"),
        RoundContainer(
          padding: .zero,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              // Title (can pick a past test from the assignments)
              Padding(
                padding: const .fromLTRB(AppSpacing.l, 0, AppSpacing.s, 0),
                child: SizedBox(
                  height: 54,
                  child: Row(
                    spacing: AppSpacing.m + 2,
                    children: [
                      ListTile.iconTile(context, icon: HugeIcons.strokeRoundedTextFont, color: isMissingTitle ? AppColors.red : null),
                      Expanded(
                        child: AutocompleteField(
                          controller: titleController,
                          focusNode: titleFocusNode,
                          decoration: const BoxDecoration(),
                          padding: .zero,
                          placeholder: "Titre",
                          placeholderStyle: AppStyles.placeholder(context).copyWith(color: isMissingTitle ? AppColors.red : null),
                          forceValid: false,
                          suffix: isMissingTitle ? const HugeIcon(icon: AppIcons.missing, color: AppColors.red, size: 18) : null,
                          suffixMode: .notEditing,
                          style: AppStyles.primaryText(context),
                          items: getPlannedGrades(),
                          header: Padding(
                            padding: const .fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.m, AppSpacing.s),
                            child: Text("Tests passés", style: AppStyles.footnote(context).copyWith(fontWeight: .w600)),
                          ),
                          itemBuilder: (assignment, query) {
                            if (assignment is! Assignment) return const SizedBox.shrink();
                            return AssignmentTile(assignment: assignment, enabled: false, padding: .zero);
                          },
                          onSelected: (assignment) {
                            if (assignment is! Assignment) return;
                            referenceAssignment(assignment);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(height: .5, margin: const .only(left: 62), color: AppColors.separator.adaptTo(context)),

              // Subject
              ListTile(
                onTap: () => subjectFocusNode.requestFocus(),
                leading: ListTile.iconTile(
                  context,
                  icon: HugeIcons.strokeRoundedBookBookmark02,
                  color: referenceId != null ? AppColors.inactive.adaptTo(context) : (isMissingSubject ? AppColors.red : null),
                ),
                trailing: isMissingSubject ? const HugeIcon(icon: AppIcons.missing, color: AppColors.red, size: 18) : const SizedBox.shrink(),
                enabled: referenceId == null,
                child: SubjectAutocomplete(
                  controller: subjectController,
                  focusNode: subjectFocusNode,
                  padding: .zero,
                  placeholder: "Branche",
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
              Container(height: .5, margin: const .only(left: 62), color: AppColors.separator.adaptTo(context)),

              // Date
              ListTile.simple(context, icon: HugeIcons.strokeRoundedCalendar04, title: "Reçu ${formatDate(date, includeArticle: true)}", onTap: showDatePicker),
            ],
          ),
        ),
        if (referenceId != null)
          Padding(
            padding: const .only(left: 4, top: AppSpacing.s),
            child: Text("La branche vient du test associé.", style: AppStyles.footer(context)),
          ),

        // The test it comes from
        if (referenceId != null && referencedAssignment != null) ...[
          sectionTitle("Test associé"),
          RoundContainer(
            padding: .zero,
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                AssignmentTile(assignment: referencedAssignment!, enabled: false),
                Container(height: .5, color: AppColors.separator.adaptTo(context)),
                ListTile.simple(
                  context,
                  title: "Dissocier du test",
                  icon: HugeIcons.strokeRoundedUnlink04,
                  isDestructive: true,
                  buildChevron: false,
                  onTap: () => showCupertinoDialog(
                    context: context,
                    builder: (_) => Dialog.confirm(
                      content: "Dissocier la note du test ?\nVous pourrez la réassocier plus tard.",
                      isDestructive: true,
                      onConfirm: () {
                        setState(() => referenceId = null);
                        referencedAssignment = null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Weight
        sectionTitle("Combien elle compte"),
        RoundContainer(
          padding: const .all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: .stretch,
            spacing: AppSpacing.s,
            children: [
              for (final row in [
                commonWeights.sublist(0, 4),
                [...commonWeights.sublist(4), null],
              ])
                Row(
                  spacing: AppSpacing.s,
                  children: [
                    for (final value in row)
                      Expanded(
                        child: value == null
                            ? buildWeightChip(isCustomWeight ? weightLabel(weight) : "Autre", isCustomWeight ? "Autre" : "…", isCustomWeight, chooseCustomWeight)
                            : buildWeightChip(weightLabel(value), weightNames[value], weight == value, () => setState(() => weight = value)),
                      ),
                    // The second row has one chip less: the same width as the first
                    if (row.length < 4) const Expanded(child: SizedBox()),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const .only(left: 4, top: AppSpacing.s),
          child: CustomText(weightSentence(weight), style: AppStyles.footer(context).copyWith(color: AppColors.secondaryText.adaptTo(context))),
        ),

        // Group
        if (subject != null) ...[
          sectionTitle("Groupe"),
          ListSection(
            footer: isInGroup ? null : "Les notes d'un même groupe comptent ensemble comme une seule note.",
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedLayers01,
                title: "Fait partie d'un groupe",
                trailing: CupertinoSwitch(
                  activeTrackColor: AppColors.accent,
                  value: isInGroup,
                  onChanged: (value) => setState(() {
                    isInGroup = value;
                    if (!value) groupName = null;
                  }),
                ),
              ),
              if (isInGroup) ...[
                for (final existingGroupName in getGroups())
                  ListTile(
                    buildChevron: false,
                    onTap: () => setState(() => groupName = existingGroupName),
                    leading: const SizedBox(width: 32),
                    trailing: groupName == existingGroupName
                        ? HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 20, color: AppColors.tint.adaptTo(context))
                        : null,
                    child: Text(existingGroupName, style: AppStyles.primaryText(context)),
                  ),
                ListTile(
                  buildChevron: false,
                  leading: const SizedBox(width: 32),
                  onTap: () => showCupertinoDialog(
                    context: context,
                    builder: (_) {
                      final controller = TextEditingController();
                      return Dialog.entry(
                        title: "Nouveau groupe",
                        placeholder: "Nom du groupe (TP, Vocs, ...)",
                        controller: controller,
                        onConfirm: () {
                          final newName = controller.text.trim();
                          if (newName.isNotEmpty) setState(() => groupName = newName);
                        },
                      );
                    },
                  ),
                  child: Text("Nouveau groupe…", style: AppStyles.primaryText(context).copyWith(color: AppColors.tint.adaptTo(context))),
                ),
              ],
            ],
          ),
        ],

        sectionTitle("Remarques"),
        Field(placeholder: "Ce qui compte pour cette note…", controller: detailsController, minLines: 3, maxLines: 5),

        if (editMode) ...[
          const SizedBox(height: AppSpacing.section),
          ListSection(
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedDelete04,
                title: "Supprimer la note",
                isDestructive: true,
                buildChevron: false,
                onTap: () => showCupertinoDialog(
                  context: context,
                  builder: (_) => Dialog.confirm(
                    content: "Êtes-vous sûr de vouloir supprimer cette note ?",
                    isDestructive: true,
                    onConfirm: () {
                      allGrades.remove(widget.toEdit);
                      database.grades.delete(widget.toEdit!);
                      Navigator.of(context).pop(widget.toEdit);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
