import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/report_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/extensions/widget_extensions.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
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
      mainAxisSize: .max,
      mainAxisAlignment: .center,
      crossAxisAlignment: .center,
      spacing: 10,
      children: [
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: .only(top: 15, bottom: 15, left: 55),
                child: LineChart(
                  LineChartData(
                    minY: max(minAverage.floor().toDouble(), 1),
                    maxY: min(maxAverage.ceil().toDouble(), 6),
                    lineBarsData: [
                      LineChartBarData(
                        color: color,
                        isCurved: true,
                        barWidth: 4,
                        preventCurveOverShooting: true,
                        isStrokeCapRound: true,
                        isStrokeJoinRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(begin: .topCenter, end: .bottomCenter, colors: [color.withAlpha(80), AppColors.transparent]),
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
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(value.removeTrailingZero(), style: TextStyle(fontSize: 12, color: AppColors.text.adaptTo(context).withAlpha(65))),
                          ),
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(enabled: false),
                    gridData: FlGridData(drawVerticalLine: false, horizontalInterval: .5),
                    borderData: FlBorderData(
                      show: true,
                      border: .symmetric(horizontal: BorderSide(color: AppColors.text.adaptTo(context).withAlpha(1))),
                    ),
                  ),
                ),
              ),

              Stack(
                clipBehavior: Clip.none,
                alignment: .center,
                children: [
                  RoundContainer(
                    borderRadius: 1000,
                    padding: .zero,
                    child: Center(
                      child: GradeDisplay(
                        grade: generalAverage,
                        size: 100,
                        strokeWidth: 5,
                        roundGrade: false,
                        textBelow: "${grades.length} note${grades.length > 1 ? 's' : ''}",
                      ),
                    ),
                  ).withAspectRatio(1),
                ],
              ),
            ],
          ),
        ),
        Text("Moyenne générale", style: AppStyles.header(context)),
      ],
    );
  }

  Widget buildReportCardTab() {
    Widget buildReportStat(String title, String value, Color? valueColor) {
      return Padding(
        padding: .symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Text(title, style: AppStyles.primaryText(context)),
            Text(value, style: AppStyles.secondaryHeader(context).copyWith(color: valueColor)),
          ],
        ),
      );
    }

    final stats = [
      buildReportStat(
        "Points totaux",
        report.totalPoints.removeTrailingZero(),
        getGradeColor(report.totalPoints / report.maxTotalPoints * 6, defaultColor: AppColors.green),
      ),
      if (report.maxFailingGrades > 0)
        buildReportStat(
          "Branches sous la moyenne",
          report.failingGrades.toString(),
          getGradeColor(report.failingGrades / report.maxFailingGrades * 6, defaultColor: AppColors.green),
        ),
      if (report.usingRestrictedGroup)
        buildReportStat(
          "Points du groupe restreint",
          report.restrictedGroupPoints.removeTrailingZero(),
          getGradeColor(6 - report.restrictedGroupPoints / report.maxRestrictedGroupPoints * 6, defaultColor: AppColors.green),
        ),
      if (report.usingDoubleCompensation)
        buildReportStat(
          "Double compensation",
          report.doubleCompensation.removeTrailingZero(),
          report.doubleCompensation >= 0 ? AppColors.green : AppColors.red,
        ),
    ];

    return Column(
      crossAxisAlignment: .start,
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: .start,
          children: [
            Text("Bulletin", style: AppStyles.header(context)),
            Button.icon(
              context,
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: AppColors.secondaryBackground.adaptTo(context),
              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => ReportCardPage())).then((_) {
                if (mounted) setState(() {});
              }),
              size: 40,
            ),
          ],
        ),

        Expanded(
          child: RoundContainer(
            padding: .zero,
            child: ListView.separated(
              padding: .symmetric(vertical: 8),
              itemCount: stats.length,
              shrinkWrap: true,
              itemBuilder: (context, index) => stats[index],
              separatorBuilder: (context, index) => Divider(height: 16, color: AppColors.secondaryBackground.adaptTo(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStatsTab() {
    Widget buildBox(String title, String value) {
      return RoundContainer(
        margin: const .all(4),
        padding: const .symmetric(vertical: 10, horizontal: 6),
        color: AppColors.secondaryBackground.adaptTo(context),
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .stretch,
          spacing: 4,
          children: [
            Expanded(
              child: Text(title, style: AppStyles.tertiaryText(context), textAlign: .center),
            ),
            Expanded(
              flex: 2,
              child: Text(value, style: AppStyles.header(context), textAlign: .center),
            ),
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
      crossAxisAlignment: .start,
      children: [
        Text("Statistiques", style: AppStyles.header(context)),

        Expanded(
          child: GridView.count(
            padding: .zero,
            crossAxisCount: 3,
            childAspectRatio: 1.3,
            children: [
              buildBox("Notes", "$total"),
              buildBox("≥ $threshold", "$aboveThreshold %"),
              buildBox("Stabilité", stdDev.toStringAsFixed(2)),
              buildBox("Moyenne", average.toStringAsFixed(2)),
              buildBox("Médiane", median.toStringAsFixed(2)),
              buildBox("Maximum", maxGrade.toStringAsFixed(2)),
              buildBox("Minimum", minGrade.toStringAsFixed(2)),
              buildBox("Étendue", range.toStringAsFixed(2)),
              buildBox("Récente", recentAverage.toStringAsFixed(2)),
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
      padding: const .only(top: 6),
      child: PagedCard(height: 160, pages: grades.isEmpty ? [buildReportCardTab()] : [buildGeneralAverageTab(), buildReportCardTab(), buildStatsTab()]),
    );
  }
}
