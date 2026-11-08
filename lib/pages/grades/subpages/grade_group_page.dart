import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/utility/widgets/basics/card_group.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';

class GradeGroupPage extends StatefulWidget {
  final String groupName;
  final Subject groupSubject;

  const GradeGroupPage({super.key, required this.groupName, required this.groupSubject});

  @override
  State<StatefulWidget> createState() => _GradeGroupPageState();
}

class _GradeGroupPageState extends State<GradeGroupPage> {
  final database = DatabaseService();

  void showNewGradePopup({Grade? toEdit}) async {
    await showCupertinoSheet(
      context: context,
      enableDrag: false,
      builder: (context) => NewGradePage(groupName: widget.groupName, subject: widget.groupSubject, toEdit: toEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      onFloatingButtonTap: showNewGradePopup,
      topBar: TopBar.sliverWithChevron(context, title: widget.groupName, icon: HugeIcons.strokeRoundedLayers01),
      body: StreamBuilder(
        stream: database.grades.watchAll(),
        builder: (context, snapshot) {
          final groupGrades = (snapshot.data ?? database.grades.getAll()).where((grade) => grade.groupName == widget.groupName).sorted((gradeA, gradeB) {
            return gradeB.date.compareTo(gradeA.date);
          });

          return ListView(
            padding: const .only(top: AppSpacing.m),
            children: [
              CardGroup(
                separatorInset: GradeBar.separatorInset,
                children: [
                  for (final grade in groupGrades)
                    GradeBar(
                      gradeData: grade,
                      onTap: () => showNewGradePopup(toEdit: grade),
                    ),
                ],
              ),
              const BottomSpacing(),
            ],
          );
        },
      ),
    );
  }
}
