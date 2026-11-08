import 'dart:math';

import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/report_service.dart';
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

class _ReportCardPageState extends State<ReportCardPage> {
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
                      if (isLocked) HugeIcon(icon: AppIcons.locked, size: 12, color: AppColors.tertiaryText.adaptTo(context)),
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
              color: average == null ? AppColors.quaternaryText.adaptTo(context) : getGradeColor(average, context: context),
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
    final color = isMet ? AppColors.green : AppColors.red;
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
                        HugeIcon(icon: isMet ? HugeIcons.strokeRoundedCheckmarkCircle02 : HugeIcons.strokeRoundedAlertCircle, size: 14, color: color),
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

  void chooseMaxFailingSubjects() {
    int maxFailingSubjects = report.maxFailingGrades;
    final pickerController = FixedExtentScrollController(initialItem: maxFailingSubjects);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => ModalPopup(
        topBar: TopBar.form(
          context,
          title: "Insuffisances permises",
          trailing: Button.icon(
            context,
            icon: HugeIcons.strokeRoundedTick02,
            onTap: () async {
              globals.persistent.setInt("MaxFailingSubjects", maxFailingSubjects);
              setState(() {});
              Navigator.pop(context);
            },
          ),
        ),
        height: 180,
        child: StatefulBuilder(
          builder: (context, setPopupState) {
            return Picker(
              controller: pickerController,
              onChanged: (index) {
                setPopupState(() {
                  maxFailingSubjects = index;
                });
              },
              children: [for (int index = 0; index <= 10; index++) Center(child: Text(index.toString(), style: AppStyles.primaryText(context)))],
            );
          },
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
          progress: max(0, report.maxTotalPoints == 0 ? 0 : report.totalPoints / report.maxTotalPoints),
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
          progress: max(0, report.maxRestrictedGroupPoints == 0 ? 0 : report.restrictedGroupPoints / report.maxRestrictedGroupPoints),
          lowerBound: "0",
          upperBound: "min. ${report.minRestrictedGroupPoints.removeTrailingZero()} · max. ${report.maxRestrictedGroupPoints.removeTrailingZero()}",
        ),
      );
    }

    return Page(
      topBar: TopBar.tab(context, title: "Bulletin"),
      child: ListView(
        padding: const .only(top: AppSpacing.s),
        children: [
          CardGroup(children: criteria),

          if (mainList.isNotEmpty) ...[
            sectionTitle("Moyennes"),
            CardGroup(separatorInset: AppSpacing.l + 32 + AppSpacing.m, children: [for (final subject in mainList) subjectRow(subject)]),
          ],

          if (usingRestrictedGroup && restrictedList.isNotEmpty) ...[
            sectionTitle("Groupe restreint"),
            CardGroup(separatorInset: AppSpacing.l + 32 + AppSpacing.m, children: [for (final subject in restrictedList) subjectRow(subject)]),
          ],

          sectionTitle("Règles"),
          ListSection(
            footer: "Les règles de promotion de votre école : elles changent les conditions ci-dessus.",
            children: [
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedAlertCircle,
                title: "Insuffisances permises",
                trailing: Row(
                  mainAxisSize: .min,
                  spacing: 6,
                  children: [
                    Text(report.maxFailingGrades.toString(), style: AppStyles.secondaryText(context)),
                    HugeIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
                  ],
                ),
                onTap: chooseMaxFailingSubjects,
              ),
              ListTile.simple(
                context,
                icon: HugeIcons.strokeRoundedBalanceScale,
                title: "Double compensation",
                trailing: CupertinoSwitch(
                  activeTrackColor: AppColors.accent,
                  value: report.usingDoubleCompensation,
                  onChanged: (newValue) {
                    globals.persistent.setBool("UseDoubleCompensation", newValue);
                    setState(() {});
                  },
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
                    onChanged: (newValue) {
                      globals.persistent.setBool("UseRestrictedGroup", newValue);
                      setState(() {});
                    },
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
                    trailing: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.secondaryText.adaptTo(context)),
                    onTap: () => onSubjectRemoved(compositeSubject.code),
                    child: Text(compositeSubject.name, style: AppStyles.primaryText(context)),
                  ),
                for (final subject in restrictedGroupSubjects)
                  ListTile(
                    leading: SubjectBadge(subject: subject, size: 28),
                    trailing: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: AppColors.secondaryText.adaptTo(context)),
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
