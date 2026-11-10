import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/gymnase_mark.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

/// Asks for the user's class at the start: a new account, or a class of an earlier school year. Closing it asks
/// again the next day.
Future<void> askUserForTheirClass(BuildContext context) async {
  final classes = ClassService();
  if (!classes.shouldAsk(DateTime.now())) return;

  final chosen = await showCupertinoSheet<bool>(context: context, builder: (_) => const ClassPickerPage(isOnboarding: true), enableDrag: false);
  if (chosen != true) await classes.postpone();
}

/// The user's class, chosen with three wheels (school, year, class: the classes of that year of that school) that show how many people already chose
/// each class. Choosing one joins its chat; "not at the Gymnase de Renens" is also possible. Pops `true` once saved.
class ClassPickerPage extends StatefulWidget {
  final bool isOnboarding;

  const ClassPickerPage({super.key, this.isOnboarding = false});

  @override
  State<ClassPickerPage> createState() => _ClassPickerPageState();
}

class _ClassPickerPageState extends State<ClassPickerPage> {
  final classes = ClassService();
  static final schoolCodes = SchoolClass.schools.keys.toList();

  late int schoolIndex, yearIndex, sectionIndex;
  late final FixedExtentScrollController schoolController, yearController, sectionController;

  Map<String, int>? counts;
  bool isSaving = false;

  String get school => schoolCodes[schoolIndex];
  List<int> get years => SchoolClass.yearsOf(school);
  int get year => years[yearIndex];
  List<String> get sections => SchoolClass.sectionsOf(year, school);

  SchoolClass get selected => SchoolClass(year, school, sections[sectionIndex]);

  @override
  void initState() {
    super.initState();

    // The class already chosen, or last year's moved up one year (same class when it still exists: 2Cci1 → 3Cci1)
    final saved = SchoolClass.tryParse(classes.savedValue);
    final isLastYear = saved != null && classes.savedYear != SchoolClass.yearLabel(DateTime.now());
    schoolIndex = saved == null ? 0 : schoolCodes.indexOf(saved.school).clamp(0, schoolCodes.length - 1);
    final wantedYear = saved == null ? 1 : (isLastYear ? saved.year + 1 : saved.year);
    yearIndex = years.indexOf(wantedYear.clamp(years.first, years.last));
    sectionIndex = saved == null ? 0 : sections.indexOf(saved.section).clamp(0, sections.length - 1);

    schoolController = FixedExtentScrollController(initialItem: schoolIndex);
    yearController = FixedExtentScrollController(initialItem: yearIndex);
    sectionController = FixedExtentScrollController(initialItem: sectionIndex);

    classes.counts().then((value) {
      if (mounted) setState(() => counts = value);
    });
  }

  @override
  void dispose() {
    schoolController.dispose();
    yearController.dispose();
    sectionController.dispose();
    super.dispose();
  }

  /// Another school or year has other years and classes: keeps the same ones when they exist there, and moves the
  /// wheels that changed
  void change({int? school, int? yearPosition}) {
    final previousYear = year;
    final previousSection = sections[sectionIndex];
    setState(() {
      if (school != null) {
        schoolIndex = school;
        yearIndex = years.contains(previousYear) ? years.indexOf(previousYear) : years.length - 1;
      }
      if (yearPosition != null) yearIndex = yearPosition;
      final kept = sections.indexOf(previousSection);
      sectionIndex = kept < 0 ? 0 : kept;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (yearController.hasClients && yearController.selectedItem != yearIndex) yearController.jumpToItem(yearIndex);
      if (sectionController.hasClients && sectionController.selectedItem != sectionIndex) sectionController.jumpToItem(sectionIndex);
    });
  }

  int countOf(SchoolClass schoolClass) => counts?[schoolClass.name] ?? 0;

