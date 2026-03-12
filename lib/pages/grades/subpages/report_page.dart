import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/progress_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class ReportCardPage extends StatefulWidget {
  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  final database = DatabaseService();
  final globals = GlobalsService();

  late final grades = database.grades.getAll();
  late final subjects = database.subjects.getAll();

  final Map<String, List<Grade>> gradesPerSubject = {};
  final Map<String, double> averagePerSubject = {};

  late var usingDoubleCompensation = globals.persistent.getBool("UseDoubleCompensation") ?? false;
  late var usingRestrictedGroup = globals.persistent.getBool("UseRestrictedGroup") ?? false;

  Widget buildSubjectRow(Subject subject) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 10,
        children: [
          SubjectBadge(subject: subject, size: 24),
          Expanded(child: Text(subject.name, style: TextStyle(fontSize: 18), overflow: TextOverflow.ellipsis)),
          Text((averagePerSubject[subject.code] ?? "-").toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget buildNumberedProgressBar(String lowerBound, String upperBound, double progress, String value, Color color) {
    final textStyle = TextStyle(fontSize: 32, fontWeight: FontWeight.w800, backgroundColor: AppColors.secondaryBackground.adaptTo(context));
    final textWidth = measureTextWidth(value, textStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        // Bounds
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(lowerBound), Text(upperBound)]),

        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final position = width * progress;

            final left = (position - textWidth / 2).clamp(0.0, width - textWidth);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                ProgressBar(progress: progress, gradient: LinearGradient(colors: [color, AppColors.white], stops: [.5, 1])),

                Positioned(left: left, bottom: 8, child: Text(value, style: textStyle)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget buildTotalPointsPart() {
    final totalPoints = 14.0;
    averagePerSubject.values.sum;
    final minPoints = subjects.length * 4;
    final maxPoints = subjects.length * 6;

    final isLowerThanMinimum = totalPoints < minPoints;

    final progress = max(0, isLowerThanMinimum ? totalPoints / minPoints : (totalPoints - minPoints) / (maxPoints - minPoints)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Points totaux"),
            Text(
              isLowerThanMinimum
                  ? "Encore ${(minPoints - totalPoints).removeTrailingZero()} points, courage !"
                  : "${(totalPoints - minPoints).removeTrailingZero()} points au-dessus du minimum !",
              style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
            ),
          ],
        ),
        const SizedBox(height: 10),

        buildNumberedProgressBar(
          isLowerThanMinimum ? "0" : minPoints.toString(),
          (isLowerThanMinimum ? minPoints : maxPoints).toString(),
          progress,
          totalPoints.removeTrailingZero(),
          isLowerThanMinimum ? AppColors.red : AppColors.green,
        ),
      ],
    );
  }

  Widget buildRestrictedGroupPointsPart() {
    final totalPoints = 14.0;
    averagePerSubject.values.sum;
    final minPoints = subjects.length * 4;
    final maxPoints = subjects.length * 6;

    final isLowerThanMinimum = totalPoints < minPoints;

    final progress = max(0, isLowerThanMinimum ? totalPoints / minPoints : (totalPoints - minPoints) / (maxPoints - minPoints)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Points totaux"),
            Text(
              isLowerThanMinimum
                  ? "Encore ${(minPoints - totalPoints).removeTrailingZero()} points, courage !"
                  : "${(totalPoints - minPoints).removeTrailingZero()} points au-dessus du minimum !",
              style: TextStyle(fontSize: 14, color: isLowerThanMinimum ? AppColors.red : AppColors.green),
            ),
          ],
        ),
        const SizedBox(height: 10),

        buildNumberedProgressBar(
          isLowerThanMinimum ? "0" : minPoints.toString(),
          (isLowerThanMinimum ? minPoints : maxPoints).toString(),
          progress,
          totalPoints.removeTrailingZero(),
          isLowerThanMinimum ? AppColors.red : AppColors.green,
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    for (final grade in grades) {
      final subject = grade.subject.value;
      if (subject == null) continue;
      gradesPerSubject.putIfAbsent(subject.code, () => []).add(grade);
    }

    for (final subject in gradesPerSubject.keys) {
      averagePerSubject[subject] = gradesPerSubject[subject] != null ? calculateAverage(gradesPerSubject[subject]!, round: true) : 0;
    }
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
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                // Subjects list part
                Container(
                  decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Column(
                    children: [
                      for (int i = 0; i < subjects.length; i++) ...[
                        buildSubjectRow(subjects[i]),
                        if (i != subjects.length - 1) Divider(color: AppColors.tertiaryBackground.adaptTo(context), height: 0),
                      ],
                    ],
                  ),
                ),

                // Points part
                Container(
                  decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(children: [buildTotalPointsPart()]),
                ),

                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.zero,
                  backgroundColor: AppColors.transparent,
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      title: Text("Double compensation"),
                      trailing: CupertinoSwitch(
                        value: usingDoubleCompensation,
                        onChanged: (newValue) {
                          globals.persistent.setBool("UseDoubleCompensation", newValue);
                          setState(() => usingDoubleCompensation = newValue);
                        },
                      ),
                    ),
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      title: Text("Groupe restreint"),
                      trailing: CupertinoSwitch(
                        value: usingRestrictedGroup,
                        onChanged: (newValue) {
                          globals.persistent.setBool("UseRestrictedGroup", newValue);
                          setState(() => usingRestrictedGroup = newValue);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
