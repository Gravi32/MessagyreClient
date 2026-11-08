import 'dart:math';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class NewCompositeSubjectPage extends StatefulWidget {
  final CompositeSubject? toEdit;

  const NewCompositeSubjectPage({super.key, this.toEdit});

  @override
  State<StatefulWidget> createState() => _NewCompositeSubjectPageState();
}

class _NewCompositeSubjectPageState extends State<NewCompositeSubjectPage> {
  final globals = GlobalsService();
  final database = DatabaseService();

  late final bool editMode = widget.toEdit != null;
  late final TextEditingController titleController = TextEditingController(text: widget.toEdit?.name);
  late final TextEditingController firstSubjectFieldController = TextEditingController(text: firstSubject?.name);
  late final TextEditingController secondSubjectFieldController = TextEditingController(text: secondSubject?.name);
  late final TextEditingController thirdSubjectFieldController = TextEditingController(text: thirdSubject?.name);

  final firstSubjectFocusNode = FocusNode();
  final secondSubjectFocusNode = FocusNode();
  final thirdSubjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();

  late Subject? firstSubject = widget.toEdit?.firstSubject.value;
  late Subject? secondSubject = widget.toEdit?.secondSubject.value;
  late double firstSubjectPeriodsPerWeek = widget.toEdit?.firstSubjectPeriodsPerWeek.clamp(.5, 10) ?? 5;
  late double secondSubjectPeriodsPerWeek = widget.toEdit?.secondSubjectPeriodsPerWeek.clamp(.5, 10) ?? 5;

  /// The third sub-subject is optional
  late bool hasThirdSubject = widget.toEdit?.thirdSubject.value != null && (widget.toEdit?.thirdSubjectPeriodsPerWeek ?? 0) > 0;
  late Subject? thirdSubject = hasThirdSubject ? widget.toEdit?.thirdSubject.value : null;
  late double thirdSubjectPeriodsPerWeek = hasThirdSubject ? widget.toEdit!.thirdSubjectPeriodsPerWeek.clamp(.5, 10) : 5;
  bool isMissingThirdSubject = false;

  bool get canBeConfirmed =>
      titleController.text.isNotEmpty && firstSubject != null && secondSubject != null && (!hasThirdSubject || thirdSubject != null) && _distinctSubjects;

  /// The same subject can't be used twice
  bool get _distinctSubjects {
    final codes = [firstSubject?.code, secondSubject?.code, if (hasThirdSubject) thirdSubject?.code].whereType<String>().toList();
    return codes.toSet().length == codes.length;
  }

  bool isMissingTitle = false;
  bool isMissingFirstSubject = false;
  bool isMissingSecondSubject = false;

