import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/numbered_progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  final globals = GlobalsService();
  final report = ReportService();

  Widget buildRow(String subjectName, double? average, double? rawAverage, bool isLocked, {Subject? subject, CompositeSubject? compositeSubject}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        spacing: 4,
        children: [
          if (subject != null) SubjectBadge(subject: subject, size: 24),
          if (compositeSubject != null) CompositeSubjectBadge(compositeSubject: compositeSubject, size: 24),

          const SizedBox(width: 8),
          Expanded(child: Text(subjectName, style: const TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),

          if (isLocked) Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.text.adaptTo(context)),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: rawAverage == null ? 6 : 0),
                child: Text(
                  (average?.removeTrailingZero() ?? "-").toString(),
                  style: TextStyle(fontSize: 18, color: (average ?? 4) < 4 ? AppColors.red : null, fontWeight: FontWeight.w800),
                ),
              ),

              if (rawAverage != null)
                Text(
                  rawAverage.toStringAsFixed(2),
                  style: TextStyle(fontSize: 10, color: AppColors.text.adaptTo(context).withAlpha(.5.toByte()), fontWeight: FontWeight.w400),
                ),
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

  Widget buildTotalPointsPart() {
    var totalPoints = report.totalPoints;
    final minPoints = report.allAverages.length * 4;
    final maxPoints = report.allAverages.length * 6;

    final isLowerThanMinimum = totalPoints < minPoints;

    final progress = max(0, isLowerThanMinimum ? totalPoints / minPoints : (totalPoints - minPoints) / (maxPoints - minPoints)).toDouble();
    final difference = (minPoints - totalPoints).abs().removeTrailingZero();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        const Text("Points totaux", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        Text(
          isLowerThanMinimum
              ? "Encore $difference point${difference == "1" ? "" : "s"}, courage !"
              : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum !",
          style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
        ),
        const SizedBox(height: 6),

        NumberedProgressBar(
          lowerBound: isLowerThanMinimum ? "0" : minPoints.toString(),
          upperBound: (isLowerThanMinimum ? minPoints : maxPoints).toString(),
          progress: progress,
          value: totalPoints.removeTrailingZero(),
          color: isLowerThanMinimum ? AppColors.red : AppColors.green,
        ),
      ],
    );
  }

  Widget buildMaxFailingGradesPart() {
    final numberOfFailingGrades = report.allAverages.values.where((grade) => grade < 3.75).length;
    final maxFailingGrades = report.maxFailingGrades;

    final progress = (numberOfFailingGrades / maxFailingGrades).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        const Text("Moyennes insuffisantes", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),

        NumberedProgressBar(
          lowerBound: "0",
          upperBound: maxFailingGrades.toString(),
          progress: progress,
          value: numberOfFailingGrades.toString(),
          color: switch (numberOfFailingGrades) {
            0 => AppColors.green,
            1 => AppColors.yellow,
            2 => AppColors.orange,
            _ => AppColors.red,
          },
        ),
      ],
    );
  }

  Widget buildRestrictedGroupPointsPart() {
    final restrictedGroupAverages = <double>[];
    for (final subjectCode in report.restrictedGroupCodes) {
      if (report.allAverages.containsKey(subjectCode) && report.allAverages[subjectCode] != null) restrictedGroupAverages.add(report.allAverages[subjectCode]!);
    }

    final totalPoints = restrictedGroupAverages.sum;
    final minPoints = restrictedGroupAverages.length * 4;
    final maxPoints = restrictedGroupAverages.length * 6;

    final isLowerThanMinimum = totalPoints < minPoints;

    final progress = max(0, isLowerThanMinimum ? totalPoints / minPoints : (totalPoints - minPoints) / (maxPoints - minPoints)).toDouble();
    final difference = (minPoints - totalPoints).abs().removeTrailingZero();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        const Text("Points du groupe restreint", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        Text(
          isLowerThanMinimum
              ? "Encore $difference point${difference == "1" ? "" : "s"}, courage !"
              : "$difference point${difference == "1" ? "" : "s"} au-dessus du minimum !",
          style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
        ),
        const SizedBox(height: 6),

        NumberedProgressBar(
          lowerBound: isLowerThanMinimum ? "0" : minPoints.toString(),
          upperBound: (isLowerThanMinimum ? minPoints : maxPoints).toString(),
          progress: progress,
          value: totalPoints.removeTrailingZero(),
          color: isLowerThanMinimum ? AppColors.red : AppColors.green,
        ),
      ],
    );
  }

  Widget buildDoubleCompensationPart() {
    var deficit = .0;
    for (final average in report.allAverages.values) {
      if (average < 4) deficit += average - 4;
    }
    var surplus = .0;
    for (final average in report.allAverages.values) {
      if (average > 4) surplus += average - 4;
    }
    final result = surplus + deficit * 2;

    final isFailing = result < 0;

    final progress = result / (deficit.abs() + surplus);
    final difference = result.abs() * 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 0,
      children: [
        const Text("Double compensation", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
        if (isFailing)
          Text(
            "+${difference.removeTrailingZero()} point${difference == 1.0 ? "" : "s"} pour compenser, courage !",
            style: TextStyle(fontSize: 14, color: AppColors.red),
          ),
        const SizedBox(height: 6),

        NumberedProgressBar(
          lowerBound: deficit.toDouble().removeTrailingZero(),
          upperBound: "+${surplus.toDouble().removeTrailingZero()}",
          progress: progress,
          value: result.toDouble().removeTrailingZero(),
          color: isFailing ? AppColors.red : AppColors.green,
          centered: true,
        ),
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    final allSubjects = report.allSubjects;
    final allCompositeSubjects = report.allCompositeSubjects;
    final usingRestrictedGroup = report.usingRestrictedGroup;
    final restrictedGroupCodes = report.restrictedGroupCodes;
    final restrictedGroupCompositeSubjects = report.restrictedGroupCompositeSubjects;
    final restrictedGroupSubjects = report.restrictedGroupSubjects;

    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [const CupertinoSliverNavigationBar(largeTitle: Text("Votre bulletin"), previousPageTitle: "Toutes les notes")];
        },
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              // All subjects list
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Column(
                  children: [
                    // All subjects
                    ...() {
                      final filteredList =
                          [...allCompositeSubjects, ...allSubjects].where((subject) {
                            final String code = (subject as dynamic).code;
                            return !(usingRestrictedGroup && restrictedGroupCodes.contains(code));
                          }).toList();

                      return filteredList.indexed.map(
                        (subject) => Column(
                          children: [
                            if (subject.$2 is CompositeSubject)
                              buildCompositeSubjectRow(subject.$2 as CompositeSubject)
                            else
                              buildSubjectRow(subject.$2 as Subject),
                            if (subject.$1 != filteredList.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                          ],
                        ),
                      );
                    }(),

                    // Restricted group subjects
                    if (usingRestrictedGroup && (restrictedGroupSubjects.isNotEmpty || restrictedGroupCompositeSubjects.isNotEmpty)) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 10, bottom: 2),
                        child: Text("Groupe restreint", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      ...() {
                        final restrictedList = [...restrictedGroupCompositeSubjects, ...restrictedGroupSubjects];

                        return restrictedList.indexed.map(
                          (subject) => Column(
                            children: [
                              if (subject.$2 is CompositeSubject)
                                buildCompositeSubjectRow(subject.$2 as CompositeSubject)
                              else
                                buildSubjectRow(subject.$2 as Subject),
                              if (subject.$1 != restrictedList.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Points part
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  spacing: 6,
                  children: [
                    buildTotalPointsPart(),
                    Divider(color: AppColors.tertiaryBackground.adaptTo(context)),
                    buildMaxFailingGradesPart(),

                    if (report.usingDoubleCompensation) ...[Divider(color: AppColors.tertiaryBackground.adaptTo(context)), buildDoubleCompensationPart()],

                    if (usingRestrictedGroup && restrictedGroupCodes.isNotEmpty) ...[
                      Divider(color: AppColors.tertiaryBackground.adaptTo(context)),
                      buildRestrictedGroupPointsPart(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.zero,
                backgroundColor: AppColors.transparent,
                header: const Text("Options de calcul"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    title: const Text("Max. de notes insuffisantes"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text("4", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))), CupertinoListTileChevron()],
                    ),
                  ),
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    title: const Text("Double compensation"),
                    trailing: CupertinoSwitch(
                      value: report.usingDoubleCompensation,
                      onChanged: (newValue) {
                        globals.persistent.setBool("UseDoubleCompensation", newValue);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),

              if (allSubjects.length > 3) ...[
                const SizedBox(height: 10),
                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  backgroundColor: AppColors.transparent,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      title: const Text("Groupe restreint"),
                      trailing: CupertinoSwitch(
                        value: usingRestrictedGroup,
                        onChanged: (newValue) {
                          globals.persistent.setBool("UseRestrictedGroup", newValue);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),

                if (usingRestrictedGroup) ...[
                  const SizedBox(height: 10),
                  CupertinoListSection.insetGrouped(
                    margin: EdgeInsets.zero,
                    backgroundColor: AppColors.transparent,
                    children: [
                      for (final compositeSubject in restrictedGroupCompositeSubjects)
                        CupertinoListTile(
                          backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                          leading: GestureDetector(
                            onTap: () => onSubjectRemoved(compositeSubject.code),
                            child: CustomIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red),
                          ),
                          title: Row(spacing: 10, children: [CompositeSubjectBadge(compositeSubject: compositeSubject, size: 20), Text(compositeSubject.name)]),
                        ),

                      for (final subject in restrictedGroupSubjects)
                        CupertinoListTile(
                          backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                          leading: GestureDetector(
                            onTap: () => onSubjectRemoved(subject.code),
                            child: CustomIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red),
                          ),
                          title: Row(spacing: 10, children: [SubjectBadge(subject: subject, size: 20), Text(subject.name)]),
                        ),

                      if (allSubjects.length - restrictedGroupSubjects.length - restrictedGroupCompositeSubjects.length > 1)
                        CupertinoListTile(
                          backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                          leading: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.placeholderText.adaptTo(context)),
                          title: SubjectAutocomplete(
                            placeholder: "Entrez une branche du groupe restreint",
                            onSubjectSelected: (subject) => onSubjectSelected(subject.code),
                            onCompositeSubjectSelected: (compositeSubject) => onSubjectSelected(compositeSubject.code),
                            useCompositeSubjects: true,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
