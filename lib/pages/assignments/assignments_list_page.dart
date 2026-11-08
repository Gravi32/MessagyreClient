import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/assignments/shared_assignment.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/pages/assignments/widgets/assignments_top_card.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/assignment_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/empty_state.dart';
import 'package:messagyre_client/utility/widgets/basics/field.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

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

  final searchFieldFocusNode = FocusNode();

  List<SharedAssignment> sharedAssignments = [];

  /// Why the shared assignments are missing, shown under the list (null when they loaded)
  String? sharedAssignmentsNotice;

  int lastSentAssignmentsCount = -1;
  String? activeFilter;

  bool get isSearching => searchFieldFocusNode.hasFocus || activeFilter != null;

  void openNewAssignmentPage() => showCupertinoSheet(context: context, builder: (context) => NewAssignmentPage(), enableDrag: false);

  Future<void> fetchSharedAssignments() async {
    final response = await network.get("/shared/assignments/get");
    if (!mounted) return;

    setState(() {
      if (response.statusCode == 200) {
        sharedAssignments = SharedAssignment.parseList(tryJsonDecode(response.body));
        sharedAssignmentsNotice = null;
      } else if (response.statusCode == 400 && response.body.contains("NoClass")) {
        sharedAssignments = [];
        sharedAssignmentsNotice = AppStrings.sharedNoClass;
      } else {
        // The ones already shown stay: only the next refresh can tell if they changed
        sharedAssignmentsNotice = AppStrings.errorFor(response);
      }
    });
  }

  void onPageChanged() {
    if (MainPage.pageIndex.value != 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => App.pages[1].showBadge.value = false);
    globals.persistent.setInt("LastSeenAssignmentDueDate", DateTime.now().dateOnly().add(const Duration(days: 1)).millisecondsSinceEpoch);
  }

  void onSearchFocusChanged() => setState(() {});

  @override
  void initState() {
    super.initState();

    MainPage.pageIndex.addListener(onPageChanged);
    searchFieldFocusNode.addListener(onSearchFocusChanged);

    final tomorrow = DateTime.now().dateOnly().add(const Duration(days: 1));
    final lastSeenDueDate = globals.persistent.getInt("LastSeenAssignmentDueDate") ?? 0;
    final hasAssignmentsForTomorrow = database.assignments.getAll().any((a) => a.dueDate.isSameDayAs(tomorrow));

    if (hasAssignmentsForTomorrow && lastSeenDueDate < tomorrow.millisecondsSinceEpoch) {
      WidgetsBinding.instance.addPostFrameCallback((_) => App.pages[1].showBadge.value = true);
    }

    fetchSharedAssignments();
  }

  @override
  void dispose() {
    MainPage.pageIndex.removeListener(onPageChanged);
    searchFieldFocusNode.removeListener(onSearchFocusChanged);
    searchFieldFocusNode.dispose();
    super.dispose();
  }

  bool matchesFilter(Assignment assignment) {
    final filter = activeFilter;
    if (filter == null) return true;
    return "${assignment.title ?? ""} ${assignment.content} ${assignment.subject.value?.name ?? ""}".toLowerCase().contains(filter);
  }

  Widget buildSection(Iterable<Assignment> list, String title, {bool tilesShowDate = true, bool dimTiles = false, bool newestFirst = false}) {
    var sorted = list.sorted((a, b) => a.dueDate.compareTo(b.dueDate));
    if (newestFirst) sorted = sorted.reversed.toList();

    return ListSection(
      title: title,
      useLargeTitle: true,
      margin: const .only(top: AppSpacing.section),
      children: sorted.map((assignment) => AssignmentTile(key: ValueKey(assignment.id), assignment: assignment, showDate: tilesShowDate, dim: dimTiles)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Page.sliver(
      topBar: TopBar.sliver(title: AppStrings.tabAssignments),
      field: Field.search(
        placeholder: AppStrings.assignmentsSearch,
        focusNode: searchFieldFocusNode,
        onChanged: (content) => setState(() => activeFilter = content.trim().isEmpty ? null : content.trim().toLowerCase()),
      ),
      onRefresh: fetchSharedAssignments,
      onFloatingButtonTap: isSearching ? null : openNewAssignmentPage,
      body: StreamBuilder(
        stream: database.assignments.watchAll(),
        builder: (context, snapshot) {
          final everyAssignment = snapshot.data ?? [];

          if (snapshot.hasData && lastSentAssignmentsCount != everyAssignment.length) {
            lastSentAssignmentsCount = everyAssignment.length;
            network.post("/analytics/upload-assignments-count", {"Assignments": everyAssignment.length});
          }

          final assignments = everyAssignment.where(matchesFilter).toList();
          final shared = sharedAssignments.where((a) => activeFilter == null || a.matches(activeFilter!)).sorted((a, b) => a.dueDate.compareTo(b.dueDate));

          final today = DateTime.now().dateOnly();
          final tomorrow = today.add(const Duration(days: 1));

          final past = assignments.where((a) => a.dueDate.isBefore(today));
          final forToday = assignments.where((a) => a.dueDate.isSameDayAs(today));
          final forTomorrow = assignments.where((a) => a.dueDate.isSameDayAs(tomorrow));
          final upcoming = assignments.where((a) => a.dueDate.isAfter(tomorrow) && !a.dueDate.isSameDayAs(tomorrow));

          final isEmpty = assignments.isEmpty && shared.isEmpty;

          // Not a ListView: with pull to refresh the page already scrolls (see Page.sliver)
          return Column(
            crossAxisAlignment: .stretch,
            children: [
              if (!isSearching) const AssignmentsTopCard(),
              if (shared.isNotEmpty)
                ListSection(
                  title: AppStrings.sectionShared,
                  useLargeTitle: true,
                  margin: const .only(top: AppSpacing.section),
                  children: shared.map((assignment) => SharedAssignmentTile(key: ValueKey("shared-${assignment.id}"), assignment: assignment)).toList(),
                ),
              if (forToday.isNotEmpty) buildSection(forToday, AppStrings.sectionToday, tilesShowDate: false),
              if (forTomorrow.isNotEmpty) buildSection(forTomorrow, AppStrings.sectionTomorrow, tilesShowDate: false),
              if (upcoming.isNotEmpty) buildSection(upcoming, AppStrings.sectionUpcoming),
              if (past.isNotEmpty) buildSection(past, AppStrings.sectionPast, dimTiles: true, newestFirst: true),
              if (isEmpty)
                activeFilter != null
                    ? const EmptyState(icon: AppIcons.noResults, title: AppStrings.assignmentsNoResults)
                    : EmptyState(
                        icon: AppIcons.emptyList,
                        title: AppStrings.assignmentsEmptyTitle,
                        subtitle: AppStrings.assignmentsEmptySubtitle,
                        actionText: AppStrings.addAssignment,
                        actionIcon: AppIcons.add,
                        onAction: openNewAssignmentPage,
                      ),
              if (sharedAssignmentsNotice != null && !isSearching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.xl, AppSpacing.l, 0),
                  child: CustomText(sharedAssignmentsNotice!, textAlign: .center, style: AppStyles.footer(context).copyWith(color: AppColors.tertiaryText.adaptTo(context))),
                ),
              const BottomSpacing(includeBottomBar: true),
            ],
          );
        },
      ),
    );
  }
}
