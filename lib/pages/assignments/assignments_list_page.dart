import 'package:collection/collection.dart';
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

  Widget buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 2,
      children: [
        const SizedBox(height: 60),
        HugeIcon(icon: HugeIcons.strokeRoundedDashedLine02, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),
        const SizedBox(height: 8),
        Text("Rien pour le moment...", style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22)),
        Text("Vos devoirs s'afficheront ici", style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.tertiaryText.adaptTo(context))),
        CupertinoButton(
          onPressed: () => Navigator.push(context, CupertinoSheetRoute(builder: (context) => NewAssignmentPage(), enableDrag: false)),
          padding: EdgeInsets.only(top: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [Text("Ajouter un devoir", style: TextStyle(fontWeight: FontWeight.w400)), HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18)],
          ),
        ),
      ],
    );
  }

  Widget buildFloatingAddButton() {
    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 20,
      right: 20,
      child: CupertinoPressable(
        onTap: () => Navigator.push(context, CupertinoSheetRoute(builder: (context) => NewAssignmentPage(), enableDrag: false)),
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
                builder: (context, snapshot) {
                  final allAssignments = snapshot.data ?? [];

                  final today = DateTime.now().dateOnly();
                  final tomorrow = today.copyWith(day: today.day + 1);

                  final pastAssignments = allAssignments.where((a) => a.dueDate.isBefore(today));
                  final todaysAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(today));
                  final tomorrowsAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(tomorrow));
                  final plannedAssignments = allAssignments.where((a) => a.dueDate.isAfter(tomorrow));

                  List<Widget> buildSection(Iterable<Assignment> list, String title, {Color? titleColor, bool tilesShowDate = true, bool dimTiles = false}) {
                    list = list.sorted((a, b) => a.dueDate.compareTo(b.dueDate));

                    return [
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(title, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600, color: titleColor ?? AppColors.text.adaptTo(context))),
                      ),
                      CupertinoListSection.insetGrouped(
                        margin: EdgeInsets.zero,
                        backgroundColor: AppColors.transparent,
                        children: list.map((a) => AssignmentTile(key: ValueKey(a.referenceId), assignment: a, showDate: tilesShowDate, dim: dimTiles)).toList(),
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
                      if (allAssignments.isEmpty) buildPlaceholder(),
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
