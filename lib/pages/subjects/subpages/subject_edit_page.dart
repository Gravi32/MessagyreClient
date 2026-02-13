import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';

class NewSubjectPage extends StatefulWidget {
  final Subject? toEdit;

  const NewSubjectPage({super.key, this.toEdit});

  @override
  State<StatefulWidget> createState() => _NewSubjectPageState();
}

final List<IconData> availableIcons = [
  Icons.menu_book,
  Icons.auto_stories,
  Icons.translate,
  Icons.language,
  Icons.public,
  Icons.record_voice_over,
  Icons.chat,
  Icons.forum,
  Icons.comment,
  Icons.speaker_notes,
  Icons.calculate,
  Icons.functions,
  Icons.percent,
  Icons.stacked_line_chart,
  Icons.grid_4x4,
  Icons.timeline,
  Icons.assessment,
  Icons.show_chart,
  Icons.bar_chart,
  Icons.trending_up,
  Icons.eco,
  Icons.spa,
  Icons.pets,
  Icons.bug_report,
  Icons.local_florist,
  Icons.nature,
  Icons.nature_people,
  Icons.coronavirus,
  Icons.health_and_safety,
  Icons.bloodtype,
  Icons.science,
  Icons.biotech,
  Icons.bubble_chart,
  Icons.local_fire_department,
  Icons.ac_unit,
  Icons.opacity,
  Icons.waves,
  Icons.grain,
  Icons.all_inclusive,
  Icons.bolt,
  Icons.rocket_launch,
  Icons.speed,
  Icons.flash_on,
  Icons.waves,
  Icons.electric_bolt,
  Icons.sensors,
  Icons.radio,
  Icons.autorenew,
  Icons.device_hub,
  Icons.code,
  Icons.computer,
  Icons.memory,
  Icons.terminal,
  Icons.storage,
  Icons.data_object,
  Icons.developer_mode,
  Icons.smartphone,
  Icons.desktop_mac,
  Icons.devices,
  Icons.account_balance,
  Icons.museum,
  Icons.gavel,
  Icons.map,
  Icons.travel_explore,
  Icons.explore,
  Icons.place,
  Icons.flag,
  Icons.landscape,
  Icons.public,
  Icons.psychology,
  Icons.lightbulb,
  Icons.psychology_alt,
  Icons.forum,
  Icons.question_mark,
  Icons.menu_book,
  Icons.auto_stories,
  Icons.school,
  Icons.local_library,
  Icons.comment_bank,
  Icons.palette,
  Icons.brush,
  Icons.color_lens,
  Icons.image,
  Icons.music_note,
  Icons.album,
  Icons.headphones,
  Icons.library_music,
  Icons.mic,
  Icons.audiotrack,
  Icons.account_balance_wallet,
  Icons.gavel,
  Icons.attach_money,
  Icons.trending_up,
  Icons.business_center,
  Icons.request_quote,
  Icons.credit_card,
  Icons.shopping_cart,
  Icons.sell,
  Icons.storefront,
  Icons.sports_soccer,
  Icons.fitness_center,
  Icons.directions_run,
  Icons.sports_basketball,
  Icons.sports_gymnastics,
  Icons.sports_tennis,
  Icons.sports_baseball,
  Icons.sports_volleyball,
  Icons.sports_hockey,
  Icons.sports_motorsports,
  Icons.engineering,
  Icons.category,
  Icons.miscellaneous_services,
  Icons.build,
  Icons.architecture,
  Icons.design_services,
  Icons.light_mode,
  Icons.dark_mode,
  Icons.extension,
  Icons.new_releases,
];

final List<Color> availableColors = [
  // Reds / Pinks
  const Color(0xFFE53935),
  const Color(0xFFD81B60),
  const Color(0xFFC2185B),
  const Color(0xFFF06292),
  const Color(0xFFF48FB1),

  // Oranges / Yellows
  const Color(0xFFFF9800),
  const Color(0xFFFFA726),
  const Color(0xFFFFB74D),
  const Color(0xFFFFF176),
  const Color(0xFFFFEB3B),

  // Greens
  const Color(0xFF43A047),
  const Color(0xFF66BB6A),
  const Color(0xFF81C784),
  const Color(0xFFA5D6A7),
  const Color(0xFF8BC34A),

  // Blues
  const Color(0xFF1E88E5),
  const Color(0xFF1976D2),
  const Color(0xFF64B5F6),
  const Color(0xFF90CAF9),
  const Color(0xFF42A5F5),

  // Purples
  const Color(0xFF8E24AA),
  const Color(0xFFAB47BC),
  const Color(0xFFBA68C8),
  const Color(0xFFE1BEE7),
  const Color(0xFF9C27B0),

  // Browns / Neutrals
  const Color(0xFF6D4C41),
  const Color(0xFFA1887F),
  const Color(0xFFD7CCC8),
  const Color(0xFF795548),
  const Color(0xFF8D6E63),

  // Teals / Cyans
  const Color(0xFF009688),
  const Color(0xFF26A69A),
  const Color(0xFF4DB6AC),
  const Color(0xFF80CBC4),
  const Color(0xFF00ACC1),

  // Deep Colors / Dark Variants
  const Color(0xFF0D47A1),
  const Color(0xFF004D40),
  const Color(0xFF1B5E20),
  const Color(0xFF4A148C),
  const Color(0xFFB71C1C),
];

class _NewSubjectPageState extends State<NewSubjectPage> {
  final globals = GlobalsService();
  final database = DatabaseService();

  late final bool editMode = widget.toEdit != null;
  late final TextEditingController nameController = TextEditingController(text: widget.toEdit?.name);

