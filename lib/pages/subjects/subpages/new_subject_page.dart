import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/material.dart' show Icons;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/field.dart';
import 'package:messagyre_client/utility/widgets/grade_picker.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class NewSubjectPage extends StatefulWidget {
  final Subject? toEdit;

  const NewSubjectPage({super.key, this.toEdit});

  @override
  State<StatefulWidget> createState() => _NewSubjectPageState();
}

final List<IconData> availableIcons = [
  // Education / Books
  Icons.menu_book,
  Icons.auto_stories,
  Icons.school,
  Icons.local_library,
  Icons.comment_bank,
  Icons.translate,
  Icons.language,
  Icons.public,
  Icons.record_voice_over,
  Icons.chat,
  Icons.forum,
  Icons.comment,
  Icons.speaker_notes,
  Icons.question_mark,
  Icons.book,
  Icons.book_online,
  Icons.menu_book_outlined,

  // Math / Statistics
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
  Icons.bubble_chart,
  Icons.insert_chart,
  Icons.insert_chart_outlined,
  Icons.query_stats,

  // Science / Biology / Chemistry
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
  Icons.psychology,
  Icons.psychology_alt,
  Icons.medical_services,
  Icons.medication,
  Icons.vaccines,

  // Physics / Chemistry / Energy
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
  Icons.electric_bolt,
  Icons.sensors,
  Icons.radio,
  Icons.battery_charging_full,
  Icons.air,
  Icons.water,
  Icons.light_mode,
  Icons.dark_mode,

  // Computing / Technology
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
  Icons.router,
  Icons.sim_card,
  Icons.settings_input_component,
  Icons.watch,
  Icons.keyboard,
  Icons.mouse,
  Icons.print,

  // Geography / History / Society
  Icons.account_balance,
  Icons.museum,
  Icons.gavel,
  Icons.map,
  Icons.travel_explore,
  Icons.explore,
  Icons.place,
  Icons.flag,
  Icons.landscape,
  Icons.terrain,
  Icons.emoji_flags,
  Icons.sailing,
  Icons.park,
  Icons.campaign,

  // Art / Music / Creativity
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
  Icons.photo_camera,
  Icons.theaters,
  Icons.movie,
  Icons.lightbulb,
  Icons.design_services,
  Icons.architecture,
  Icons.photo_album,
  Icons.video_collection,
  Icons.video_camera_back,

  // Economy / Business / Finance
  Icons.account_balance_wallet,
  Icons.attach_money,
  Icons.business_center,
  Icons.request_quote,
  Icons.credit_card,
  Icons.shopping_cart,
  Icons.sell,
  Icons.storefront,
  Icons.monetization_on,
  Icons.wallet_giftcard,
  Icons.corporate_fare,
  Icons.price_change,
  Icons.money_off,
  Icons.account_tree,
  Icons.analytics,

  // Sports / Physical Education
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
  Icons.sports_handball,
  Icons.sports_cricket,
  Icons.sports_esports,
  Icons.sports_kabaddi,
  Icons.sports_rugby,
  Icons.sports_mma,

  // Engineering / Technology / Misc
  Icons.engineering,
  Icons.category,
  Icons.miscellaneous_services,
  Icons.build,
  Icons.extension,
  Icons.new_releases,
  Icons.settings,
  Icons.settings_applications,
  Icons.build_circle,
  Icons.science_outlined,
  Icons.auto_fix_high,
];

final List<Color> availableColors = [
  // Red
  const Color(0xFF880E4F),
  const Color(0xFF9A0036),
  const Color(0xFFB71C1C),
  const Color(0xFFC62828),
  const Color(0xFFD32F2F),
  const Color(0xFFE53935),

  // Orange
  const Color(0xFFE65100),
  const Color(0xFFEF6C00),
  const Color(0xFFF57C00),
  const Color(0xFFFF6F00),
  const Color(0xFFFB8C00),
  const Color(0xFFFFA726),

  // Green
  const Color(0xFF1B5E20),
  const Color(0xFF33691E),
  const Color(0xFF2E7D32),
  const Color(0xFF388E3C),
  const Color(0xFF43A047),
  const Color(0xFF4CAF50),

  // Blue
  const Color(0xFF0D47A1),
  const Color(0xFF1565C0),
  const Color(0xFF1976D2),
  const Color(0xFF1E88E5),
  const Color(0xFF2196F3),
  const Color(0xFF42A5F5),

  // Purple
  const Color(0xFF311B92),
  const Color(0xFF4A148C),
  const Color(0xFF4527A0),
  const Color(0xFF512DA8),
  const Color(0xFF6A1B9A),
  const Color(0xFF7B1FA2),

  // Brown
  const Color(0xFF3E2723),
  const Color(0xFF4B2E2B),
  const Color(0xFF4E342E),
  const Color(0xFF5D4037),
  const Color(0xFF6D4C41),
  const Color(0xFF795548),

  // Teal / Cyan
  const Color(0xFF004D40),
  const Color(0xFF006064),
  const Color(0xFF00695C),
  const Color(0xFF00796B),
  const Color(0xFF00838F),
  const Color(0xFF009688),
];

class _NewSubjectPageState extends State<NewSubjectPage> {
  final globals = GlobalsService();
  final database = DatabaseService();

