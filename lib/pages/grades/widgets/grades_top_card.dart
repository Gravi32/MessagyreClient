import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class GradesTopCard extends StatefulWidget {
  const GradesTopCard({super.key});

  @override
  State<GradesTopCard> createState() => _GradesTopCardState();
}

class _GradesTopCardState extends State<GradesTopCard> {
  final database = DatabaseService();

  List<Grade> grades = [];

  Widget buildGeneralAverageTab() {
    final average = calculateAverage(grades.toList());

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        GradeDisplay(grade: average, size: 100, strokeWidth: 5, roundGrade: false, textBelow: "${grades.length} note${grades.length > 1 ? 's' : ''}"),
        Text("Moyenne générale", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
      ],
    );
  }

  Widget buildReportCardTab() {
    final subjects = database.subjects.getAll();

    final Map<String, List<Grade>> gradesPerSubject = {};
    final Map<String, double> averagePerSubject = {};

    for (final grade in grades) {
      final subject = grade.subject.value;
      if (subject == null) continue;
      gradesPerSubject.putIfAbsent(subject.code, () => []).add(grade);
    }

    for (final subject in gradesPerSubject.keys) {
      averagePerSubject[subject] = gradesPerSubject[subject] != null ? calculateAverage(gradesPerSubject[subject]!, round: true) : 0;
    }

    Widget statBox(String label, String value) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 1,
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.secondaryText.adaptTo(context))),
        ],
      );
    }

    Widget buildSubjectRow(Subject subject) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          spacing: 6,
          children: [
            SubjectBadge(subject: subject, size: 20),
            Expanded(child: Text(subject.name, overflow: TextOverflow.ellipsis)),
            Text((averagePerSubject[subject.code] ?? "-").toString()),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bulletin", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: EdgeInsets.zero,
            crossAxisSpacing: 8,
            physics: NeverScrollableScrollPhysics(),
            children: [
              // Subjects list
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                child: ListView(padding: EdgeInsets.zero, children: subjects.map(buildSubjectRow).toList()),
              ),

              // Stats
              Container(
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    statBox("Points", "${averagePerSubject.values.sum} / ${6 * averagePerSubject.length}"),
                    statBox("Notes insuffisantes", "${averagePerSubject.values.where((avg) => avg < 4).length} / 4"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildStatsTab() {
    Widget statBox(String label, String value) {
      return Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    final total = grades.length;

    if (total == 0) {
      return Center(child: Text("Aucune note disponible"));
    }

    // Extract grade values and sort them
    final values = grades.map((g) => g.grade).toList()..sort();

    // Threshold percentage
    final threshold = 5.0;
    final aboveThreshold = (values.where((v) => v >= threshold).length / total * 100).round();

    // Average
    final average = values.reduce((a, b) => a + b) / total;

    // Median
    final mid = total ~/ 2;
    final median = total.isOdd ? values[mid] : (values[mid - 1] + values[mid]) / 2;

    // Minimum and maximum
    final minGrade = values.first;
    final maxGrade = values.last;

    // Range
    final range = maxGrade - minGrade;

    // Stability = standard deviation
    final variance = values.map((v) => pow(v - average, 2)).reduce((a, b) => a + b) / total;
    final stdDev = sqrt(variance);

    // Recent trend = average of last 3 grades
    final recentCount = min(3, total);
    final recentAverage = values.take(recentCount).reduce((a, b) => a + b) / recentCount;

    // Build the grid of statistics
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Statistiques", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            children: [
              statBox("Total des notes", "$total"),
              statBox("≥ $threshold", "$aboveThreshold %"),
              statBox("Stabilité", stdDev.toStringAsFixed(2)),
              statBox("Moyenne", average.toStringAsFixed(2)),
              statBox("Médiane", median.toStringAsFixed(2)),
              statBox("Maximum", maxGrade.toStringAsFixed(2)),
              statBox("Minimum", minGrade.toStringAsFixed(2)),
              statBox("Étendue", range.toStringAsFixed(2)),
              statBox("Récente", recentAverage.toStringAsFixed(2)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    grades = database.grades.getAll();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: PagedCard(height: 150, pages: [buildGeneralAverageTab(), buildReportCardTab(), buildStatsTab()]),
    );
  }
}
