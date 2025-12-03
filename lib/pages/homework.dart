import 'dart:math';

import 'package:device_calendar/device_calendar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/homework_subpages/new_homework.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/homework_card.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final router = ConnectionController();
  final data = Data();
  final calendar = DeviceCalendarPlugin();

  late final PageController timelineController;
  late final Box<Homework> allHomework;

  HomeworkViewMode currentViewMode = HomeworkViewMode.byDefault;

  late Map<DateTime, List<Homework>> homeworkByDate;
  final Map<int, HomeworkCardController> homeworkCardControllers = {};
  final FocusNode searchFocusNode = FocusNode();
  final TextEditingController searchController = TextEditingController();

  Calendar? targetCalendar;
  List<Homework> nearbyTests = [];
  bool isNearbyTestsNotifierHidden = false;
  int currentViewingTestIndex = -1;
  bool isAnimating = false;

  List<DateTime> get allDays {
    final rawList = List<DateTime>.generate(data.schoolEnd.difference(data.schoolStart).inDays, (i) => data.schoolStart.add(Duration(days: i)));

    return data.settings.includeWeekends ? rawList : rawList.where((d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday).toList();
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

  @override
  void initState() {
    super.initState();
    allHomework = Hive.box<Homework>("Homework");
    timelineController = PageController(initialPage: tomorrowPageIndex, viewportFraction: 0.95);

    data.getTargetCalendar().then((retreivedCalendar) => targetCalendar = retreivedCalendar);

    groupHomeworkByDate();
    allHomework.listenable().addListener(groupHomeworkByDate);

    timelineController.addListener(() {
      if (isAnimating) return;
      if (currentViewingTestIndex != -1) {
        setState(() => currentViewingTestIndex = -1);
      }
    });

    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus && currentViewMode == HomeworkViewMode.searchMode) {
        setState(() => currentViewMode = HomeworkViewMode.byDefault);
      }
      searchFocusNode.addListener(() => setState(() {}));
    });
  }

  Future<void> animateToPage(int pageIndex) async {
    isAnimating = true;
    await timelineController.animateToPage(pageIndex, duration: const Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
    isAnimating = false;
    return;
  }

  void groupHomeworkByDate() {
    final grouped = <DateTime, List<Homework>>{};
    nearbyTests.clear();

    for (var hw in allHomework.values) {
      final daysLeft = hw.dueDate.difference(DateTime.now()).inDays;

      if (hw.isTest && daysLeft >= 0 && daysLeft < 7) nearbyTests.add(hw);
      grouped.putIfAbsent(hw.dueDate, () => []).add(hw);
    }

    for (var list in grouped.values) {
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    }
    setState(() {
      homeworkByDate = grouped;
    });
  }

  void showNewHomeworkPopup({Homework? toEdit, DateTime? dueDateOverride}) async {
    final result = await showCupertinoModalBottomSheet(
      expand: false,
      enableDrag: false,
      previousRouteAnimationCurve: Curves.ease,
      clipBehavior: Clip.none,
      backgroundColor: CupertinoColors.transparent,
      context: context,
      builder: (context) => NewHomework(toEdit: toEdit, dueDateOverride: dueDateOverride),
    );

    final homework = result.homework;

    if (homework == null) return;

    if (toEdit != null) toEdit.delete();

    allHomework.add(homework);

    if (result.editsCalendar) {
      final permissionResult = await calendar.hasPermissions();
      if (!permissionResult.isSuccess || permissionResult.data != true) {
        final requestResult = await calendar.requestPermissions();
        if (!requestResult.isSuccess || requestResult.data != true) return;
      }

      if (targetCalendar == null) return;

      String title = "Devoir ${SubjectHelper.withPreposition(homework.subject)}";
      if (homework.isGraded) {
        title = "Devoir noté ${SubjectHelper.withPreposition(homework.subject)}";
      } else if (homework.isTest) {
        title = "Test ${SubjectHelper.withPreposition(homework.subject)}";
      }

      final timeZone = getLocation("Europe/Zurich");

      final event = Event(
        targetCalendar!.id,
        eventId: homework.calendarEventId,
        title: title,
        start: TZDateTime.from(homework.dueDate, timeZone),
        end: TZDateTime.from(homework.dueDate.add(const Duration(minutes: 45)), timeZone),
        allDay: true,
        description: "${(homework.content?.isEmpty ?? true) ? "" : "${homework.content}\n\n"}Créé par Messagyre.",
      );

      final result = await calendar.createOrUpdateEvent(event);
      homework.calendarEventId = result?.data ?? homework.calendarEventId;
      homework.save();
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
      await animateToPage(allDays.indexWhere((date) => date.isSameDayAs(targetTest.dueDate)));

      homeworkCardControllers[targetTest.key as int]?.triggerBounceEffect();
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
                color: CupertinoColors.systemGrey.resolveFrom(context).withOpacity(0.15),
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
                        CupertinoColors.secondarySystemBackground.resolveFrom(context).withBrightness(data.appBrightness == Brightness.dark ? .1 : .02),
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
                        right: -5,
                        child: Transform.rotate(
                          angle: pi / 40,
                          child: Opacity(opacity: .6, child: Image.asset("assets/warningSign.png", width: 100, height: 120)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.all(6).add(EdgeInsets.only(bottom: 30)),
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
                            nearbyTests.length > 1
                                ? Padding(
                                  padding: EdgeInsetsGeometry.symmetric(vertical: 6),
                                  child: Column(
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
                                  ),
                                )
                                : Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  spacing: 4,
                                  children: [
                                    Opacity(
                                      opacity: .6,
                                      child: HugeIcon(
                                        icon: HugeIcons.strokeRoundedCalendar04,
                                        color: CupertinoColors.secondaryLabel.resolveFrom(context).withAlpha(160),
                                        size: 16,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('d MMMM', 'fr_CH').format(nearbyTests.first.dueDate),
                                      style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context).withAlpha(160)),
                                    ),
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
          top: 0,
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
        Positioned(
          bottom: 16,
          left: 20,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: CupertinoColors.secondarySystemBackground.resolveFrom(context)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 4,
                children: [
                  Opacity(
                    opacity: .6,
                    child: HugeIcon(icon: HugeIcons.strokeRoundedSearch01, color: CupertinoColors.secondaryLabel.resolveFrom(context).withAlpha(160), size: 16),
                  ),
                  Text("Appuyez pour voir", style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context).withAlpha(160))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildHomeworkList() {
    final now = DateTime.now();

    void deleteHomework(Homework target) {
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
      case HomeworkViewMode.byDueDate:
        final sortedHomework = allHomework.values.toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedHomework.length,
          itemBuilder: (context, index) {
            final date = sortedHomework[index].dueDate;
            final formattedDate = formatDate(date);
            final opacity = date.isBefore(now) ? 0.5 : 1.0;
            final homework = sortedHomework[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index == 0 || !sortedHomework[index - 1].dueDate.isSameDayAs(date)) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 6,
                    children: [
                      Text(
                        "Pour ${formatDate(date, includeArticle: true)}",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity)),
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
                    child: HomeworkCard(
                      homework: homework,
                      controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                      onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                      onDeleteButtonClicked: () => deleteHomework(homework),
                      onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => homework.isMarkedAsDone = isMarkedAsDone),
                    ),
                  ),
                ),
              ],
            );
          },
        );

      case HomeworkViewMode.bySubject:
        final homeworkListBySubject = <Subject, List<Homework>>{};

        for (var hw in allHomework.values) {
          homeworkListBySubject.putIfAbsent(hw.subject, () => []).add(hw);
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: SubjectHelper.sortedSubjects.length,
          itemBuilder: (context, index) {
            final subject = SubjectHelper.sortedSubjects[index];
            final subjectHomework = homeworkListBySubject[subject];

            return subjectHomework == null
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
                          "${subjectHomework.length} ${subjectHomework.length == 1 ? "Devoir" : "Devoirs"}",
                          style: TextStyle(fontSize: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ...subjectHomework.map(
                      (homework) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: homework.dueDate.isBefore(now) ? 0.5 : 1.0,
                          child: HomeworkCard(
                            homework: homework,
                            controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                            onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                            onDeleteButtonClicked: () => deleteHomework(homework),
                            onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => homework.isMarkedAsDone = isMarkedAsDone),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                );
          },
        );

      case HomeworkViewMode.testsFirst:
        final sortedHomework =
            allHomework.values.toList()
              ..sort((a, b) => b.dueDate.compareTo(a.dueDate))
              ..sort((a, b) {
                if (a.isTest && !b.isTest) return -1;
                if (!a.isTest && b.isTest) return 1;
                return 0;
              });

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedHomework.length,
          itemBuilder: (context, index) {
            final date = sortedHomework[index].dueDate;
            final formattedDate = formatDate(date);
            final opacity = date.isBefore(now) ? 0.5 : 1.0;
            final homework = sortedHomework[index];

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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity)),
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
                    child: HomeworkCard(
                      homework: homework,
                      controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                      onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                      onDeleteButtonClicked: () => deleteHomework(homework),
                      onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => homework.isMarkedAsDone = isMarkedAsDone),
                    ),
                  ),
                ),
              ],
            );
          },
        );

      case HomeworkViewMode.testsOnly:
        final sortedHomework = allHomework.values.where((hw) => hw.isTest).toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedHomework.length,
          itemBuilder: (context, index) {
            final date = sortedHomework[index].dueDate;
            final formattedDate = formatDate(date);
            final opacity = date.isBefore(now) ? 0.5 : 1.0;
            final homework = sortedHomework[index];

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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity)),
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
                    child: HomeworkCard(
                      homework: homework,
                      controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                      onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                      onDeleteButtonClicked: () => deleteHomework(homework),
                      onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => homework.isMarkedAsDone = isMarkedAsDone),
                    ),
                  ),
                ),
              ],
            );
          },
        );

      case HomeworkViewMode.all:
        final sortedHomework = allHomework.values.toList()..sort((a, b) => b.dueDate.compareTo(a.dueDate));

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: sortedHomework.length,
          itemBuilder: (context, index) {
            final homework = sortedHomework[index];
            final opacity = homework.dueDate.isBefore(now) ? 0.5 : 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: opacity,
                child: HomeworkCard(
                  homework: homework,
                  controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                  onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                  onDeleteButtonClicked: () => deleteHomework(homework),
                  onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => homework.isMarkedAsDone = isMarkedAsDone),
                ),
              ),
            );
          },
        );

      case HomeworkViewMode.searchMode:
        final query = searchController.text.trim().toLowerCase();
        final sortedHomework =
            query.isEmpty ? [] : SubjectHelper.searchBySimilarity(query, allHomework.toMap().map((key, value) => MapEntry(value.subject, value)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                sortedHomework.isEmpty
                    ? "Recherchéz un devoir..."
                    : "${sortedHomework.length} ${sortedHomework.length == 1 ? "Résultat" : "Résultats"} ${query.isEmpty ? "" : "pour '$query'"}",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                itemCount: sortedHomework.length,
                itemBuilder: (context, index) {
                  final date = sortedHomework[index].dueDate;
                  final homework = sortedHomework[index];

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
                        child: HomeworkCard(
                          homework: homework,
                          controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                          onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                          onDeleteButtonClicked: () => deleteHomework(homework),
                          onMarkAsDoneButtonClicked: (isMarkedAsDone) => setState(() => homework.isMarkedAsDone = isMarkedAsDone),
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

            final thisDaysHomework = homeworkByDate[date] ?? [];
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity)),
                      ),
                      if (int.tryParse(formattedDate[0]) == null)
                        Text(
                          DateFormat("${formattedDate == "aujourd'hui" || formattedDate == "hier" ? "EEEE " : ""}d MMMM", "fr_CH").format(date),
                          style: TextStyle(fontSize: 18, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: 6, bottom: 20),
                      clipBehavior: Clip.none,
                      itemCount: thisDaysHomework.length + 1,
                      itemBuilder: (context, i) {
                        if (i < thisDaysHomework.length) {
                          final homework = thisDaysHomework[i];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: HomeworkCard(
                              homework: homework,
                              controller: homeworkCardControllers.putIfAbsent(homework.key as int, () => HomeworkCardController()),
                              onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                              onDeleteButtonClicked: () => deleteHomework(homework),
                              onMarkAsDoneButtonClicked: (isMarkedAsDone) {
                                bool isAllDone = true;

                                for (var homework
                                    in homeworkByDate.entries.where((entry) => entry.key.isSameDayAs(date)).expand((entry) => entry.value).toList()) {
                                  if (!homework.isTest && !homework.isMarkedAsDone) isAllDone = false;
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
                          onTap: () => showNewHomeworkPopup(dueDateOverride: date),
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
                              child: Opacity(
                                opacity: .2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text("Ajouter un devoir", style: TextStyle(fontSize: 16, color: CupertinoColors.label.resolveFrom(context))),
                                    HugeIcon(icon: HugeIcons.strokeRoundedAdd01, strokeWidth: 1, color: CupertinoColors.label.resolveFrom(context)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
    }
  }

  Widget buildFilterButton(HomeworkViewMode viewMode, List<List> icon, String text) {
    final isSelected = currentViewMode == viewMode;

    return CupertinoPressable(
      onTap: () => setState(() => currentViewMode = isSelected ? HomeworkViewMode.byDefault : viewMode),
      decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(12)),
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
  void dispose() {
    timelineController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double goalHeight = currentViewMode != HomeworkViewMode.searchMode ? 80 : 40;

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
                                          currentViewMode = HomeworkViewMode.searchMode;
                                          searchFocusNode.requestFocus();
                                        }),
                                    focusNode: searchFocusNode,
                                    placeholder: "Rechercher des devoirs",
                                  ),

                                  if (currentViewMode != HomeworkViewMode.searchMode)
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: BouncingScrollPhysics(),
                                      child: Row(
                                        spacing: 6,
                                        children: [
                                          buildFilterButton(HomeworkViewMode.byDueDate, HugeIcons.strokeRoundedCalendarUpload01, "Par date de remise"),
                                          buildFilterButton(HomeworkViewMode.bySubject, HugeIcons.strokeRoundedCheckmarkBadge04, "Par branche"),
                                          buildFilterButton(HomeworkViewMode.testsFirst, HugeIcons.strokeRoundedTextCheck, "Les tests d'abord"),
                                          buildFilterButton(HomeworkViewMode.testsOnly, HugeIcons.strokeRoundedTextCheck, "Seulement les tests"),
                                          buildFilterButton(HomeworkViewMode.all, HugeIcons.strokeRoundedMenu01, "Tous"),
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
                    if (nearbyTests.isNotEmpty && !isNearbyTestsNotifierHidden) buildNearbyTestsNotifier(),
                    SizedBox(height: 6),
                    Expanded(child: buildHomeworkList()),
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
                          onTap: showNewHomeworkPopup,
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

enum HomeworkViewMode { byDefault, byDueDate, bySubject, testsFirst, testsOnly, all, searchMode }