  final subjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();
  final contentFocusNode = FocusNode();

  late final ValueNotifier<Color> colorNotifier = ValueNotifier(widget.toEdit?.color ?? AppColors.grey);
  late final ValueNotifier<IconData> iconNotifier = ValueNotifier(widget.toEdit?.icon ?? Icons.question_mark_rounded);

  late final bool canBeDeleted =
      !(!editMode ||
          (database.assignments.getAll().any((assignment) => assignment.subject.value?.code == widget.toEdit?.code) ||
              database.grades.getAll().any((grade) => grade.subject.value?.code == widget.toEdit?.code)));

  void confirmSubject() async {
    if (nameController.text.isEmpty) return;

    final subject = widget.toEdit ?? Subject();
    subject
      ..name = nameController.text
      ..code = widget.toEdit?.code ?? nameController.text.normalize().replaceAll(' ', '_').toLowerCase()
      ..iconCodePoint = iconNotifier.value.codePoint
      ..colorValue = colorNotifier.value.toInt();

    await database.subjects.save(subject);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void unfocusFields() {
    subjectFocusNode.unfocus();
    titleFocusNode.unfocus();
    contentFocusNode.unfocus();
  }

  void showMissingInfoPopup() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text("Nom manquant"),
          content: const CustomText("Pour créer cette branche entrez un nom !", textAlign: TextAlign.center),
          actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(dialogContext))],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameController.dispose();
    subjectFocusNode.dispose();
    titleFocusNode.dispose();
    contentFocusNode.dispose();
    iconNotifier.dispose();
    colorNotifier.dispose();
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
          middle: Text(editMode ? "Modifier la branche" : "Nouvelle branche"),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: nameController.text.isNotEmpty ? confirmSubject : showMissingInfoPopup,
            child: Text(
              editMode ? "Terminé" : "Ajouter",
              style: TextStyle(
                color: nameController.text.isNotEmpty ? AppColors.text.adaptTo(context) : AppColors.inactive.adaptTo(context),
                fontWeight: FontWeight.w600,
              ),
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
                      controller: nameController,
                      focusNode: titleFocusNode,
                      decoration: const BoxDecoration(),
                      placeholder: "Titre de la branche",
                      minLines: 1,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                      placeholderStyle: TextStyle(color: AppColors.placeholderText.adaptTo(context), fontWeight: FontWeight.w400),
                      onTapOutside: (event) => titleFocusNode.unfocus(),
                    ),
                  ),
                ],
              ),
              CupertinoListSection.insetGrouped(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: const Text("Icône"),
                children: [
                  CupertinoListTile.notched(
                    padding: const EdgeInsets.all(8),
                    backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    title: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ValueListenableBuilder<Color>(
                        valueListenable: colorNotifier,
                        builder: (context, selectedColor, _) {
                          return ValueListenableBuilder<IconData>(
                            valueListenable: iconNotifier,
                            builder: (context, selectedIcon, _) {
                              return GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 6, crossAxisSpacing: 6),
                                shrinkWrap: true,
                                itemCount: availableIcons.length,
                                itemBuilder: (context, index) {
                                  final thisIcon = availableIcons[index];
                                  final isSelected = thisIcon == selectedIcon;

                                  return CupertinoPressable(
                                    decoration: BoxDecoration(
                                      color: isSelected ? colorNotifier.value.withBrightness(-.15) : AppColors.secondaryBackground.adaptTo(context),
                                      border: Border.all(color: isSelected ? colorNotifier.value : AppColors.transparent),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Icon(thisIcon, size: 23, color: AppColors.white)),
                                    onTap: () => iconNotifier.value = thisIcon,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              CupertinoListSection.insetGrouped(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                backgroundColor: AppColors.transparent,
                header: const Text("Couleur"),
                children: [
                  CupertinoListTile.notched(
                    padding: const EdgeInsets.all(8),
                    backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                    title: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ValueListenableBuilder<Color>(
                        valueListenable: colorNotifier,
                        builder: (context, selectedColor, _) {
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 8, crossAxisSpacing: 8),
                            shrinkWrap: true,
                            itemCount: availableColors.length,
                            itemBuilder: (context, index) {
                              final thisColor = availableColors[index];
                              final isSelected = thisColor == selectedColor;

                              return CupertinoPressable(
                                decoration: BoxDecoration(
                                  color: thisColor,
                                  border: Border.all(color: isSelected ? AppColors.white : AppColors.transparent),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SizedBox.shrink(),
                                onTap: () => colorNotifier.value = thisColor,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              if (editMode)
                CupertinoListSection.insetGrouped(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.transparent,
                  header: const SizedBox.shrink(),
                  footer:
                      canBeDeleted
                          ? null
                          : Padding(
                            padding: EdgeInsetsGeometry.symmetric(horizontal: 6, vertical: 6),
                            child: Text(
                              "Cette branche ne peut pas être supprimé car elle est utilisée par des notes ou des devoirs !",
                              style: TextStyle(color: AppColors.quaternaryText.adaptTo(context), fontSize: 14),
                            ),
                          ),
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.tertiaryBackground.adaptTo(context),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedDelete04, color: canBeDeleted ? AppColors.red : AppColors.inactive.adaptTo(context)),
                      title: Text("Supprimer la note", style: TextStyle(color: canBeDeleted ? AppColors.red : AppColors.inactive.adaptTo(context))),

                      onTap:
                          canBeDeleted
                              ? () {
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
                                              database.subjects.delete(widget.toEdit!);
                                              Navigator.of(context).pop();
                                              Navigator.of(context).pop(widget.toEdit);
                                            },
                                          ),
                                        ],
                                      ),
                                );
                              }
                              : null,
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
