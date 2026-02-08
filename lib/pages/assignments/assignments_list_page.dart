import 'dart:math';

import 'package:device_calendar/device_calendar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/assignments/subpages/new_assignment_page.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/assignment_card.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

final assignmentListPageKey = GlobalKey<AssignmentsListPageState>();

class AssignmentsListPage extends StatefulWidget {
  const AssignmentsListPage({super.key});

  @override
  State<StatefulWidget> createState() => AssignmentsListPageState();
}

class AssignmentsListPageState extends State<AssignmentsListPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final calendar = DeviceCalendarPlugin();

  late final PageController timelineController;
  late final Box<Assignment> allAssignment;
  late final Box<Grade> allGrades;

  AssignmentViewMode currentViewMode = AssignmentViewMode.byDefault;

  late Map<DateTime, List<Assignment>> assignmentByDate;
  final Map<int, AssignmentCardController> assignmentCardControllers = {};
  final Map<int, ScrollController> dayListViewControllers = {};
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  Calendar? targetCalendar;
  List<Assignment> nearbyTests = [];
  bool isNearbyTestsNotifierHidden = false;
  int currentViewingTestIndex = -1;
  bool isAnimating = false;

  List<DateTime> get allDays {
    final rawList = List<DateTime>.generate(globals.schoolEnd.difference(globals.schoolStart).inDays, (i) => globals.schoolStart.add(Duration(days: i)));

    return globals.settings.includeWeekends ? rawList : rawList.where((d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday).toList();
  }

  int get tomorrowPageIndex {
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));

    if (tomorrow.weekday == DateTime.saturday) {
      tomorrow = tomorrow.add(Duration(days: 2));
    } else if (tomorrow.weekday == DateTime.sunday) {
      tomorrow = tomorrow.add(Duration(days: 1));
    }

    final index = allDays.indexWhere((d) => d.isSameDayAs(tomorrow));

    return index >= 0 ? index : 0;
  }

  Future<bool> requestPermissions() async {
    final result = await calendar.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<void> animateToPage(int pageIndex) async {
    isAnimating = true;
    await timelineController.animateToPage(pageIndex, duration: const Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
    isAnimating = false;
    return;
  }

  Future<void> showAssignment(Assignment target) async {
    await animateToPage(allDays.indexWhere((date) => date.isSameDayAs(target.dueDate)));

    assignmentCardControllers[target.key as int]?.triggerBounceEffect();

    return;
  }

  void groupAssignmentByDate() {
    final grouped = <DateTime, List<Assignment>>{};
    nearbyTests.clear();

    for (var hw in allAssignment.values) {
      final daysLeft = hw.dueDate.difference(DateTime.now()).inDays;

      if (hw.isTest && daysLeft >= 0 && daysLeft < 7) nearbyTests.add(hw);
      grouped.putIfAbsent(hw.dueDate, () => []).add(hw);
    }

    for (var list in grouped.values) {
      list.sort((a, b) {
        if (a.isTest != b.isTest) {
          return a.isTest ? -1 : 1;
        }

        if (a.isGraded != b.isGraded) {
          return a.isGraded ? -1 : 1;
        }

        return 0;
      });
    }

    setState(() {
      assignmentByDate = grouped;
    });
  }

  void showNewAssignmentPopup({Assignment? toEdit, DateTime? dueDateOverride}) async {
    final result = await showCupertinoModalBottomSheet(
      expand: false,
      enableDrag: false,
      previousRouteAnimationCurve: Curves.ease,
      clipBehavior: Clip.none,
      backgroundColor: CupertinoColors.transparent,
      context: context,
      builder: (context) => NewAssignmentPage(toEdit: toEdit, dueDateOverride: dueDateOverride),
    );

    final assignment = result.assignment;

    if (assignment == null) return;

    if (toEdit != null) {
      // If the subject was changed while editing, updates the linked grade.
      if (assignment.referenceId != null) {
        allGrades.values.where((grade) => grade.referenceId == assignment.referenceId).forEach((grade) {
          grade.subject = assignment.subject;
          grade.save();
        });
      }

      toEdit.delete();
    }

    allAssignment.add(assignment);

    if (result.editsCalendar) {
      final permissionResult = await calendar.hasPermissions();
      if (!permissionResult.isSuccess || permissionResult.data != true) {
        final requestResult = await calendar.requestPermissions();
        if (!requestResult.isSuccess || requestResult.data != true) return;
      }

      if (targetCalendar == null) return;

      String title = "Devoir ${SubjectHelper.withPreposition(assignment.subject)}";
      if (assignment.isGraded) {
        title = "Devoir noté ${SubjectHelper.withPreposition(assignment.subject)}";
      } else if (assignment.isTest) {
        title = "Test ${SubjectHelper.withPreposition(assignment.subject)}";
      }

      String description = "";
      if (assignment.title != null) description += "${assignment.title}\n\n";
      if (assignment.content?.isNotEmpty) description += assignment.content;
      if (description.isNotEmpty) description += "\n\nCréé par Messagyre.";

      final timeZone = getLocation("Europe/Zurich");

      final event = Event(
        targetCalendar!.id,
        eventId: assignment.calendarEventId,
        title: title,
        start: TZDateTime.from(assignment.dueDate, timeZone),
        end: TZDateTime.from(assignment.dueDate.add(const Duration(minutes: 45)), timeZone),
        allDay: true,
        description: description,
      );

      final result = await calendar.createOrUpdateEvent(event);
      assignment.calendarEventId = result?.data ?? assignment.calendarEventId;
      assignment.save();
    }
  }

  Widget buildNearbyTestsNotifier() {
    void onTap() async {
      HapticFeedback.lightImpact();
      setState(() {
        if (currentViewingTestIndex >= nearbyTests.length - 1) {
          currentViewingTestIndex = 0;
        } else {
          currentViewingTestIndex += 1;
        }
      });

      final targetTest = nearbyTests[currentViewingTestIndex];
      showAssignment(targetTest);
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Shimmer(
                duration: Duration(seconds: 10),
                interval: Duration(seconds: 10),
                color: CupertinoColors.systemGrey.resolveFrom(context).withValues(alpha: 0.15),
                colorOpacity: 0.3,
                enabled: true,
                direction: ShimmerDirection.fromLeftToRight(),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(minHeight: 100),
                  padding: EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        CupertinoColors.secondarySystemBackground.resolveFrom(context),
                        CupertinoColors.secondarySystemBackground.resolveFrom(context).withBrightness(globals.appBrightness == Brightness.dark ? .1 : .02),
                      ],
                      stops: [0, 1],
                      center: Alignment.bottomRight,
                      radius: 3,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: -10,
                        right: -10,
                        child: Transform.rotate(
                          angle: pi / 40,
                          child: Opacity(opacity: 1, child: Image.asset("assets/warningSign.png", width: 100, height: 120)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              nearbyTests.length > 1
                                  ? "*Plusieurs* tests approchent !"
                                  : "Test *${SubjectHelper.withPreposition(nearbyTests.first.subject)}* ${DateFormat.EEEE('fr_CH').format(nearbyTests.first.dueDate)} !",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context)),
                              boldWeight: FontWeight.w800,
                            ),
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                              child:
                                  nearbyTests.length > 1
                                      ? Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        spacing: 2,
                                        children:
                                            nearbyTests.map((test) {
                                              final isSelected = nearbyTests.indexOf(test) == currentViewingTestIndex;

                                              return TweenAnimationBuilder<double>(
                                                key: ValueKey(test.key),
                                                tween: Tween<double>(begin: 1.0, end: isSelected ? 0.6 : 1.0),
                                                duration: Duration(milliseconds: isSelected ? 500 : 1000),
                                                onEnd: () {
                                                  if (isSelected) {
                                                    Future.delayed(Duration(milliseconds: 500), () {
                                                      if (mounted) setState(() {});
                                                    });
                                                  }
                                                },
                                                builder: (context, value, _) {
                                                  final baseColor = CupertinoColors.secondaryLabel.resolveFrom(context);
                                                  return Opacity(
                                                    opacity: value,
                                                    child: CustomText(
                                                      "• *${SubjectHelper.toFrench(test.subject)}* ${DateFormat.EEEE('fr_CH').format(test.dueDate)}",
                                                      style: TextStyle(fontSize: 16, color: baseColor.withAlpha(isSelected ? 255 : 160)),
                                                      boldWeight: FontWeight.w600,
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                      )
                                      : Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        spacing: 4,
                                        children: [
                                          HugeIcon(
                                            icon: HugeIcons.strokeRoundedCalendar04,
                                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                                            size: 16,
                                          ),
                                          Text(
                                            DateFormat('d MMMM', 'fr_CH').format(nearbyTests.first.dueDate),
                                            style: TextStyle(fontSize: 18, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                                          ),
                                        ],
                                      ),
                            ),

                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(vertical: 2).add(EdgeInsetsGeometry.only(bottom: 2, top: 6)),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ShaderMask(
                                    shaderCallback: (rect) {
                                      return LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [CupertinoColors.white, CupertinoColors.transparent],
                                      ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: Dash(
                                      direction: Axis.horizontal,
                                      length: constraints.maxWidth - 40,
                                      dashLength: 6,
                                      dashGap: 3,
                                      dashThickness: 1,
                                      dashColor: CupertinoColors.quaternaryLabel.resolveFrom(context),
                                      dashBorderRadius: 2,
                                    ),
                                  );
                                },
                              ),
                            ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 4,
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 16),
                                Text("Appuyez pour voir", style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 10,
          child: GestureDetector(
            onTap: () => setState(() => isNearbyTestsNotifierHidden = true),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: CupertinoColors.secondarySystemBackground.resolveFrom(context)),
              child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, color: CupertinoColors.label.resolveFrom(context), size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildAssignmentList() {
    final now = DateTime.now();

    void deleteAssignment(Assignment target) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: Text("Supprimer le devoir"),
              content: Text("Le devoir sera supprimé. Cette action est irréversible."),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("Annuler", style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.2))),
                ),
                CupertinoDialogAction(
                  onPressed: () {
                    if (target.calendarEventId != null && targetCalendar?.id != null) {
                      calendar.deleteEvent(targetCalendar?.id, target.calendarEventId);
                    }
                    target.delete();
                    Navigator.pop(dialogContext);
                  },
                  child: Text("Supprimer", style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context))),
                ),
              ],
            ),
      );
    }

    switch (currentViewMode) {
      case AssignmentViewMode.byDueDate:
        final sortedAssignment = allAssignment.values.toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          itemCount: sortedAssignment.length,
          itemBuilder: (context, index) {
            final date = sortedAssignment[index].dueDate;
            final formattedDate = formatDate(date);
            final opacity = date.isBefore(now) ? 0.5 : 1.0;
            final assignment = sortedAssignment[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index == 0 || !sortedAssignment[index - 1].dueDate.isSameDayAs(date)) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 6,
                    children: [
                      Text(
                        "Pour ${formatDate(date, includeArticle: true)}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.label.resolveFrom(context).withValues(alpha: opacity),
                        ),
                      ),
                      if (int.tryParse(formattedDate[0]) == null)
                        Text(
                          DateFormat("${formattedDate == "aujourd'hui" || formattedDate == "hier" ? "EEEE " : ""}d MMMM", "fr_CH").format(date),
                          style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                ],
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: opacity,
                    child: AssignmentCard(
                      assignment: assignment,
                      controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                      onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                      onDeleteButtonClicked: () => deleteAssignment(assignment),
                      onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => assignment.isMarkedAsDone = isMarkedAsDone),
                    ),
                  ),
                ),
              ],
            );
          },
        );

      case AssignmentViewMode.bySubject:
        final assignmentListBySubject = <Subject, List<Assignment>>{};

        for (var hw in allAssignment.values) {
          assignmentListBySubject.putIfAbsent(hw.subject, () => []).add(hw);
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: SubjectHelper.sortedSubjects.length,
          itemBuilder: (context, index) {
            final subject = SubjectHelper.sortedSubjects[index];
            final subjectAssignment = assignmentListBySubject[subject];

            return subjectAssignment == null
                ? SizedBox.shrink()
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: 6,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 140),
                          child: Text(
                            SubjectHelper.toFrench(subject),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Text(
                          "${subjectAssignment.length} ${subjectAssignment.length == 1 ? "Devoir" : "Devoirs"}",
                          style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ...subjectAssignment.map(
                      (assignment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: assignment.dueDate.isBefore(now) ? 0.5 : 1.0,
                          child: AssignmentCard(
                            assignment: assignment,
                            controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                            onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                            onDeleteButtonClicked: () => deleteAssignment(assignment),
                            onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => assignment.isMarkedAsDone = isMarkedAsDone),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                );
          },
        );

      case AssignmentViewMode.testsFirst:
        final sortedAssignment =
            allAssignment.values.toList()
              ..sort((a, b) => b.dueDate.compareTo(a.dueDate))
              ..sort((a, b) {
                if (a.isTest && !b.isTest) return -1;
                if (!a.isTest && b.isTest) return 1;
                return 0;
              });

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedAssignment.length,
          itemBuilder: (context, index) {
            final date = sortedAssignment[index].dueDate;
            final formattedDate = formatDate(date);
            final opacity = date.isBefore(now) ? 0.5 : 1.0;
            final assignment = sortedAssignment[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: [
                    Text(
                      "Pour ${formatDate(date, includeArticle: true)}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context).withValues(alpha: opacity)),
                    ),
                    if (int.tryParse(formattedDate[0]) == null)
                      Text(
                        DateFormat("${formattedDate == "aujourd'hui" || formattedDate == "hier" ? "EEEE " : ""}d MMMM", "fr_CH").format(date),
                        style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      ),
                  ],
                ),
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: opacity,
                    child: AssignmentCard(
                      assignment: assignment,
                      controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                      onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                      onDeleteButtonClicked: () => deleteAssignment(assignment),
                      onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => assignment.isMarkedAsDone = isMarkedAsDone),
                    ),
                  ),
                ),
              ],
            );
          },
        );

      case AssignmentViewMode.testsOnly:
        final sortedAssignment = allAssignment.values.where((hw) => hw.isTest).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedAssignment.length,
          itemBuilder: (context, index) {
            final date = sortedAssignment[index].dueDate;
            final formattedDate = formatDate(date);
            final opacity = date.isBefore(now) ? 0.5 : 1.0;
            final assignment = sortedAssignment[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: [
                    Text(
                      "Pour ${formatDate(date, includeArticle: true)}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context).withValues(alpha: opacity)),
                    ),
                    if (int.tryParse(formattedDate[0]) == null)
                      Text(
                        DateFormat("${formattedDate == "aujourd'hui" || formattedDate == "hier" ? "EEEE " : ""}d MMMM", "fr_CH").format(date),
                        style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                      ),
                  ],
                ),
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: opacity,
                    child: AssignmentCard(
                      assignment: assignment,
                      controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                      onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                      onDeleteButtonClicked: () => deleteAssignment(assignment),
                      onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => assignment.isMarkedAsDone = isMarkedAsDone),
                    ),
                  ),
                ),
              ],
            );
          },
        );

      case AssignmentViewMode.all:
        final sortedAssignment = allAssignment.values.toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedAssignment.length,
          itemBuilder: (context, index) {
            final assignment = sortedAssignment[index];
            final opacity = assignment.dueDate.isBefore(now) ? 0.5 : 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: opacity,
                child: AssignmentCard(
                  assignment: assignment,
                  controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                  onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                  onDeleteButtonClicked: () => deleteAssignment(assignment),
                  onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => assignment.isMarkedAsDone = isMarkedAsDone),
                ),
              ),
            );
          },
        );

      case AssignmentViewMode.searchMode:
        final query = searchController.text.trim().toLowerCase();
        final sortedAssignment =
            query.isEmpty ? [] : SubjectHelper.searchBySimilarity(query, allAssignment.toMap().map((key, value) => MapEntry(value.subject, value)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                sortedAssignment.isEmpty
                    ? "Recherchéz un devoir..."
                    : "${sortedAssignment.length} ${sortedAssignment.length == 1 ? "Résultat" : "Résultats"} ${query.isEmpty ? "" : "pour '$query'"}",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                itemCount: sortedAssignment.length,
                itemBuilder: (context, index) {
                  final date = sortedAssignment[index].dueDate;
                  final assignment = sortedAssignment[index];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "pour ${formatDate(date, includeArticle: true)}",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                      ),
                      SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AssignmentCard(
                          assignment: assignment,
                          controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                          onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                          onDeleteButtonClicked: () => deleteAssignment(assignment),
                          onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => assignment.isMarkedAsDone = isMarkedAsDone),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );

      default:
        return PageView.builder(
          controller: timelineController,
          itemCount: allDays.length,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: PageScrollPhysics(),
          itemBuilder: (context, index) {
            final date = allDays[index].dateOnly();
            final isPassed = date.isBefore(now);
            final opacity = isPassed ? 0.5 : 1.0;

            final thisDaysAssignment = assignmentByDate[date] ?? [];
            final formattedDate = formatDate(date);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Pour ${formatDate(date, includeArticle: true)}",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.label.resolveFrom(context).withValues(alpha: opacity),
                        ),
                      ),
                      if (int.tryParse(formattedDate[0]) == null)
                        Text(
                          DateFormat("${formattedDate == "aujourd'hui" || formattedDate == "hier" ? "EEEE " : ""}d MMMM", "fr_CH").format(date),
                          style: TextStyle(fontSize: 18, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ClipPath(
                      clipper: _VerticalClipper(),
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.only(top: 6, bottom: 20),
                        clipBehavior: Clip.none,
                        itemCount: thisDaysAssignment.length + 1,
                        itemBuilder: (context, i) {
                          if (i < thisDaysAssignment.length) {
                            final assignment = thisDaysAssignment[i];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AssignmentCard(
                                assignment: assignment,
                                controller: assignmentCardControllers.putIfAbsent(assignment.key as int, () => AssignmentCardController()),
                                onEditButtonClicked: () => showNewAssignmentPopup(toEdit: assignment),
                                onDeleteButtonClicked: () => deleteAssignment(assignment),
                                onMarkAsDoneButtonClicked: (isMarkedAsDone) {
                                  bool isAllDone = true;

                                  for (var assignment
                                      in assignmentByDate.entries.where((entry) => entry.key.isSameDayAs(date)).expand((entry) => entry.value).toList()) {
                                    if (!assignment.isTest && !assignment.isMarkedAsDone) isAllDone = false;
                                  }

                                  if (isAllDone) {
                                    Confetti.launch(context, options: const ConfettiOptions(particleCount: 100, spread: 70, y: 0.6));
                                    HapticFeedback.heavyImpact();
                                  }
                                },
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () => showNewAssignmentPopup(dueDateOverride: date),
                            behavior: HitTestBehavior.opaque,
                            child: DottedBorder(
                              options: RoundedRectDottedBorderOptions(
                                color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                                strokeWidth: 2,
                                dashPattern: [4, 5],
                                radius: Radius.circular(8),
                                strokeCap: StrokeCap.round,
                                borderPadding: EdgeInsets.all(2),
                              ),
                              child: SizedBox(
                                height: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text("Ajouter un devoir", style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context))),
                                    HugeIcon(icon: HugeIcons.strokeRoundedAdd01, strokeWidth: 1, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
    }
  }

  Widget buildFilterButton(AssignmentViewMode viewMode, List<List> icon, String text) {
    final isSelected = currentViewMode == viewMode;

    return CupertinoPressable(
      onTap: () => setState(() => currentViewMode = isSelected ? AssignmentViewMode.byDefault : viewMode),
      decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Opacity(
        opacity: isSelected ? 1 : 0.5,
        child: Row(
          spacing: 6,
          children: [
            isSelected
                ? HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 16, color: CupertinoColors.destructiveRed.resolveFrom(context))
                : HugeIcon(icon: icon, size: 16, color: CupertinoColors.label.resolveFrom(context)),
            Text(text),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    allAssignment = Hive.box<Assignment>("Assignment");
    allGrades = Hive.box<Grade>("Grades");
    timelineController = PageController(initialPage: tomorrowPageIndex, viewportFraction: 0.95);

   globals.getTargetCalendar().then((retreivedCalendar) => targetCalendar = retreivedCalendar);

    groupAssignmentByDate();
    allAssignment.listenable().addListener(groupAssignmentByDate);

    timelineController.addListener(() {
      if (isAnimating) return;
      if (currentViewingTestIndex != -1) {
        setState(() => currentViewingTestIndex = -1);
      }
    });

    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus && currentViewMode == AssignmentViewMode.searchMode) {
        setState(() => currentViewMode = AssignmentViewMode.byDefault);
      }
      searchFocusNode.addListener(() => setState(() {}));
    });
  }

  @override
  void dispose() {
    timelineController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double goalHeight = currentViewMode != AssignmentViewMode.searchMode ? 80 : 40;

    return GestureDetector(
      onTap: () => searchFocusNode.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder:
                  (context, innerBoxIsScrolled) => [
                    CupertinoSliverNavigationBar(
                      largeTitle: Text("Devoirs"),
                      bottomMode: NavigationBarBottomMode.automatic,
                      bottom: PreferredSize(
                        preferredSize: Size.fromHeight(goalHeight),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints.tightFor(height: goalHeight),
                            child: Padding(
                              padding: EdgeInsetsGeometry.symmetric(horizontal: 14),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 10,
                                children: [
                                  CupertinoSearchTextField(
                                    controller: searchController,
                                    onChanged: (value) => setState(() {}),
                                    onTap:
                                        () => setState(() {
                                          currentViewMode = AssignmentViewMode.searchMode;
                                          searchFocusNode.requestFocus();
                                        }),
                                    focusNode: searchFocusNode,
                                    placeholder: "Rechercher des devoirs",
                                  ),

                                  if (currentViewMode != AssignmentViewMode.searchMode)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: BouncingScrollPhysics(),
                                      child: Row(
                                        spacing: 6,
                                        children: [
                                          buildFilterButton(AssignmentViewMode.byDueDate, HugeIcons.strokeRoundedCalendarUpload01, "Par date de remise"),
                                          buildFilterButton(AssignmentViewMode.bySubject, HugeIcons.strokeRoundedCheckmarkBadge04, "Par branche"),
                                          buildFilterButton(AssignmentViewMode.testsFirst, HugeIcons.strokeRoundedTextCheck, "Les tests d'abord"),
                                          buildFilterButton(AssignmentViewMode.testsOnly, HugeIcons.strokeRoundedTextCheck, "Seulement les tests"),
                                          buildFilterButton(AssignmentViewMode.all, HugeIcons.strokeRoundedMenu01, "Tous"),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
              body: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (nearbyTests.isNotEmpty && !isNearbyTestsNotifierHidden && currentViewMode == AssignmentViewMode.byDefault) buildNearbyTestsNotifier(),
                    SizedBox(height: 6),
                    Expanded(child: buildAssignmentList()),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([timelineController, MainPage.pageIndex]),
              builder: (context, _) {
                final currentPage =
                    (timelineController.hasClients ? timelineController.page ?? timelineController.initialPage : timelineController.initialPage).round();
                final dayDistance = currentPage - tomorrowPageIndex;
                final isAtTomorrow = dayDistance.abs() < 0.1;
                final isAtThisPage = MainPage.pageIndex.value == 1;

                return Positioned(
                  bottom: MediaQuery.paddingOf(context).bottom + 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: isAtThisPage ? 1 : 0,
                    duration: Duration(milliseconds: isAtThisPage ? 300 : 100),

                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedScale(
                          scale: isAtTomorrow ? 0 : 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: isAtTomorrow ? 0 : 1,
                            duration: const Duration(milliseconds: 100),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CupertinoPressable(
                                onTap:
                                    isAtTomorrow
                                        ? null
                                        : () => setState(() {
                                          currentViewingTestIndex = -1;
                                          animateToPage(tomorrowPageIndex);
                                        }),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: CupertinoColors.black.withAlpha(30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
                                  ],
                                ),
                                child: HugeIcon(
                                  icon: dayDistance > 0 ? HugeIcons.strokeRoundedCalendarCheckIn01 : HugeIcons.strokeRoundedCalendarCheckOut01,
                                  color: CupertinoColors.label.resolveFrom(context),
                                ),
                              ),
                            ),
                          ),
                        ),

                        CupertinoPressable(
                          onTap: showNewAssignmentPopup,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: CupertinoColors.black.withAlpha(30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))],
                          ),
                          child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: CupertinoColors.label.resolveFrom(context)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum AssignmentViewMode { byDefault, byDueDate, bySubject, testsFirst, testsOnly, all, searchMode }

class _VerticalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()..addRect(Rect.fromLTWH(-10, 0, size.width + 20, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
