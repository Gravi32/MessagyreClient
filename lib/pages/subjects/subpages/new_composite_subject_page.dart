import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

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

  final subjectFocusNode = FocusNode();
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
    subjectFocusNode.unfocus();
    titleFocusNode.unfocus();
  }

  void showMissingInfoPopup() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
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

        return CupertinoAlertDialog(
          title: Text("Informations manquantes"),
          content: CustomText("Pour créer ce devoir entrez ${missingInfos.join(" et ")} !", textAlign: TextAlign.center),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildSubjectFields({
    required String title,
    required Subject? subject,
    required double periodsPerWeek,
    required TextEditingController subjectFieldController,
    required Function(Subject) onSubjectSelected,
    required Function(double) onPeriodsPerWeekChanged,
    required bool isMissingInfo,
    bool showHint = false,
  }) {
    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: AppColors.transparent,
      header: Text(title),
      footer:
          showHint
              ? Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Merci de remplir les champs obligatoires *",
                  style: TextStyle(fontSize: 14, color: canBeConfirmed ? AppColors.secondaryText.adaptTo(context) : AppColors.yellow),
                ),
              )
              : null,
      children: [
        Container(
          color: AppColors.tertiaryBackground.adaptTo(context),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text("Branche", style: TextStyle(fontWeight: FontWeight.w600)),
              Row(
                spacing: 12,
                children: [
                  SizedBox.square(
                    dimension: 32,
                    child:
                        subject == null
                            ? HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.placeholderText.adaptTo(context))
                            : SubjectBadge(subject: subject),
                  ),

                  Expanded(
                    child: SubjectAutocomplete(
                      placeholder: "Entrez une branche *",
                      controller: subjectFieldController,
                      onSelected: onSubjectSelected,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      placeholderStyle: TextStyle(color: isMissingInfo ? AppColors.red : null, fontWeight: FontWeight.w400),
                    ),
                  ),

                  isMissingInfo
                      ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18)
                      : Opacity(
                        opacity: .5,
                        child: HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit02, color: AppColors.text.adaptTo(context), strokeWidth: 1),
                      ),
                ],
              ),

              Divider(color: AppColors.secondaryBackground.adaptTo(context)),

              Text("Périodes par semaine", style: TextStyle(fontWeight: FontWeight.w600)),

              Row(
                spacing: 12,
                children: [
                  SizedBox.square(
                    dimension: 32,
                    child: Center(
                      child: Text(
                        periodsPerWeek.removeTrailingZero(),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCalculationsTile() {
    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: AppColors.transparent,
      header: const Text("Calcul"),
      children: [
        Container(
          width: double.infinity,
          color: AppColors.tertiaryBackground.adaptTo(context),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Center(
            child: IntrinsicWidth(
              child: Column(
                spacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        firstSubjectPeriodsPerWeek.removeTrailingZero(),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: firstSubject?.color),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        firstSubject?.name ?? "Sous-branche 1",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      Text("+"),
                      const SizedBox(width: 6),
                      Text(
                        secondSubjectPeriodsPerWeek.removeTrailingZero(),
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: secondSubject?.color),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        secondSubject?.name ?? "Sous-branche 2",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  Container(height: 1, width: double.infinity, color: AppColors.text.adaptTo(context)),

                  Text(
                    (firstSubjectPeriodsPerWeek + secondSubjectPeriodsPerWeek).removeTrailingZero(),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
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
    subjectFocusNode.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: unfocusFields,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppColors.transparent,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Annuler", style: TextStyle(color: AppColors.text.adaptTo(context))),
          ),
          middle: Text("Branche composée"),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: canBeConfirmed ? confirmCompositeSubject : showMissingInfoPopup,
            child: Text(
              editMode ? "Terminé" : "Ajouter",
              style: TextStyle(color: canBeConfirmed ? AppColors.text.adaptTo(context) : AppColors.inactive.adaptTo(context), fontWeight: FontWeight.w600),
            ),
          ),
        ),
        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
        child: SafeArea(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            children: [
              CupertinoListSection.insetGrouped(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: const Text("Titre"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    title: CupertinoTextField(
                      controller: titleController,
                      focusNode: titleFocusNode,
                      decoration: const BoxDecoration(),
                      placeholder: "Titre de la branche *",
                      maxLines: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                      placeholderStyle: TextStyle(
                        color: isMissingTitle ? AppColors.red : AppColors.placeholderText.adaptTo(context),
                        fontWeight: FontWeight.w400,
                      ),
                      onTap: () => setState(() => isMissingTitle = false),
                      onTapOutside: (event) => titleFocusNode.unfocus(),
                    ),
                    trailing: isMissingTitle ? Icon(CupertinoIcons.exclamationmark_circle_fill, color: AppColors.red, size: 18) : null,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              buildSubjectFields(
                title: "Sous-branche 1",
                subject: firstSubject,
                periodsPerWeek: firstSubjectPeriodsPerWeek,
                subjectFieldController: firstSubjectFieldController,
                onSubjectSelected:
                    (selectedSubject) => setState(() {
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
                onSubjectSelected:
                    (selectedSubject) => setState(() {
                      secondSubject = selectedSubject;
                      isMissingSecondSubject = false;
                    }),
                onPeriodsPerWeekChanged: (newAmount) => setState(() => secondSubjectPeriodsPerWeek = newAmount),
                isMissingInfo: isMissingSecondSubject,
                showHint: true,
              ),

              const SizedBox(height: 8),

              buildCalculationsTile(),

              // Delete button
              if (editMode)
                CupertinoListSection.insetGrouped(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.transparent,
                  header: const SizedBox.shrink(),
                  footer: Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 6, vertical: 6),
                    child: Text(
                      "En supprimeant cette branche ses notes resteront dans ses sous-branches.",
                      style: TextStyle(color: AppColors.quaternaryText.adaptTo(context), fontSize: 14),
                    ),
                  ),
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: AppColors.red),
                      title: Text("Supprimer cette branche", style: TextStyle(color: AppColors.red)),

                      onTap: () {
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (_) => CupertinoAlertDialog(
                                title: Text("Supprimer cette branche"),
                                content: Text("Êtes-vous sûr de vouloir supprimer cette note ?"),
                                actions: [
                                  CupertinoDialogAction(child: Text("Annuler"), onPressed: () => Navigator.pop(context)),
                                  CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: Text("Supprimer"),
                                    onPressed: () {
                                      database.compositeSubjects.delete(widget.toEdit!);
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

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
