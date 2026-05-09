import 'dart:math';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
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
import 'package:messagyre_client/utility/widgets/field.dart';
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

  final firstSubjectFocusNode = FocusNode();
  final secondSubjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();

  late Subject? firstSubject = widget.toEdit?.firstSubject.value;
  late Subject? secondSubject = widget.toEdit?.secondSubject.value;
  late double firstSubjectPeriodsPerWeek = widget.toEdit?.firstSubjectPeriodsPerWeek.clamp(.5, 10) ?? 5;
  late double secondSubjectPeriodsPerWeek = widget.toEdit?.secondSubjectPeriodsPerWeek.clamp(.5, 10) ?? 5;

  bool get canBeConfirmed => titleController.text.isNotEmpty && firstSubjectFieldController.text.isNotEmpty && secondSubjectFieldController.text.isNotEmpty;

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
      ..secondSubjectPeriodsPerWeek = secondSubjectPeriodsPerWeek;

    await database.compositeSubjects.save(compositeSubject);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void unfocusFields() {
    firstSubjectFocusNode.unfocus();
    secondSubjectFocusNode.unfocus();
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

        return Dialog(
          title: "Informations manquantes",
          content: "Pour créer ce devoir entrez ${missingInfos.join(" et ")} !",
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
                  style: const TextStyle(fontSize: 20, fontWeight: .w700),
                  placeholderStyle: TextStyle(color: isMissingInfo ? AppColors.red : AppColors.placeholderText.adaptTo(context), fontWeight: .w400),
                ),
              ),
              if (isMissingInfo) const Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18),
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
                    fit: BoxFit.scaleDown,
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
              Row(
                mainAxisAlignment: .center,
                spacing: 6,
                children: [
                  Text(firstSubjectPeriodsPerWeek.removeTrailingZero(), style: AppStyles.header(context).copyWith(color: firstSubject?.color)),
                  Flexible(
                    child: Text(
                      firstSubject?.name ?? "Sous-branche 1",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.secondaryHeader(context),
                    ),
                  ),

                  Text("+", style: AppStyles.secondaryHeader(context)),

                  Text(secondSubjectPeriodsPerWeek.removeTrailingZero(), style: AppStyles.header(context).copyWith(color: secondSubject?.color)),
                  Flexible(
                    child: Text(
                      secondSubject?.name ?? "Sous-branche 2",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.secondaryHeader(context),
                    ),
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(height: 1, width: constraints.maxWidth * 0.8, color: AppColors.text.adaptTo(context));
                },
              ),
              Text((firstSubjectPeriodsPerWeek + secondSubjectPeriodsPerWeek).removeTrailingZero(), style: AppStyles.header(context)),
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
    firstSubjectFocusNode.dispose();
    secondSubjectFocusNode.dispose();
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
            showHint: true,
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
