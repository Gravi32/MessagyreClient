import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/report_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';
import 'package:messagyre_client/utility/widgets/paged_card.dart';

class GradesTopCard extends StatefulWidget {
  const GradesTopCard({super.key});

  @override
  State<GradesTopCard> createState() => _GradesTopCardState();
}

class _GradesTopCardState extends State<GradesTopCard> {
  final database = DatabaseService();
  final report = ReportService();

  List<Grade> grades = [];

  Widget buildGeneralAverageTab() {
    final generalAverage = calculateAverage(grades.toList());
    final color = getGradeColor(generalAverage);

    grades.sort((a, b) => a.date.compareTo(b.date));

    double sum = 0;
    int count = 0;

    double minAverage = double.infinity;
    double maxAverage = -double.infinity;

    final allAverages = <double>[];

    for (final grade in grades) {
      sum += grade.grade;
      count++;

      final average = sum / count;

      allAverages.add(average);

      if (average < minAverage) minAverage = average;
      if (average > maxAverage) maxAverage = average;
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 10,
      children: [
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 15, bottom: 15, left: 55),
                child: LineChart(
                  LineChartData(
                    minY: max(minAverage.floor().toDouble(), 1),
                    maxY: min(maxAverage.ceil().toDouble(), 6),
                    lineBarsData: [
                      LineChartBarData(
                        color: color,
                        isCurved: true,
                        barWidth: 3,
                        preventCurveOverShooting: true,
                        isStrokeCapRound: true,
                        isStrokeJoinRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [color.withAlpha(80), AppColors.transparent],
                          ),
                        ),
                        spots: allAverages.mapIndexed((index, average) => FlSpot(index / allAverages.length, average)).toList(),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(),
                      leftTitles: AxisTitles(),
                      bottomTitles: AxisTitles(),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget:
                              (value, meta) => SideTitleWidget(
                                meta: meta,
                                child: Text(value.removeTrailingZero(), style: TextStyle(fontSize: 12, color: AppColors.text.adaptTo(context).withAlpha(65))),
                              ),
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(enabled: false),
                    gridData: FlGridData(drawVerticalLine: false, horizontalInterval: .5),
                    borderData: FlBorderData(show: true, border: Border.symmetric(horizontal: BorderSide(color: AppColors.text.adaptTo(context).withAlpha(1)))),
                  ),
                ),
              ),

              Positioned(
                left: 5,
                top: 0,
                bottom: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -15,
                      right: -15,
                      left: -15,
                      bottom: -15,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), shape: BoxShape.circle)),
                      ),
                    ),

                    GradeDisplay(
                      grade: generalAverage,
                      size: 100,
                      strokeWidth: 5,
                      roundGrade: false,
                      textBelow: "${grades.length} note${grades.length > 1 ? 's' : ''}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text("Moyenne générale", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
      ],
    );
  }

  Widget buildReportCardTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bulletin", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),
            GestureDetector(
              onTap:
                  () => Navigator.push(context, CupertinoPageRoute(builder: (context) => ReportCardPage())).then((_) {
                    if (mounted) setState(() {});
                  }),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 4,
                children: [
                  Text("Tout voir", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.tertiaryText.adaptTo(context))),
                  Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
                ],
              ),
            ),
          ],
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              report.buildTotalPointsIndicator(minimized: true),
              if (report.maxFailingGrades > 0) ...[
                Divider(height: 16, color: AppColors.tertiaryBackground.adaptTo(context)),
                report.buildMaxFailingSubjectsIndicator(minimized: true),
              ],
              if (report.usingRestrictedGroup) ...[
                Divider(height: 16, color: AppColors.tertiaryBackground.adaptTo(context)),
                report.buildRestrictedGroupPointsIndicator(minimized: true),
              ],
              if (report.usingDoubleCompensation && !report.usingRestrictedGroup) ...[
                Divider(height: 16, color: AppColors.tertiaryBackground.adaptTo(context)),
                report.buildDoubleCompensationIndicator(minimized: true),
              ],
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
            Expanded(child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600))),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
    }

    final total = grades.length;

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
    final recentGrades = grades..sort((a, b) => b.date.compareTo(a.date));
    final recentAverage = recentGrades.take(recentCount).map((g) => g.grade).reduce((a, b) => a + b) / recentCount;

    // Build the grid of statistics
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Statistiques", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: adaptiveColor(AppColors.black, AppColors.white))),

        Expanded(
          child: GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            children: [
              statBox("Notes", "$total"),
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
      child: PagedCard(height: 160, pages: grades.isEmpty ? [buildReportCardTab()] : [buildGeneralAverageTab(), buildReportCardTab(), buildStatsTab()]),
    );
  }
}
