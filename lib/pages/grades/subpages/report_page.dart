import 'package:messagyre_client/utility/widgets/appear.dart';
import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/services/report_presets.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/pages/grades/widgets/report_tutorial.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/modal_popup.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/picker.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> with AppearOnOpen {
  final globals = GlobalsService();
  final report = ReportService();

  /// A subject of the report: its rounded average, big, and the exact one under it
  Widget buildRow(String subjectName, double? average, double? rawAverage, bool isLocked, {Subject? subject, CompositeSubject? compositeSubject}) {
    return Padding(
      padding: const .fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.m),
      child: Row(
        spacing: AppSpacing.m,
        children: [
          if (subject != null) SubjectBadge(subject: subject, size: 32),
          if (compositeSubject != null) SizedBox.square(dimension: 32, child: CompositeSubjectBadge(compositeSubject: compositeSubject, size: 32)),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              spacing: 2,
              children: [
                Text(subjectName, style: AppStyles.primaryText(context), maxLines: 1, overflow: .ellipsis),
                if (isLocked || rawAverage != null)
                  Row(
                    spacing: 4,
                    children: [
                      if (isLocked) AppIcon(icon: AppIcons.locked, size: 12, color: AppColors.tertiaryText.adaptTo(context)),
                      Text(isLocked ? "Bloquée" : "Moyenne ${rawAverage!.toStringAsFixed(2)}", style: AppStyles.footnote(context)),
                    ],
                  ),
              ],
            ),
          ),
          Text(
            average?.removeTrailingZero() ?? "–",
            style: AppStyles.secondaryHeader(context).copyWith(
              fontWeight: .w700,
              color: average == null ? AppColors.quaternaryText.adaptTo(context) : getGradeColor(average, context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// One of the promotion's conditions: where it stands, and a bar from its minimum to its maximum
  Widget buildCriterion({
    required String title,
    required String value,
    required String status,
    required bool isMet,
    required double progress,
    bool centered = false,
    String? lowerBound,
    String? upperBound,
  }) {
    final color = (isMet ? AppColors.gradeGood : AppColors.gradeLow).adaptTo(context);
    return Padding(
      padding: const .all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: AppSpacing.s,
        children: [
          Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  spacing: 2,
                  children: [
                    Text(title, style: AppStyles.strongText(context)),
                    Row(
                      spacing: 4,
                      children: [
                        AppIcon(icon: isMet ? HugeIcons.strokeRoundedCheckmarkCircle02 : HugeIcons.strokeRoundedAlertCircle, size: 14, color: color),
                        Flexible(
                          child: Text(status, style: AppStyles.footnote(context).copyWith(color: color)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(value, style: AppStyles.header(context).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
          ProgressBar(progress: progress, height: 6, centered: centered, color: color),
          if (lowerBound != null && upperBound != null)
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(lowerBound, style: AppStyles.caption(context)),
                Text(upperBound, style: AppStyles.caption(context)),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildSubjectRow(Subject subject) {
    double? average = subject.lockedGrade ?? report.allAverages[subject.code];
    double? rawAverage = report.allAveragesRaw[subject.code];

    if (average != null && average < 1) average = null;

    return buildRow(subject.name, average, rawAverage, subject.isLocked, subject: subject);
  }

  Widget buildCompositeSubjectRow(CompositeSubject compositeSubject) {
    double? average = calculateCompositeSubjectAverage(compositeSubject, round: true);
    double? rawAverage = report.allAveragesRaw[compositeSubject.code];

    if (average != null && average < 1) average = null;

    return buildRow(compositeSubject.name, average, rawAverage, false, compositeSubject: compositeSubject);
  }

  void onSubjectSelected(String selectedSubjectCode) {
    final newList = report.restrictedGroupCodes.toList();
    newList.add(selectedSubjectCode);
    globals.persistent.setStringList("RestrictedGroupSubjects", newList);
    setState(() {});
  }

  void onSubjectRemoved(String subjectCode) {
    final newList = report.restrictedGroupCodes.toList();
    newList.remove(subjectCode);
    globals.persistent.setStringList("RestrictedGroupSubjects", newList);
    setState(() {});
  }

  /// A wheel to choose one of [labels]; [onChosen] gets its index. Changing a rule by hand leaves the class's preset.
  void choose({required String title, required List<String> labels, required int selected, required Future<void> Function(int) onChosen}) {
    var chosen = selected.clamp(0, labels.length - 1);
    final pickerController = FixedExtentScrollController(initialItem: chosen);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => ModalPopup(
        topBar: TopBar.form(
          context,
          title: title,
          trailing: Button.icon(
            context,
            icon: HugeIcons.strokeRoundedTick02,
            onTap: () async {
              await onChosen(chosen);
              await globals.persistent.remove("ReportPreset");
              if (mounted) setState(() {});
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
        height: 180,
        child: Picker(
          controller: pickerController,
          onChanged: (index) => chosen = index,
          children: [for (final label in labels) Center(child: Text(label, style: AppStyles.primaryText(context)))],
        ),
      ),
    );
  }

  void chooseMaxFailingSubjects() => choose(
    title: "Insuffisances permises",
    labels: [for (int index = 0; index <= 10; index++) index.toString()],
    selected: report.maxFailingGrades,
    onChosen: (index) => globals.persistent.setInt("MaxFailingSubjects", index),
  );

  static final _minimumChoices = [0, for (int points = 20; points <= 80; points += 4) points];

  void chooseMinimumTotal() => choose(
    title: "Total minimum",
    labels: [for (final points in _minimumChoices) points == 0 ? "Auto (4 par branche)" : "$points points (${points ~/ 4} moyennes)"],
    selected: math.max(0, _minimumChoices.indexOf(report.fixedMinTotalPoints?.round() ?? 0)),
    onChosen: (index) => globals.persistent.setInt("MinTotalPoints", _minimumChoices[index]),
  );

  static final _negativeChoices = [for (int half = 1; half <= 12; half++) half / 2];

  void chooseMaxNegativePoints() => choose(
    title: "Points négatifs max.",
    labels: [for (final value in _negativeChoices) value.removeTrailingZero().replaceAll(".", ",")],
    selected: math.max(0, _negativeChoices.indexOf(report.maxNegativePoints)),
    onChosen: (index) => globals.persistent.setDouble("MaxNegativePoints", _negativeChoices[index]),
  );

  Future<void> setRule(String key, bool value) async {
    await globals.persistent.setBool(key, value);
    await globals.persistent.remove("ReportPreset");
    if (mounted) setState(() {});
  }

  /// The rules of each school and year: choosing one sets them all
  void choosePreset() {
    final mine = ReportPreset.forClass(ClassService().current.value);
    final presets = [?mine, ...ReportPreset.all.where((preset) => preset != mine)];
    final current = ReportPreset.current;

    showCupertinoModalPopup(
      context: context,
      builder: (popupContext) => ModalPopup(
        topBar: TopBar.form(popupContext, title: "Régler pour ma classe"),
        height: 560,
        child: ListView(
          padding: const .only(top: AppSpacing.s),
          children: [
            for (final preset in presets)
              Padding(
                padding: const .only(bottom: AppSpacing.s),
                child: CupertinoButton(
                  padding: .zero,
                  minimumSize: .zero,
                  pressedOpacity: .6,
                  onPressed: () async {
                    await preset.apply();
                    if (mounted) setState(() {});
                    if (popupContext.mounted) Navigator.pop(popupContext);
                    if (preset.todo != null && mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (_) => Dialog(title: "Encore une chose", content: preset.todo, options: {"Compris": () {}}),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: AppDurations.normal,
                    padding: const .all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: preset == current ? AppColors.accentSoft.adaptTo(context) : AppColors.tertiaryBackground.adaptTo(context),
                      borderRadius: .circular(AppRadius.m),
                    ),
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 2,
                      children: [
                        Row(
                          spacing: AppSpacing.s,
                          children: [
                            Expanded(child: Text(preset.title, style: AppStyles.strongText(context))),
                            if (preset == mine) Text("Votre classe", style: AppStyles.footnote(context).copyWith(color: AppColors.tint.adaptTo(context))),
                            if (preset == current) AppIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 18, color: AppColors.tint.adaptTo(context)),
                          ],
                        ),
                        Text(preset.subtitle, style: AppStyles.footnote(context)),
                        const SizedBox(height: AppSpacing.xs),
                        for (final rule in preset.rules) Text("·  $rule", style: AppStyles.secondaryText(context)),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const .symmetric(vertical: AppSpacing.s),
              child: Text(
                "D'après le règlement des gymnases vaudois. Votre gymnase peut avoir des règles en plus : en cas de doute, demandez à votre maître de classe.",
                style: AppStyles.footnote(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) => Padding(
    padding: const .only(left: 4, top: AppSpacing.section, bottom: AppSpacing.s),
    child: Text(title, style: AppStyles.section(context)),
  );

  @override
  Widget build(BuildContext context) {
    final allSubjects = report.allSubjects;
    final allCompositeSubjects = report.allCompositeSubjects;
    final usingRestrictedGroup = report.usingRestrictedGroup;
    final restrictedGroupCodes = report.restrictedGroupCodes;
    final restrictedGroupCompositeSubjects = report.restrictedGroupCompositeSubjects;
    final restrictedGroupSubjects = report.restrictedGroupSubjects;

    Widget subjectRow(Object subject) => subject is CompositeSubject ? buildCompositeSubjectRow(subject) : buildSubjectRow(subject as Subject);

    final mainList = [
      ...allCompositeSubjects,
      ...allSubjects,
    ].where((subject) => !(usingRestrictedGroup && restrictedGroupCodes.contains((subject as dynamic).code))).toList();
    final restrictedList = [...restrictedGroupCompositeSubjects, ...restrictedGroupSubjects];

    // The conditions
    final criteria = <Widget>[];
    {
      final isLower = report.totalPoints < report.minTotalPoints;
      final difference = (report.minTotalPoints - report.totalPoints).abs().removeTrailingZero();
      criteria.add(
        buildCriterion(
          title: "Total des points",
          value: report.totalPoints.removeTrailingZero(),
          status: isLower ? "Encore $difference point${difference == "1" ? "" : "s"}" : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum",
          isMet: !isLower,
          progress: math.max(0, report.maxTotalPoints == 0 ? 0 : report.totalPoints / report.maxTotalPoints),
          lowerBound: "0",
          upperBound: "min. ${report.minTotalPoints.removeTrailingZero()} · max. ${report.maxTotalPoints.removeTrailingZero()}",
        ),
      );
    }
    if (report.maxFailingGrades > 0) {
      criteria.add(
        buildCriterion(
          title: "Moyennes insuffisantes",
          value: "${report.failingGrades} / ${report.maxFailingGrades}",
          status: report.failingGrades <= report.maxFailingGrades ? "Dans la limite" : "Au-dessus de la limite",
          isMet: report.failingGrades <= report.maxFailingGrades,
          progress: (report.failingGrades / report.maxFailingGrades).clamp(0, 1),
        ),
      );
    }
    if (report.usingMaxNegativePoints) {
      final isMet = report.negativePoints <= report.maxNegativePoints;
      criteria.add(
        buildCriterion(
          title: "Points négatifs",
          value: "${report.negativePoints.removeTrailingZero()} / ${report.maxNegativePoints.removeTrailingZero()}",
          status: isMet ? "Dans la limite" : "Au-dessus de la limite",
          isMet: isMet,
          progress: report.maxNegativePoints == 0 ? 1 : (report.negativePoints / report.maxNegativePoints).clamp(0, 1),
        ),
      );
    }
    if (report.usingDoubleCompensation) {
      final isFailing = report.doubleCompensation < 0;
      final span = report.deficit.abs() + report.surplus;
      final needed = report.doubleCompensation.abs() * 2.0;
      criteria.add(
        buildCriterion(
          title: "Double compensation",
          value: report.doubleCompensation.removeTrailingZero(),
          status: isFailing ? "Encore ${needed.removeTrailingZero()} point${needed == 1.0 ? "" : "s"}" : "Les insuffisances sont compensées",
          isMet: !isFailing,
          progress: span == 0 ? 0 : report.doubleCompensation / span,
          centered: true,
          lowerBound: report.deficit.removeTrailingZero(),
          upperBound: "+${report.surplus.removeTrailingZero()}",
        ),
      );
    }
    if (usingRestrictedGroup && restrictedGroupCodes.isNotEmpty) {
      final isLower = report.restrictedGroupPoints < report.minRestrictedGroupPoints;
      final difference = (report.minRestrictedGroupPoints - report.restrictedGroupPoints).abs().removeTrailingZero();
      criteria.add(
        buildCriterion(
          title: "Groupe restreint",
          value: report.restrictedGroupPoints.removeTrailingZero(),
          status: isLower ? "Encore $difference point${difference == "1" ? "" : "s"}" : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum",
          isMet: !isLower,
          progress: math.max(0, report.maxRestrictedGroupPoints == 0 ? 0 : report.restrictedGroupPoints / report.maxRestrictedGroupPoints),
          lowerBound: "0",
          upperBound: "min. ${report.minRestrictedGroupPoints.removeTrailingZero()} · max. ${report.maxRestrictedGroupPoints.removeTrailingZero()}",
        ),
      );
    }

    return Page(
      topBar: TopBar.tab(
        context,
        title: "Bulletin",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedHelpCircle, onTap: () => ReportTutorial.show(context)),
      ),
      child: ListView(
        padding: const .only(top: AppSpacing.s),
        children: [
          // Nobody knew the rules had to be set: proposed until a school's rules are chosen
          AnimatedSize(
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            child: ReportPreset.current != null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const .only(bottom: AppSpacing.l),
                    child: _SetUpCard(onSetUp: choosePreset, onExplain: () => ReportTutorial.show(context)),
                  ),
          ),

          Appear(enabled: isOpening, child: CardGroup(children: criteria)),

          if (mainList.isNotEmpty) ...[
            sectionTitle("Moyennes"),
            Appear(
              index: 2,
              enabled: isOpening,
              child: CardGroup(separatorInset: AppSpacing.l + 32 + AppSpacing.m, children: [for (final subject in mainList) subjectRow(subject)]),
            ),
          ],

          if (usingRestrictedGroup && restrictedList.isNotEmpty) ...[
            sectionTitle("Groupe restreint"),
            CardGroup(separatorInset: AppSpacing.l + 32 + AppSpacing.m, children: [for (final subject in restrictedList) subjectRow(subject)]),
          ],

          sectionTitle("Règles"),
          ListSection(
            footer: "Les règles de promotion de votre école : elles changent les conditions ci-dessus. Touchez « ? » en haut pour voir comment les régler.",
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedSchool,
                title: "Régler pour ma classe",
                trailing: Row(
                  mainAxisSize: .min,
                  spacing: 6,
                  children: [
                    Text(ReportPreset.current?.id ?? "À la main", style: AppStyles.secondaryText(context)),
                    AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
                  ],
                ),
                onTap: choosePreset,
              ),
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedCalculator,
                title: "Total minimum",
                trailing: Row(
                  mainAxisSize: .min,
                  spacing: 6,
                  children: [
                    Text(report.fixedMinTotalPoints?.removeTrailingZero() ?? "Auto", style: AppStyles.secondaryText(context)),
                    AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
                  ],
                ),
                onTap: chooseMinimumTotal,
              ),
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedAlertCircle,
                title: "Insuffisances permises",
                trailing: Row(
                  mainAxisSize: .min,
                  spacing: 6,
                  children: [
                    Text(report.maxFailingGrades.toString(), style: AppStyles.secondaryText(context)),
                    AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
                  ],
                ),
                onTap: chooseMaxFailingSubjects,
              ),
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedRemoveCircle,
                title: "Points négatifs max.",
                trailing: CupertinoSwitch(
                  activeTrackColor: AppColors.accent,
                  value: report.usingMaxNegativePoints,
                  onChanged: (newValue) => setRule("UseMaxNegativePoints", newValue),
                ),
              ),
              if (report.usingMaxNegativePoints)
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedRuler,
                  title: "Limite des points négatifs",
                  trailing: Row(
                    mainAxisSize: .min,
                    spacing: 6,
                    children: [
                      Text(report.maxNegativePoints.removeTrailingZero().replaceAll(".", ","), style: AppStyles.secondaryText(context)),
                      AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
                    ],
                  ),
                  onTap: chooseMaxNegativePoints,
                ),
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedBalanceScale,
                title: "Double compensation",
                trailing: CupertinoSwitch(
                  activeTrackColor: AppColors.accent,
                  value: report.usingDoubleCompensation,
                  onChanged: (newValue) => setRule("UseDoubleCompensation", newValue),
                ),
              ),
              if (allSubjects.length > 3)
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedLayers01,
                  title: "Groupe restreint",
                  trailing: CupertinoSwitch(
                    activeTrackColor: AppColors.accent,
                    value: usingRestrictedGroup,
                    onChanged: (newValue) => setRule("UseRestrictedGroup", newValue),
                  ),
                ),
              if (usingRestrictedGroup && allSubjects.length > 3)
                ListTile.simple(
                  context,
                  icon: HugeIcons.strokeRoundedFilter,
                  title: "Limites sur le groupe seulement",
                  trailing: CupertinoSwitch(
                    activeTrackColor: AppColors.accent,
                    value: report.limitsOnRestrictedGroup,
                    onChanged: (newValue) => setRule("LimitsOnRestrictedGroup", newValue),
                  ),
                ),
            ],
          ),

          // The subjects of the restricted group
          if (usingRestrictedGroup && allSubjects.length > 3) ...[
            sectionTitle("Branches du groupe restreint"),
            ListSection(
              children: [
                for (final compositeSubject in restrictedGroupCompositeSubjects)
                  ListTile(
                    leading: CompositeSubjectBadge(compositeSubject: compositeSubject, size: 28),
                    trailing: AppIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                    onTap: () => onSubjectRemoved(compositeSubject.code),
                    child: Text(compositeSubject.name, style: AppStyles.primaryText(context)),
                  ),
                for (final subject in restrictedGroupSubjects)
                  ListTile(
                    leading: SubjectBadge(subject: subject, size: 28),
                    trailing: AppIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                    onTap: () => showCupertinoDialog(
                      context: context,
                      builder: (_) =>
                          Dialog.confirm(content: "Retirer *${subject.name}* du groupe restreint ?", onConfirm: () => onSubjectRemoved(subject.code)),
                    ),
                    child: Text(subject.name, style: AppStyles.primaryText(context)),
                  ),
                if (allSubjects.length - restrictedGroupSubjects.length - restrictedGroupCompositeSubjects.length > 1)
                  ListTile(
                    leading: ListTile.iconTile(context, icon: HugeIcons.strokeRoundedAdd01),
                    buildChevron: false,
                    child: SubjectAutocomplete(
                      placeholder: "Ajouter une branche",
                      onSubjectSelected: (subject) => onSubjectSelected(subject.code),
                      onCompositeSubjectSelected: (compositeSubject) => onSubjectSelected(compositeSubject.code),
                      useCompositeSubjects: true,
                    ),
                  ),
              ],
            ),
          ],

          const BottomSpacing(),
        ],
      ),
    );
  }
}

/// Proposed at the top of the bulletin until the rules of a school and year are chosen
class _SetUpCard extends StatelessWidget {
  final VoidCallback onSetUp;
  final VoidCallback onExplain;

  const _SetUpCard({required this.onSetUp, required this.onExplain});

  @override
  Widget build(BuildContext context) {
    final mine = ReportPreset.forClass(ClassService().current.value);
    return Container(
      padding: const .all(AppSpacing.card),
      decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: .circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: .start,
        spacing: AppSpacing.s,
        children: [
          Text("Votre bulletin est-il bien réglé ?", style: AppStyles.secondaryHeader(context).copyWith(color: AppColors.white)),
          Text(
            mine != null
                ? "Les règles changent selon l'école et l'année. Prenez celles de ${mine.title} en un geste."
                : "Les règles changent selon l'école et l'année : total minimum, insuffisances, points négatifs…",
            style: AppStyles.secondaryText(context).copyWith(color: AppColors.white.withValues(alpha: .85)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CupertinoButton(
                padding: const .symmetric(horizontal: 16, vertical: 9),
                minimumSize: .zero,
                color: AppColors.white,
                borderRadius: .circular(AppRadius.l),
                onPressed: onSetUp,
                child: Text("Régler pour ma classe", style: AppStyles.button(context).copyWith(color: AppColors.accent)),
              ),
              CupertinoButton(
                padding: const .symmetric(horizontal: 8, vertical: 9),
                minimumSize: .zero,
                onPressed: onExplain,
                child: Text("Comment ça marche ?", style: AppStyles.button(context).copyWith(color: AppColors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