  Future<void> save(String value) async {
    if (isSaving) return;
    setState(() => isSaving = true);

    final error = await classes.choose(value);
    if (!mounted) return;
    setState(() => isSaving = false);

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => Dialog(title: "Classe non enregistrée", content: error),
      );
    }
  }

  void confirmOutside() {
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog.confirm(
        content: "Vous ne rejoindrez aucune classe. Vous pourrez la choisir plus tard dans *Réglages → Ma classe*.",
        onConfirm: () => save(SchoolClass.outside),
      ),
    );
  }

  Widget buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required Widget Function(int index) itemBuilder,
    required void Function(int index) onChanged,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 40,
      squeeze: 1.1,
      diameterRatio: 1.4,
      // The selection band is drawn once, under the three wheels
      selectionOverlay: null,
      onSelectedItemChanged: onChanged,
      children: [for (var index = 0; index < count; index++) Center(child: itemBuilder(index))],
    );
  }

  /// The class being chosen, big, with how many already chose it
  Widget buildPreview() {
    final schoolClass = selected;
    final count = countOf(schoolClass);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: BrandCard(
        padding: const EdgeInsets.all(AppSpacing.l),
        markScale: 1.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gymnase de Renens",
              style: AppStyles.subheadline(context).copyWith(color: AppColors.white.withValues(alpha: .8), fontWeight: FontWeight.w600),
            ),
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Text(
                schoolClass.name,
                key: ValueKey(schoolClass.name),
                style: AppStyles.display(context).copyWith(color: AppColors.white),
              ),
            ),
            Text(
              "${schoolClass.yearName} · ${schoolClass.description}",
              style: AppStyles.subheadline(context).copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              counts == null
                  ? " "
                  : count == 0
                  ? "Personne n'a encore choisi cette classe"
                  : count == 1
                  ? "1 personne a déjà choisi cette classe"
                  : "$count personnes ont déjà choisi cette classe",
              style: AppStyles.footnote(context).copyWith(color: AppColors.white.withValues(alpha: .85)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppStyles.primaryText(context);
    final schoolClassYear = SchoolClass.yearLabel(DateTime.now());

    return Page(
      topBar: TopBar.form(
        context,
        title: "Votre classe",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedTick02, isLoading: isSaving, onTap: () => save(selected.name)),
      ),
      child: ListView(
        children: [
          CustomText(
            widget.isOnboarding
                ? "Choisissez votre classe pour l'année *$schoolClassYear* : vous rejoindrez automatiquement la conversation de votre classe."
                : "Votre classe pour l'année *$schoolClassYear*. En changeant de classe, vous quittez la conversation de l'ancienne.",
            style: AppStyles.secondaryText(context),
            padding: const EdgeInsets.only(top: AppSpacing.m),
          ),
          buildPreview(),
          const SizedBox(height: AppSpacing.l),
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground.adaptTo(context),
              borderRadius: BorderRadius.circular(AppRadius.l),
              border: Border.all(color: AppColors.outline.adaptTo(context)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(AppRadius.s)),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: buildWheel(
                        controller: schoolController,
                        count: schoolCodes.length,
                        itemBuilder: (index) => Text(SchoolClass.shortSchools[schoolCodes[index]]!, style: text),
                        onChanged: (index) => change(school: index),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: buildWheel(
                        controller: yearController,
                        count: years.length,
                        itemBuilder: (index) => Text(years[index] == 1 ? "1re" : "${years[index]}e", style: text),
                        onChanged: (index) => change(yearPosition: index),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: buildWheel(
                        controller: sectionController,
                        count: sections.length,
                        // A dot next to the classes that already have members
                        itemBuilder: (index) {
                          final schoolClass = SchoolClass(year, school, sections[index]);
                          final count = countOf(schoolClass);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: AppSpacing.xs,
                            children: [
                              Text(schoolClass.name, style: text),
                              if (count > 0)
                                Text(
                                  "· $count",
                                  style: AppStyles.footnote(context).copyWith(color: AppColors.tint.adaptTo(context), fontWeight: FontWeight.w600),
                                ),
                            ],
                          );
                        },
                        onChanged: (index) => setState(() => sectionIndex = index),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListSection(
            margin: const EdgeInsets.only(top: AppSpacing.m),
            footer:
                "Le Gymnase ne publie pas la liste des classes : n'importe qui peut choisir une classe. Ne partagez rien de privé dans la conversation de classe.",
            children: [ListTile.simple(context, title: "Je ne suis pas au Gymnase de Renens", icon: HugeIcons.strokeRoundedSchool01, onTap: confirmOutside)],
          ),
          const BottomSpacing(),
        ],
      ),
    );
  }
}