  late final bool editMode = widget.toEdit != null;
  late final TextEditingController titleController = TextEditingController(text: widget.toEdit?.name);

  final subjectFocusNode = FocusNode();
  final titleFocusNode = FocusNode();

  late final ValueNotifier<Color> colorNotifier = ValueNotifier(widget.toEdit?.color ?? AppColors.grey);
  late final ValueNotifier<IconData> iconNotifier = ValueNotifier(widget.toEdit?.icon ?? Icons.question_mark_rounded);
  late var isLocked = widget.toEdit?.isLocked ?? false;
  late var grade = widget.toEdit?.lockedGrade ?? 4.0;

  late final bool canBeDeleted =
      !(!editMode ||
          (database.assignments.getAll().any((assignment) => assignment.subject.value?.code == widget.toEdit?.code) ||
              database.grades.getAll().any((grade) => grade.subject.value?.code == widget.toEdit?.code)));

  void confirmSubject() async {
    if (titleController.text.isEmpty) return;

    final subject = widget.toEdit ?? Subject();
    subject
      ..name = titleController.text
      ..code = widget.toEdit?.code ?? titleController.text.normalize().replaceAll(' ', '_').toLowerCase()
      ..iconCodePoint = iconNotifier.value.codePoint
      ..colorValue = colorNotifier.value.toInt()
      ..isLocked = isLocked
      ..lockedGrade = isLocked ? grade : null;

    await database.subjects.save(subject);

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
      builder: (_) => Dialog(title: "Titre manquant", content: "*Entrez un titre* pour créer cette branche !"),
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
    subjectFocusNode.dispose();
    titleFocusNode.dispose();
    iconNotifier.dispose();
    colorNotifier.dispose();
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
          onTap: titleController.text.isNotEmpty ? confirmSubject : showMissingInfoPopup,
          icon: editMode ? HugeIcons.strokeRoundedTick02 : HugeIcons.strokeRoundedAdd01,
        ),
      ),

      child: ListView(
        children: [
          Field(placeholder: "Titre de la branche", maxLines: 1, controller: titleController, focusNode: titleFocusNode),

          AspectRatio(
            aspectRatio: 1.5,
            child: RoundContainer(
              margin: .only(top: 16),
              child: ValueListenableBuilder<Color>(
                valueListenable: colorNotifier,
                builder: (context, selectedColor, _) {
                  return ValueListenableBuilder<IconData>(
                    valueListenable: iconNotifier,
                    builder: (context, selectedIcon, _) {
                      return GridView.builder(
                        scrollDirection: .horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6),
                        shrinkWrap: true,
                        itemCount: availableIcons.length,
                        itemBuilder: (context, index) {
                          final thisIcon = availableIcons[index];
                          final isSelected = thisIcon == selectedIcon;

                          return CupertinoPressable(
                            decoration: BoxDecoration(
                              color: isSelected ? colorNotifier.value : AppColors.secondaryBackground.adaptTo(context),
                              border: .all(color: isSelected ? colorNotifier.value.withBrightness(-.15) : AppColors.transparent),
                              borderRadius: .circular(10),
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

          AspectRatio(
            aspectRatio: 1.5,
            child: RoundContainer(
              margin: .only(top: 16),
              child: ValueListenableBuilder<Color>(
                valueListenable: colorNotifier,
                builder: (context, selectedColor, _) {
                  return GridView.builder(
                    scrollDirection: .horizontal,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    shrinkWrap: true,
                    itemCount: availableColors.length,
                    itemBuilder: (context, index) {
                      final thisColor = availableColors[index];
                      final isSelected = thisColor == selectedColor;

                      return CupertinoPressable(
                        decoration: BoxDecoration(
                          color: thisColor,
                          border: .all(color: isSelected ? AppColors.white : AppColors.transparent),
                          borderRadius: .circular(10),
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

          // Lock option
          ListSection(
            margin: .only(top: 16),
            footer: isLocked
                ? "Choisissez la note qui sera attribuée à cette branche dans le bulletin. *Les branches bloquées ne peuvent pas être modifiées dans la page des notes.*"
                : null,
            children: [
              ListTile.simple(
                context,
                title: "Branche bloquée",
                icon: isLocked ? HugeIcons.strokeRoundedSquareLock02 : HugeIcons.strokeRoundedSquareUnlock02,
                trailing: CupertinoSwitch(value: isLocked, onChanged: (value) => setState(() => isLocked = value)),
              ),

              if (isLocked)
                ListTile(
                  buildChevron: false,
                  child: GradePicker(grade: grade, onGradeChanged: (newGrade) => setState(() => grade = newGrade)),
                ),
            ],
          ),

          // Delete button
          if (editMode)
            ListSection(
              margin: .only(top: 16),
              footer: canBeDeleted ? null : "Cette branche ne peut pas être supprimée ! Supprimez ses notes ses notes et devoirs d'abord.",
              children: [
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedDelete04,
                  title: "Supprimer cette branche",
                  enabled: canBeDeleted,
                  isDestructive: true,
                  onTap: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => Dialog.confirm(
                        content: "Êtes-vous sûr de vouloir *supprimer cette note* ?",
                        isDestructive: true,
                        onConfirm: () {
                          database.subjects.delete(widget.toEdit!);
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