  void confirmCompositeSubject() async {
    if (!canBeConfirmed) return;

    final compositeSubject = widget.toEdit ?? CompositeSubject();
    compositeSubject
      ..name = titleController.text
      ..code = widget.toEdit?.code ?? titleController.text.normalize().replaceAll(' ', '_').toLowerCase()
      ..firstSubject.value = firstSubject
      ..secondSubject.value = secondSubject
      ..firstSubjectPeriodsPerWeek = firstSubjectPeriodsPerWeek
      ..secondSubjectPeriodsPerWeek = secondSubjectPeriodsPerWeek
      ..thirdSubject.value = hasThirdSubject ? thirdSubject : null
      ..thirdSubjectPeriodsPerWeek = hasThirdSubject ? thirdSubjectPeriodsPerWeek : 0;

    await database.compositeSubjects.save(compositeSubject);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void unfocusFields() {
    firstSubjectFocusNode.unfocus();
    secondSubjectFocusNode.unfocus();
    thirdSubjectFocusNode.unfocus();
    titleFocusNode.unfocus();
  }

  void showMissingInfoPopup() {
    showCupertinoDialog(
      context: context,
      builder: (_) {
        final missingInfos = [];

        if (titleController.text.isEmpty) {
          missingInfos.add("un *titre*");
          isMissingTitle = true;
        }
        if (firstSubject == null) {
          missingInfos.add("la *première sous-branche*");
          isMissingFirstSubject = true;
        }
        if (secondSubject == null) {
          missingInfos.add("la *deuxième sous-branche*");
          isMissingSecondSubject = true;
        }
        if (hasThirdSubject && thirdSubject == null) {
          missingInfos.add("la *troisième sous-branche*");
          isMissingThirdSubject = true;
        }

        if (missingInfos.isEmpty && !_distinctSubjects) {
          return const Dialog(title: "Sous-branches identiques", content: "Chaque sous-branche doit être *différente*.");
        }

        return Dialog(
          title: "Informations manquantes",
          content: "Pour créer cette branche, entrez ${missingInfos.join(" et ")} !",
          options: {"OK": () => setState(() {})},
        );
      },
    );
  }

  Widget buildSubjectFields({
    required String title,
    required Subject? subject,
    required double periodsPerWeek,
    required TextEditingController subjectFieldController,
    required FocusNode subjectFieldFocusNode,
    required Function(Subject) onSubjectSelected,
    required Function(double) onPeriodsPerWeekChanged,
    required bool isMissingInfo,
    bool showHint = false,
  }) {
    return ListSection(
      margin: .only(top: 16),
      footer: showHint ? "Merci de remplir les champs obligatoires *" : null,
      children: [
        ListTile(
          buildChevron: false,
          child: Row(
            spacing: 12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                child: subject == null
                    ? CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.placeholderText.adaptTo(context))
                    : SubjectBadge(subject: subject),
              ),
              Expanded(
                child: SubjectAutocomplete(
                  placeholder: "$title *",
                  controller: subjectFieldController,
                  focusNode: subjectFieldFocusNode,
                  onSubjectSelected: onSubjectSelected,
                  style: AppStyles.section(context),
                  placeholderStyle: TextStyle(color: isMissingInfo ? AppColors.red : AppColors.placeholderText.adaptTo(context), fontWeight: .w400),
                ),
              ),
              if (isMissingInfo) const HugeIcon(icon: AppIcons.missing, color: AppColors.red, size: 18),
            ],
          ),
        ),

        ListTile(
          buildChevron: false,
          child: Row(
            spacing: 12,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 40),
                height: 32,
                child: Center(
                  child: FittedBox(
                    fit: .scaleDown,
                    child: Text(periodsPerWeek.removeTrailingZero(), style: AppStyles.header(context)),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoSlider(
                  min: 0,
                  max: 10,
                  divisions: 20,
                  value: periodsPerWeek.toDouble(),
                  activeColor: subject?.color ?? AppColors.grey,
                  onChanged: (newValue) => onPeriodsPerWeekChanged(max(.5, newValue)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<({Subject? subject, double periods})> get calculationParts => [
    (subject: firstSubject, periods: firstSubjectPeriodsPerWeek),
    (subject: secondSubject, periods: secondSubjectPeriodsPerWeek),
    if (hasThirdSubject) (subject: thirdSubject, periods: thirdSubjectPeriodsPerWeek),
  ];

  Widget buildCalculationsTile() {
    return ListSection(
      margin: .only(top: 24),
      title: "Calcul de la moyenne finale",
      children: [
        ListTile(
          buildChevron: false,
          child: Column(
            mainAxisSize: .min,
            spacing: 4,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final (index, part) in calculationParts.indexed) ...[
                    if (index > 0) Text("+", style: AppStyles.secondaryHeader(context)),
                    Text(part.periods.removeTrailingZero(), style: AppStyles.header(context).copyWith(color: part.subject?.color)),
                    Text(part.subject?.name ?? "Sous-branche ${index + 1}", maxLines: 1, overflow: .ellipsis, style: AppStyles.secondaryHeader(context)),
                  ],
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(height: 1, width: constraints.maxWidth * 0.8, color: AppColors.text.adaptTo(context));
                },
              ),
              Text(calculationParts.fold(0.0, (total, part) => total + part.periods).removeTrailingZero(), style: AppStyles.header(context)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    titleController.dispose();
    firstSubjectFieldController.dispose();
    secondSubjectFieldController.dispose();
    thirdSubjectFieldController.dispose();
    firstSubjectFocusNode.dispose();
    secondSubjectFocusNode.dispose();
    thirdSubjectFocusNode.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.form(
        context,
        title: editMode ? "Modifier la branche" : "Nouvelle branche",
        trailing: Button.icon(
          context,
          onTap: canBeConfirmed ? confirmCompositeSubject : showMissingInfoPopup,
          icon: editMode ? HugeIcons.strokeRoundedTick02 : HugeIcons.strokeRoundedAdd01,
        ),
      ),
      child: ListView(
        children: [
          Field(
            placeholder: "Titre de la branche *",
            controller: titleController,
            focusNode: titleFocusNode,
            onChanged: (_) => setState(() => isMissingTitle = false),
          ),

          buildSubjectFields(
            title: "Sous-branche 1",
            subject: firstSubject,
            periodsPerWeek: firstSubjectPeriodsPerWeek,
            subjectFieldController: firstSubjectFieldController,
            subjectFieldFocusNode: firstSubjectFocusNode,
            onSubjectSelected: (selectedSubject) => setState(() {
              firstSubject = selectedSubject;
              isMissingFirstSubject = false;
            }),
            onPeriodsPerWeekChanged: (newAmount) => setState(() => firstSubjectPeriodsPerWeek = newAmount),
            isMissingInfo: isMissingFirstSubject,
          ),

          buildSubjectFields(
            title: "Sous-branche 2",
            subject: secondSubject,
            periodsPerWeek: secondSubjectPeriodsPerWeek,
            subjectFieldController: secondSubjectFieldController,
            subjectFieldFocusNode: secondSubjectFocusNode,
            onSubjectSelected: (selectedSubject) => setState(() {
              secondSubject = selectedSubject;
              isMissingSecondSubject = false;
            }),
            onPeriodsPerWeekChanged: (newAmount) => setState(() => secondSubjectPeriodsPerWeek = newAmount),
            isMissingInfo: isMissingSecondSubject,
            showHint: !hasThirdSubject,
          ),

          if (hasThirdSubject) ...[
            buildSubjectFields(
              title: "Sous-branche 3",
              subject: thirdSubject,
              periodsPerWeek: thirdSubjectPeriodsPerWeek,
              subjectFieldController: thirdSubjectFieldController,
              subjectFieldFocusNode: thirdSubjectFocusNode,
              onSubjectSelected: (selectedSubject) => setState(() {
                thirdSubject = selectedSubject;
                isMissingThirdSubject = false;
              }),
              onPeriodsPerWeekChanged: (newAmount) => setState(() => thirdSubjectPeriodsPerWeek = newAmount),
              isMissingInfo: isMissingThirdSubject,
              showHint: true,
            ),
            ListSection(
              margin: const .only(top: 8),
              children: [
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedRemoveCircle,
                  title: "Retirer la troisième sous-branche",
                  isDestructive: true,
                  buildChevron: false,
                  onTap: () => setState(() {
                    hasThirdSubject = false;
                    thirdSubject = null;
                    thirdSubjectFieldController.clear();
                    isMissingThirdSubject = false;
                  }),
                ),
              ],
            ),
          ] else
            ListSection(
              margin: const .only(top: 16),
              footer: "Une branche composée peut réunir deux ou trois sous-branches.",
              children: [
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedAddCircle,
                  title: "Ajouter une troisième sous-branche",
                  buildChevron: false,
                  onTap: () => setState(() => hasThirdSubject = true),
                ),
              ],
            ),

          buildCalculationsTile(),

          // Delete button
          if (editMode)
            ListSection(
              margin: const .only(top: 24),
              footer: "En supprimeant cette branche, ses notes resteront dans ses sous-branches.",
              children: [
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedDelete04,
                  title: "Supprimer cette branche",
                  isDestructive: true,
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => Dialog.confirm(
                        content: "Êtes-vous sûr de vouloir *supprimer la branche composée \"${widget.toEdit?.name}\"* ?",
                        isDestructive: true,
                        onConfirm: () {
                          database.compositeSubjects.delete(widget.toEdit!);
                          Navigator.of(context).pop(widget.toEdit);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),

          BottomSpacing(),
        ],
      ),
    );
  }
}
