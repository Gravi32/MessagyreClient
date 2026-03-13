import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/numbered_progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_autocomplete.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  final globals = GlobalsService();
  final report = ReportService();

  Widget buildSubjectRow(Subject subject) {
    double? grade = subject.lockedGrade ?? report.allAverages[subject.code];

    if (grade != null && grade < 1) grade = null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 4,
        children: [
          SubjectBadge(subject: subject, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(subject.name, style: TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),
          if (subject.isLocked) Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.text.adaptTo(context)),
          Text((grade ?? "-").toString(), style: TextStyle(fontSize: 18, color: (grade ?? 4) < 4 ? AppColors.red : null, fontWeight: FontWeight.w800)),
        ],
      ),
    );
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

  Widget buildRestrictedGroupPointsPart() {
    final restrictedGroupAverages = <double>[];
    for (final subjectCode in report.restrictedGroupSubjectCodes) {
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Votre bulletin"), previousPageTitle: "Toutes les notes")];
        },
        body: SafeArea(
          top: false,

          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Column(
                  children: [
                    for (final subject in report.allSubjects.indexed) ...[
                      if (!(report.usingRestrictedGroup && report.restrictedGroupSubjectCodes.contains(subject.$2.code))) buildSubjectRow(subject.$2),
                      if (subject.$1 != report.allSubjects.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                    ],
                    if (report.usingRestrictedGroup && report.restrictedGroupSubjects.isNotEmpty) ...[
                      Padding(padding: EdgeInsets.only(top: 10, bottom: 2), child: Text("Groupe restreint", style: TextStyle(fontWeight: FontWeight.w600))),
                      for (final restrictedGroupSubject in report.restrictedGroupSubjects.indexed) ...[
                        buildSubjectRow(restrictedGroupSubject.$2),
                        if (restrictedGroupSubject.$1 != report.restrictedGroupSubjects.length - 1)
                          Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                      ],
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
                    if (report.usingRestrictedGroup && report.restrictedGroupSubjectCodes.isNotEmpty) ...[
                      Divider(color: AppColors.tertiaryBackground.adaptTo(context)),
                      buildRestrictedGroupPointsPart(),
                    ],
                    if (report.usingDoubleCompensation) ...[Divider(color: AppColors.tertiaryBackground.adaptTo(context)), buildDoubleCompensationPart()],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.zero,
                backgroundColor: AppColors.transparent,
                header: Text("Options de calcul"),
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    title: Text("Groupe restreint"),
                    trailing: CupertinoSwitch(
                      value: report.usingRestrictedGroup,
                      onChanged: (newValue) {
                        globals.persistent.setBool("UseRestrictedGroup", newValue);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),

              if (report.usingRestrictedGroup) ...[
                const SizedBox(height: 10),
                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  backgroundColor: AppColors.transparent,
                  children: [
                    for (final subject in report.restrictedGroupSubjects)
                      CupertinoListTile(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        leading: GestureDetector(
                          onTap: () {
                            final newList = report.restrictedGroupSubjectCodes;
                            newList.remove(subject.code);
                            globals.persistent.setStringList("RestrictedGroupSubjects", newList);
                            setState(() {});
                          },
                          child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: AppColors.red),
                        ),
                        title: Row(spacing: 10, children: [SubjectBadge(subject: subject, size: 20), Text(subject.name)]),
                      ),

                    if (report.allSubjects.length - report.restrictedGroupSubjects.length > 1)
                      CupertinoListTile(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        leading: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.placeholderText.adaptTo(context)),
                        title: SubjectAutocomplete(
                          placeholder: "Entrez une branche du groupe restreint",
                          onSelected: (selectedSubject) {
                            final newList = report.restrictedGroupSubjectCodes;
                            newList.add(selectedSubject.code);
                            globals.persistent.setStringList("RestrictedGroupSubjects", newList);
                            setState(() {});
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 10),

              CupertinoListSection.insetGrouped(
                margin: EdgeInsets.zero,
                backgroundColor: AppColors.transparent,
                children: [
                  CupertinoListTile(
                    backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                    title: Text("Double compensation"),
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
            ],
          ),
        ),
      ),
    );
  }
}
