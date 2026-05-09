import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class GradeGroupPage extends StatefulWidget {
  final String groupName;
  final Subject groupSubject;

  const GradeGroupPage({super.key, required this.groupName, required this.groupSubject});

  @override
  State<StatefulWidget> createState() => _GradeGroupPageState();
}

class _GradeGroupPageState extends State<GradeGroupPage> {
  final database = DatabaseService();

  Widget buildList(List<Grade> thisGroupGrades) {
    // Sorting grades by date
    thisGroupGrades.sort((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    return ListView.separated(
      padding: .only(top: 8),
      itemCount: thisGroupGrades.length,
      itemBuilder:
          (context, index) => GradeBar(gradeData: thisGroupGrades.elementAt(index), onTap: () => showNewGradePopup(toEdit: thisGroupGrades.elementAt(index))),
      separatorBuilder: (context, index) => SizedBox(height: 8),
    );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    await showCupertinoSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder: (context) => NewGradePage(groupName: widget.groupName, subject: widget.groupSubject, toEdit: toEdit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                CupertinoSliverNavigationBar(
                  largeTitle: Row(
                    spacing: 10,
                    children: [CustomIcon(icon: HugeIcons.strokeRoundedSelect01, color: AppColors.text.adaptTo(context), size: 28), Text(widget.groupName)],
                  ),
                  previousPageTitle: "Retour",
                ),
              ];
            },
            body: SafeArea(
              top: false,
              child: Padding(
                padding: .symmetric(horizontal: 16),
                child: StreamBuilder(
                  stream: database.grades.watchAll(),
                  builder: (context, snapshot) {
                    return buildList((snapshot.data ?? database.grades.getAll()).where((grade) => grade.groupName == widget.groupName).toList());
                  },
                ),
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: GestureDetector(
              onTap: showNewGradePopup,
              child: Container(
                padding: .all(14),
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: .circular(20)),
                child: CustomIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
