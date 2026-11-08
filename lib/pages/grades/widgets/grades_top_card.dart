import 'package:messagyre_client/utility/widgets/app_icon.dart';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/report_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/report_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/round_container.dart';
import 'package:messagyre_client/utility/widgets/chart.dart';
import 'package:messagyre_client/utility/widgets/grade_display.dart';

/// The top of the grades page: the general average with its curve and a few figures, then the report card's summary
class GradesTopCard extends StatefulWidget {
  const GradesTopCard({super.key});

  @override
  State<GradesTopCard> createState() => _GradesTopCardState();
}

class _GradesTopCardState extends State<GradesTopCard> {
  final database = DatabaseService();
  final report = ReportService();

  Widget buildAverageCard(List<Grade> grades) {
    if (grades.isEmpty) {
      return RoundContainer(
        watermark: true,
        padding: const .all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: .start,
          spacing: AppSpacing.xs,
          children: [
            Text("MOYENNE GÉNÉRALE", style: AppStyles.overline(context)),
            Text("Pas encore de notes", style: AppStyles.header(context)),
            Text("Ajoutez votre première note avec le bouton +.", style: AppStyles.subheadline(context)),
          ],
        ),
      );
    }

    final generalAverage = calculateAverage(grades.toList());
    final chronological = grades.sorted((a, b) => a.date.compareTo(b.date));

    // The running average, grade after grade (the curve)
    double sum = 0;
    final runningAverages = <double>[];
    for (final (index, grade) in chronological.indexed) {
      sum += grade.grade;
      runningAverages.add(sum / (index + 1));
    }
    final low = runningAverages.reduce(min), high = runningAverages.reduce(max);

    final values = grades.map((grade) => grade.grade).toList();
    final recent = chronological.reversed.take(3).map((grade) => grade.grade).toList();
    final recentAverage = recent.reduce((a, b) => a + b) / recent.length;
    final best = values.reduce(max);
    final aboveFive = (values.where((value) => value >= 5).length / values.length * 100).round();
    final isFailing = generalAverage < 4;

    return RoundContainer(
      watermark: true,
      padding: .zero,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: const .fromLTRB(AppSpacing.card, AppSpacing.card, AppSpacing.card, AppSpacing.l),
            child: Row(
              crossAxisAlignment: .end,
              spacing: AppSpacing.xl,
              children: [
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text("MOYENNE GÉNÉRALE", style: AppStyles.overline(context)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      GradeDisplay.format(generalAverage, round: false),
                      style: AppStyles.display(
                        context,
                      ).copyWith(color: isFailing ? getGradeColor(generalAverage, context) : null, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    Text("${grades.length} note${grades.length > 1 ? "s" : ""}", style: AppStyles.subheadline(context)),
                  ],
                ),
                Expanded(
                  child: SizedBox(
                    height: 72,
                    child: Chart(
                      color: isFailing ? getGradeColor(generalAverage, context) : AppColors.text.adaptTo(context).withValues(alpha: .75),
                      showLines: false,
                      min: max(low.floorToDouble() - .5, 1),
                      max: min(high.ceilToDouble(), 6),
                      spots: runningAverages.mapIndexed((index, average) => FlSpot(index.toDouble(), average)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: .5, color: AppColors.separator.adaptTo(context)),
          Padding(
            padding: const .symmetric(vertical: AppSpacing.m + 2),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Figure(label: "3 dernières", value: GradeDisplay.format(recentAverage, round: false)),
                  ),
                  _divider(context),
                  Expanded(
                    child: _Figure(label: "Meilleure", value: GradeDisplay.format(best)),
                  ),
                  _divider(context),
                  Expanded(
                    child: _Figure(label: "5 ou plus", value: "$aboveFive %"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(width: .5, margin: const .symmetric(vertical: 4), color: AppColors.separator.adaptTo(context));

  Widget buildReportCard() {
    final failingColor = report.failingGrades <= 0
        ? AppColors.gradeGood.adaptTo(context)
        : report.failingGrades <= report.maxFailingGrades
        ? AppColors.gradeBorderline.adaptTo(context)
        : AppColors.gradeLow.adaptTo(context);

    final figures = <Widget>[
      _Figure(label: "Points", value: report.totalPoints.removeTrailingZero(), alignment: .start),
      if (report.maxFailingGrades > 0)
        _Figure(label: "Insuffisantes", value: "${report.failingGrades} / ${report.maxFailingGrades}", valueColor: failingColor, alignment: .start),
      if (report.usingRestrictedGroup) _Figure(label: "Groupe restreint", value: report.restrictedGroupPoints.removeTrailingZero(), alignment: .start),
      if (report.usingDoubleCompensation)
        _Figure(
          label: "Compensation",
          value: report.doubleCompensation.removeTrailingZero(),
          valueColor: (report.doubleCompensation >= 0 ? AppColors.gradeGood : AppColors.gradeLow).adaptTo(context),
          alignment: .start,
        ),
    ];

    return CupertinoButton(
      padding: .zero,
      minimumSize: .zero,
      pressedOpacity: .6,
      onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const ReportCardPage())).then((_) {
        if (mounted) setState(() {});
      }),
      child: RoundContainer(
        padding: const .all(AppSpacing.card),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: AppSpacing.l,
          children: [
            Row(
              spacing: AppSpacing.m,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: .center,
                  decoration: BoxDecoration(color: AppColors.tertiaryBackground.adaptTo(context), borderRadius: .circular(9)),
                  child: AppIcon(icon: HugeIcons.strokeRoundedFile02, size: 18, color: AppColors.text.adaptTo(context)),
                ),
                Expanded(child: Text("Bulletin", style: AppStyles.strongText(context))),
                AppIcon(icon: AppIcons.chevronRight, size: 18, color: AppColors.quaternaryText.adaptTo(context)),
              ],
            ),
            Row(children: [for (final figure in figures.take(3)) Expanded(child: figure)]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grades = database.grades.getAll();

    return Column(crossAxisAlignment: .stretch, spacing: AppSpacing.m, children: [buildAverageCard(grades), buildReportCard()]);
  }
}

/// A figure and its label, small
class _Figure extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment alignment;

  const _Figure({required this.label, required this.value, this.valueColor, this.alignment = .center});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      spacing: 2,
      children: [
        Text(
          value,
          maxLines: 1,
          style: AppStyles.secondaryHeader(context).copyWith(fontWeight: .w700, color: valueColor, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        Text(label, maxLines: 1, overflow: .ellipsis, style: AppStyles.footnote(context)),
      ],
    );
  }
}
