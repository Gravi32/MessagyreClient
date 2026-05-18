import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class RecentGradesPage extends StatefulWidget {
  const RecentGradesPage({super.key});

  @override
  State<StatefulWidget> createState() => _RecentGradesPageState();
}

class _RecentGradesPageState extends State<RecentGradesPage> {
  final database = DatabaseService();

  String? activeFilter;

  void showNewGradePopup(Grade toEdit) async {
    await showCupertinoModalBottomSheet<Grade?>(
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
      field: Field.search(placeholder: "Chercher une note...", onChanged: (content) => setState(() => activeFilter = content.isEmpty ? null : content.toLowerCase())),
      body: ListView(
        padding: .zero,
        children: grouped.entries.map((entry) {
          final start = entry.key;
          final end = start.add(const Duration(days: 6));

          return ListSection(
            title: "${formatDate(start).capitalize()} - ${formatDate(end)}",
            margin: .only(top: 16),
            children: entry.value.map((grade) {
              return ListTile(
                buildChevron: false,
                padding: .symmetric(horizontal: 12, vertical: 8),
                child: GradeBar(gradeData: grade, onTap: () => showNewGradePopup(grade), showSubject: true),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
