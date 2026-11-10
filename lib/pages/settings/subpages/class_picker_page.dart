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

  /// The classes that exist this year (from the server), null while it is read
  ClassCatalog? catalog;

  int schoolIndex = 0, yearIndex = 0, sectionIndex = 0;
  FixedExtentScrollController? schoolController, yearController, sectionController;

  Map<String, int>? counts;
  bool isSaving = false;

  CatalogSchool get school => catalog!.schools[schoolIndex];
  List<int> get years => school.years;
  int get year => years[yearIndex];
  List<String> get sections => school.classes[year]!;

  SchoolClass get selected => SchoolClass.tryParse(sections[sectionIndex], catalog: catalog)!;

  @override
  void initState() {
    super.initState();
    classes.loadCatalog().then((loaded) {
      if (mounted) setState(() => setUp(loaded));
    });
    classes.counts().then((value) {
      if (mounted) setState(() => counts = value);
    });
  }

  /// Puts the wheels on the class already chosen, or on last year's moved up one year (2Cci1 → 3Cci1 when it exists)
  void setUp(ClassCatalog loaded) {
    catalog = loaded;
    if (loaded.schools.isEmpty) return;
    final saved = SchoolClass.tryParse(classes.savedValue, catalog: loaded);
    final isLastYear = saved != null && classes.savedYear != SchoolClass.yearLabel(DateTime.now());
    final savedSchool = saved == null ? -1 : loaded.schools.indexWhere((school) => school.code == saved.school);
    schoolIndex = savedSchool < 0 ? 0 : savedSchool;
    final wantedYear = saved == null || savedSchool < 0 ? years.first : (isLastYear ? saved.year + 1 : saved.year);
    yearIndex = years.indexOf(wantedYear.clamp(years.first, years.last));
    if (yearIndex < 0) yearIndex = 0;
    final wanted = saved == null ? "" : "$year${saved.school}${saved.section}";
    sectionIndex = sections.indexWhere((name) => name.toLowerCase() == wanted.toLowerCase());
    if (sectionIndex < 0) sectionIndex = 0;

    schoolController = FixedExtentScrollController(initialItem: schoolIndex);
    yearController = FixedExtentScrollController(initialItem: yearIndex);
    sectionController = FixedExtentScrollController(initialItem: sectionIndex);
  }

  @override
  void dispose() {
    schoolController?.dispose();
    yearController?.dispose();
    sectionController?.dispose();
    super.dispose();
  }

  /// Another school or year has other years and classes: keeps the same year when it exists there, and moves the
  /// wheels that changed
  void change({int? school, int? yearPosition}) {
    final previousYear = year;
    setState(() {
      if (school != null) {
        schoolIndex = school;
        yearIndex = years.contains(previousYear) ? years.indexOf(previousYear) : years.length - 1;
      }
      if (yearPosition != null) yearIndex = yearPosition;
      sectionIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final years = yearController, sections = sectionController;
      if (years != null && years.hasClients && years.selectedItem != yearIndex) years.jumpToItem(yearIndex);
      if (sections != null && sections.hasClients && sections.selectedItem != sectionIndex) sections.jumpToItem(sectionIndex);
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
            Text("${schoolClass.yearName} · ${schoolClass.describe(catalog)}", style: AppStyles.subheadline(context).copyWith(color: AppColors.white)),
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
    final isReady = catalog != null && catalog!.schools.isNotEmpty;

    return Page(
      topBar: TopBar.form(
        context,
        title: "Votre classe",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedTick02, isLoading: isSaving || !isReady, onTap: isReady ? () => save(selected.name) : null),
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
          if (!isReady)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl * 3),
              child: Center(child: GymnaseLoader(size: 40)),
            ),
          if (isReady) buildPreview(),
          if (isReady) const SizedBox(height: AppSpacing.l),
          if (isReady)
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
                          controller: schoolController!,
                          count: catalog!.schools.length,
                          itemBuilder: (index) => Text(catalog!.schools[index].shortName, style: text),
                          onChanged: (index) => change(school: index),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: buildWheel(
                          controller: yearController!,
                          count: years.length,
                          itemBuilder: (index) => Text(years[index] == 1 ? "1re" : "${years[index]}e", style: text),
                          onChanged: (index) => change(yearPosition: index),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: buildWheel(
                          controller: sectionController!,
                          count: sections.length,
                          // A dot next to the classes that already have members
                          itemBuilder: (index) {
                            final name = sections[index];
                            final count = counts?[name] ?? 0;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: AppSpacing.xs,
                              children: [
                                Text(name, style: text),
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
                "Votre classe n'est pas dans la liste ? Écrivez à support.messagyre. N'importe qui peut choisir une classe : ne partagez rien de privé dans la conversation de classe.",
            children: [ListTile.simple(context, title: "Je ne suis pas au Gymnase de Renens", icon: HugeIcons.strokeRoundedSchool01, onTap: confirmOutside)],
          ),
          const BottomSpacing(),
        ],
      ),
    );
  }
}
