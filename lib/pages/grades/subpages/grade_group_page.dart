import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/pages/grades/subpages/new_grade_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/grade_bar.dart';

class GradeGroupPage extends StatefulWidget {
  final List<Grade> grades;

  const GradeGroupPage({super.key, required this.grades});

  @override
  State<StatefulWidget> createState() => _GradeGroupPageState();
}

class _GradeGroupPageState extends State<GradeGroupPage> {
  final database = DatabaseService().isar;

  Widget buildList() {
    // Sorting grades by date
    widget.grades.sort((gradeA, gradeB) {
      return gradeB.date.compareTo(gradeA.date);
    });

    return ListView.separated(
      padding: EdgeInsets.only(top: 8),
      itemCount: widget.grades.length,
      itemBuilder:
          (context, index) => GradeBar(gradeData: widget.grades.elementAt(index), onTap: () => showNewGradePopup(toEdit: widget.grades.elementAt(index))),
      separatorBuilder: (context, index) => SizedBox(height: 8),
    );
  }

  void showNewGradePopup({Grade? toEdit}) async {
    final newGrade = await showCupertinoSheet<Grade?>(
      context: context,
      enableDrag: false,
      builder:
          (context) => NewGradePage(
            subject: widget.grades.isNotEmpty ? widget.grades.first.subject.value : null,
            toEdit: toEdit,
            groupName: widget.grades.isNotEmpty ? widget.grades.first.groupName : null,
          ),
    );

    setState(() {});

    // Closing the page if empty
    if (widget.grades.isEmpty && newGrade?.groupName == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
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
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedSelect01, color: AppColors.text.adaptTo(context), size: 28),
                      Text(widget.grades.isNotEmpty ? (widget.grades.first.groupName ?? "Groupe") : "Groupe"),
                    ],
                  ),
                  previousPageTitle: "Retour",
                ),
              ];
            },
            body: SafeArea(top: false, child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: buildList())),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: GestureDetector(
              onTap: showNewGradePopup,
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.secondaryBackground.adaptTo(context), borderRadius: BorderRadius.circular(20)),
                child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
