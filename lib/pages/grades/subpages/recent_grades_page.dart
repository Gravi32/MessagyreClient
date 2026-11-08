import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';

class RecentGradesPage extends StatefulWidget {
  const RecentGradesPage({super.key});

  @override
  State<StatefulWidget> createState() => _RecentGradesPageState();
}

class _RecentGradesPageState extends State<RecentGradesPage> {
  final database = DatabaseService();

  String? activeFilter;

  void showNewGradePopup(Grade toEdit) async {
    await showCupertinoSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder: (context) => NewGradePage(toEdit: toEdit),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final grades = database.grades
        .getAll()
        .sorted((a, b) => b.date.compareTo(a.date))
        .where((s) => activeFilter != null ? s.title.toLowerCase().contains(activeFilter!) : true);

    final Map<DateTime, List<Grade>> grouped = {};

    for (final grade in grades) {
      final weekStart = grade.date.subtract(Duration(days: grade.date.weekday - 1)).dateOnly();
      grouped.putIfAbsent(weekStart, () => []).add(grade);
    }

    return Page.sliver(
      topBar: TopBar.sliverWithChevron(context, title: "Toutes les notes"),
      field: Field.search(
        placeholder: "Chercher une note...",
        onChanged: (content) => setState(() => activeFilter = content.isEmpty ? null : content.toLowerCase()),
      ),
      body: ListView(
        padding: const .only(top: AppSpacing.m),
        children: [
          for (final entry in grouped.entries)
            Padding(
              padding: const .only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  // The week
                  Padding(
                    padding: const .only(left: 4, bottom: AppSpacing.s),
                    child: Text(
                      "${formatDate(entry.key).capitalize()} – ${formatDate(entry.key.add(const Duration(days: 6)))}",
                      style: AppStyles.footnote(context).copyWith(fontWeight: .w600),
                    ),
                  ),
                  CardGroup(
                    separatorInset: GradeBar.separatorInset,
                    children: [for (final grade in entry.value) GradeBar(gradeData: grade, onTap: () => showNewGradePopup(grade), showSubject: true)],
                  ),
                ],
              ),
            ),
          const BottomSpacing(),
        ],
      ),
    );
  }
}
