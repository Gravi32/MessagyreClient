import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/pages/assignments/widgets/assignments_top_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/assignment_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/tag.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

final assignmentListPageKey = GlobalKey<AssignmentsListPageState>();

class AssignmentsListPage extends StatefulWidget {
  const AssignmentsListPage({super.key});

  @override
  State<StatefulWidget> createState() => AssignmentsListPageState();
}

class AssignmentsListPageState extends State<AssignmentsListPage> {
  final network = NetworkService();
  final database = DatabaseService();
  final globals = GlobalsService();

  final sharedAssignmentsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

  int lastSentAssignmentsCount = 0;
  String? activeFilter;

  final searchFieldFocusNode = FocusNode();

  Widget buildPlaceholder() {
    return Column(
      mainAxisAlignment: .center,
      spacing: 2,
      children: [
        const SizedBox(height: 60),
        CustomIcon(icon: HugeIcons.strokeRoundedDashedLine02, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),
        const SizedBox(height: 8),
        Text(
          "Rien pour le moment...",
          style: TextStyle(fontWeight: .w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22),
        ),
        Text(
          "Vos devoirs s'afficheront ici",
          style: TextStyle(fontWeight: .w400, color: AppColors.tertiaryText.adaptTo(context)),
        ),
        CupertinoButton(
          onPressed: () => Navigator.push(context, CupertinoSheetRoute(builder: (context) => NewAssignmentPage(), enableDrag: false)),
          padding: .only(top: 40),
          child: Row(
            mainAxisAlignment: .center,
            spacing: 6,
            children: [
              Text("Ajouter un devoir", style: TextStyle(fontWeight: .w400)),
              CustomIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> fetchSharedAssignments() async {
    final apiResponse = await network.get("/shared/assignments/get");
    if (apiResponse.statusCode != 200 && mounted) {
      showCupertinoDialog(context: context, builder: (_) => Dialog.networkError(apiResponse));
      return;
    }
    sharedAssignmentsNotifier.value = List<Map<String, dynamic>>.from(tryJsonDecode(apiResponse.body) ?? []);
  }

  @override
  void initState() {
    super.initState();

    MainPage.pageIndex.addListener(() async {
      if (MainPage.pageIndex.value != 1) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => App.pages[1].showBadge.value = false);
      globals.persistent.setInt("LastSeenAssignmentDueDate", DateTime.now().dateOnly().add(Duration(days: 1)).millisecondsSinceEpoch);
    });

    searchFieldFocusNode.addListener(() => setState(() {}));

    final lastSeenDueDate = globals.persistent.getInt("LastSeenAssignmentDueDate") ?? 0;
    final tomorrowsAssignments = database.assignments.getAll().where((a) => a.dueDate.isSameDayAs(DateTime.now().dateOnly().add(const Duration(days: 1))));

    if (tomorrowsAssignments.isNotEmpty && lastSeenDueDate < DateTime.now().dateOnly().add(Duration(days: 1)).millisecondsSinceEpoch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => App.pages[1].showBadge.value = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      topBar: TopBar.sliver(title: "Devoirs"),
      field: Field.search(
        placeholder: "Chercher une branche...",
        focusNode: searchFieldFocusNode,
        onChanged: (content) => setState(() => activeFilter = content.isEmpty ? null : content.toLowerCase()),
      ),
      onRefresh: () => fetchSharedAssignments(),
      onFloatingButtonTap: !searchFieldFocusNode.hasFocus && activeFilter == null
          ? () => showCupertinoSheet(context: context, builder: (context) => NewAssignmentPage(), enableDrag: false)
          : null,
      body: ValueListenableBuilder(
        valueListenable: sharedAssignmentsNotifier,
        builder: (_, sharedAssignments, _) => StreamBuilder(
          stream: database.assignments.watchAll(),
          builder: (context, snapshot) {
            final allAssignments =
                snapshot.data?.where((s) => activeFilter != null ? ((s.title ?? "") + s.content).toLowerCase().contains(activeFilter!) : true) ?? [];

            final today = DateTime.now().dateOnly();
            final tomorrow = today.add(const Duration(days: 1));

            final pastAssignments = allAssignments.where((a) => a.dueDate.isBefore(today));
            final todaysAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(today));
            final tomorrowsAssignments = allAssignments.where((a) => a.dueDate.isSameDayAs(tomorrow));
            final plannedAssignments = allAssignments.where((a) => a.dueDate.isAfter(tomorrow));

            if (lastSentAssignmentsCount != allAssignments.length) {
              lastSentAssignmentsCount = allAssignments.length;
              network.post("/analytics/upload-assignments-count", {"Assignments": allAssignments.length});
            }

            Widget buildSection(
              Iterable<Assignment> list,
              String title, {
              Color? titleColor,
              bool tilesShowDate = true,
              bool dimTiles = false,
              bool reverseSort = false,
            }) {
              list = list.sorted((a, b) => a.dueDate.compareTo(b.dueDate));

              if (reverseSort) list = list.toList().reversed;

              return ListSection(
                title: title,
                useLargeTitle: true,
                margin: .only(top: 16),
                children: list
                    .map((assignment) => AssignmentTile(key: ValueKey(assignment.referenceId), assignment: assignment, showDate: tilesShowDate, dim: dimTiles))
                    .toList(),
              );
            }

            Widget buildSharedAssignmentsSection(
              Iterable<Map<String, dynamic>> list,
              String title, {
              Color? titleColor,
              bool tilesShowDate = true,
              bool dimTiles = false,
              bool reverseSort = false,
            }) {
              list = list.sorted((a, b) => (a["DueDate"] ?? DateTime(2000)).compareTo(b["DueDate"] ?? DateTime(2000)));

              if (reverseSort) list = list.toList().reversed;

              return ListSection(
                title: title,
                useLargeTitle: true,
                margin: .only(top: 16),
                children: list.map((sharedAssignment) {
                  final type = AssignmentType.values.asNameMap()[(sharedAssignment["Type"] ?? "assignment").toLowerCase()];
                  final content = sharedAssignment["Content"];

                  return ListTile(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: 8,
                      children: [
                        // Title and tag
                        Row(
                          spacing: 10,
                          children: [
                            // Test tag
                            if (type == .test) Tag(text: "TEST", color: AppColors.red),

                            // Leave tag
                            if (type == .leave) Tag(text: "CONGÉ", color: AppColors.orange),

                            // Title
                            Expanded(
                              child: Text(
                                type == .test ? sharedAssignment["Title"] ?? "Test sans titre" : content,
                                style: AppStyles.secondaryHeader(context).copyWith(color: type == .test ? AppColors.red : null),
                                softWrap: true,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),

                        // Description
                        if (type == .test && content.isNotEmpty)
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                            child: Text(content, style: AppStyles.primaryText(context), softWrap: true, maxLines: 5),
                          ),

                        // Subject and date
                        Row(
                          spacing: 8,
                          children: [
                            //  if (assignment.subject.value != null) SubjectBadge(subject: assignment.subject.value!, size: 22),
                            // Expanded(
                            //   child: Text(
                            //     type == .leave
                            //         ? "Prévu pour ${formatDate(assignment.dueDate, includeArticle: true)}"
                            //         : "${assignment.subject.value?.name}${widget.showDate ? "  •  ${formatDate(assignment.dueDate)}" : ""}",
                            //     style: AppStyles.primaryText(context),
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }

            return ListView(
              padding: .zero,
              children: [
                if (!searchFieldFocusNode.hasFocus && activeFilter == null) AssignmentsTopCard(),
                if (sharedAssignments.isNotEmpty) buildSharedAssignmentsSection(sharedAssignments, "Partagés"),
                if (todaysAssignments.isNotEmpty) buildSection(todaysAssignments, "Pour aujourd'hui", tilesShowDate: false),
                if (tomorrowsAssignments.isNotEmpty) buildSection(tomorrowsAssignments, "Pour demain", tilesShowDate: false),
                if (plannedAssignments.isNotEmpty) buildSection(plannedAssignments, "À venir"),
                if (pastAssignments.isNotEmpty) buildSection(pastAssignments, "Passés", dimTiles: true, reverseSort: true),
                if (allAssignments.isEmpty) buildPlaceholder(),
                BottomSpacing(includeBottomBar: true),
              ],
            );
          },
        ),
      ),
    );
  }
}
