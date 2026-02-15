import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class RecentGradesPage extends StatefulWidget {
  const RecentGradesPage({super.key});

  @override
  State<StatefulWidget> createState() => _RecentGradesPageState();
}

class _RecentGradesPageState extends State<RecentGradesPage> {
  final database = DatabaseService();

  Widget buildList(List<Grade> grades) {
    final Map<DateTime, List<Grade>> grouped = {};

    for (final grade in grades) {
      final weekStart = grade.date.subtract(Duration(days: grade.date.weekday - 1)).dateOnly();

      grouped.putIfAbsent(weekStart, () => []).add(grade);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children:
          grouped.entries.map((entry) {
            final start = entry.key;
            final end = start.add(const Duration(days: 6));

            return CupertinoListSection.insetGrouped(
              header: Text("${formatDate(start).capitalize()} - ${formatDate(end)}"),
              backgroundColor: AppColors.transparent,
              margin: EdgeInsets.zero,
              children:
                  entry.value.map((grade) {
                    return CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      padding: EdgeInsets.all(6),
                      title: GradeBar(gradeData: grade, onTap: () => showNewGradePopup(grade)),
                    );
                  }).toList(),
            );
          }).toList(),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void showNewGradePopup(Grade toEdit) async {
    await showCupertinoModalBottomSheet<Grade?>(context: context, enableDrag: false, builder: (context) => NewGradePage(toEdit: toEdit));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final grades = database.grades.getAll().where((g) => g.groupName == null).sorted((a, b) => b.date.compareTo(a.date));

    final total = grades.length;

    // Percentuale sopra soglia
    final threshold = 5.0;
    final aboveThreshold = grades.isEmpty ? 0 : (grades.where((g) => g.grade >= threshold).length / total * 100).round();

    // Stabilità = deviazione standard
    double? stdDev;
    if (grades.isNotEmpty) {
      final avg = grades.map((g) => g.grade).reduce((a, b) => a + b) / total;
      final variance = grades.map((g) => pow(g.grade - avg, 2)).reduce((a, b) => a + b) / total;
      stdDev = sqrt(variance);
    }

    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Toutes les notes"), previousPageTitle: "Retour")];
        },
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBox("Total", "$total"),
                    _statBox("≥ $threshold", "$aboveThreshold %"),
                    _statBox("Stabilité", stdDev != null ? stdDev.toStringAsFixed(2) : "-"),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: buildList(grades)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
