import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/pages/assignments/widgets/assignments_top_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/assignment_tile.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';

final assignmentListPageKey = GlobalKey<AssignmentsListPageState>();

class AssignmentsListPage extends StatefulWidget {
  const AssignmentsListPage({super.key});

  @override
  State<StatefulWidget> createState() => AssignmentsListPageState();
}

class AssignmentsListPageState extends State<AssignmentsListPage> {
  final database = DatabaseService();

  Widget buildFloatingAddButton() {
    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 20,
      right: 20,
      child: CupertinoPressable(
        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => NewAssignmentPage())),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground.adaptTo(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.black.withAlpha(30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))],
        ),
        child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.text.adaptTo(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [CupertinoSliverNavigationBar(largeTitle: Text("Devoirs"))],
            body: SafeArea(
              top: false,
              child: StreamBuilder(
                stream: database.assignments.watchAll(),
                builder: (context, _) {
                  final allAssignments = database.assignments.getAll();

                  final today = DateTime.now().dateOnly();
                  final tomorrow = today.copyWith(day: today.day + 1);

                  final pastAssignments = allAssignments.where((a) => a.dueDate.isBefore(today));
                  final todaysAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(today));
                  final tomorrowsAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(tomorrow));
                  final plannedAssignments = allAssignments.where((a) => a.dueDate.isAfter(tomorrow));

                  List<Widget> buildSection(Iterable<Assignment> list, String title, {Color? titleColor, bool tilesShowDate = true, bool dimTiles = false}) {
                    return [
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(title, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: titleColor ?? AppColors.text.adaptTo(context))),
                      ),
                      CupertinoListSection.insetGrouped(
                        margin: EdgeInsets.zero,
                        backgroundColor: AppColors.transparent,
                        children: list.map((a) => AssignmentTile(assignment: a, showDate: tilesShowDate, dim: dimTiles)).toList(),
                      ),
                      const SizedBox(height: 30),
                    ];
                  }

                  return ListView(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    physics: const ClampingScrollPhysics(),
                    children: [
                      AssignmentsTopCard(),
                      if (todaysAssignments.isNotEmpty) ...buildSection(todaysAssignments, "Pour aujourd'hui", tilesShowDate: false),
                      if (tomorrowsAssignments.isNotEmpty) ...buildSection(tomorrowsAssignments, "Pour demain", tilesShowDate: false),
                      if (plannedAssignments.isNotEmpty) ...buildSection(plannedAssignments, "À venir"),
                      if (pastAssignments.isNotEmpty) ...buildSection(pastAssignments, "Passés", dimTiles: true),
                    ],
                  );
                },
              ),
            ),
          ),
          buildFloatingAddButton(),
        ],
      ),
    );
  }
}
