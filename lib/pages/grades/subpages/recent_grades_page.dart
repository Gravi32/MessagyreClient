import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class RecentGradesPage extends StatefulWidget {
  const RecentGradesPage({super.key});

  @override
  State<StatefulWidget> createState() => _RecentGradesPageState();
}

class _RecentGradesPageState extends State<RecentGradesPage> {
  final database = DatabaseService();

  Widget buildList() {
    late final allGrades = database.grades.getAll();

    return Column(
      spacing: 1,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 8),

            children: [
              ...allGrades
                  .where((grade) => grade.groupName == null)
                  .toList()
                  .sorted((gradeA, gradeB) {
                    return gradeB.date.compareTo(gradeA.date);
                  })
                  .map((grade) => GradeBar(gradeData: grade, onTap: () => showNewGradePopup(grade))),
            ],
          ),
        ),
      ],
    );
  }

  void showNewGradePopup(Grade toEdit) async {
    await showCupertinoModalBottomSheet<Grade?>(context: context, enableDrag: false, builder: (context) => NewGradePage(toEdit: toEdit));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CupertinoSliverNavigationBar(largeTitle: Text("Toutes les notes"), previousPageTitle: "Retour")];
        },
        body: SafeArea(top: false, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: buildList())),
      ),
    );
  }
}
