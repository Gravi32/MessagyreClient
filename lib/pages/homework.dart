import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/pages/homework_subpages/new_homework.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/cupertino_pressable.dart';
import 'package:messagyre_client/utility/widgets/homework_card.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final router = ConnectionController();
  final data = Data();

  late final PageController timelineController;
  late final Box<Homework> allHomework;

  late Map<DateTime, List<Homework>> homeworkByDate;

  List<DateTime> get allDays {
    final rawList = List<DateTime>.generate(data.schoolEnd.difference(data.schoolStart).inDays, (i) => data.schoolStart.add(Duration(days: i)));

    return data.settings.includeWeekends ? rawList : rawList.where((d) => d.weekday != DateTime.saturday && d.weekday != DateTime.sunday).toList();
  }

  int get tomorrowPageIndex {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return allDays.indexWhere((d) => d.year == tomorrow.year && d.month == tomorrow.month && d.day == tomorrow.day);
  }

  @override
  void initState() {
    super.initState();
    allHomework = Hive.box<Homework>("Homework");
    timelineController = PageController(initialPage: tomorrowPageIndex, viewportFraction: 0.95);

    _groupHomeworkByDate();
    allHomework.listenable().addListener(_groupHomeworkByDate);
  }

  void _groupHomeworkByDate() {
    final grouped = <DateTime, List<Homework>>{};
    for (var hw in allHomework.values) {
      final day = DateTime(hw.dueDate.year, hw.dueDate.month, hw.dueDate.day);
      grouped.putIfAbsent(day, () => []).add(hw);
    }
    for (var list in grouped.values) {
      list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    }
    setState(() {
      homeworkByDate = grouped;
    });
  }

  void showNewHomeworkPopup({Homework? toEdit, DateTime? dueDateOverride}) async {
    final newHomework = await showCupertinoModalBottomSheet<Homework?>(
      expand: false,
      enableDrag: false,
      clipBehavior: Clip.none,
      backgroundColor: CupertinoColors.transparent,
      context: context,
      builder: (context) => NewHomework(toEdit: toEdit, dueDateOverride: dueDateOverride),
    );

    if (newHomework == null) return;

    if (toEdit != null) toEdit.delete();
    allHomework.add(newHomework);
  }

  @override
  void dispose() {
    timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [CupertinoSliverNavigationBar(largeTitle: Text("Devoirs"))],
            body: SafeArea(
              top: false,
              child: SizedBox(
                child: PageView.builder(
                  controller: timelineController,
                  itemCount: allDays.length,
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: PageScrollPhysics(),
                  itemBuilder: (context, index) {
                    final date = allDays[index];
                    final isPassed = date.isBefore(now);
                    final opacity = isPassed ? 0.5 : 1.0;

                    final thisDaysHomework = homeworkByDate[DateTime(date.year, date.month, date.day)] ?? [];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "Pour ${formatDate(date, includeArticle: true)}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity),
                                ),
                              ),
                              // Text(
                              //   DateFormat(", d MMMM", "fr_CH").format(date),
                              //   style: TextStyle(fontSize: 22, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                              // ),
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
                                      onEditButtonClicked: () => showNewHomeworkPopup(toEdit: homework),
                                      onDeleteButtonClicked:
                                          () => showCupertinoDialog(
                                            context: context,
                                            builder:
                                                (dialogContext) => CupertinoAlertDialog(
                                                  title: Text("Supprimer le devoir"),
                                                  content: Text("Le devoir sera supprimé. Cette action est irréversible."),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                      onPressed: () => Navigator.pop(dialogContext),
                                                      child: Text(
                                                        "Annuler",
                                                        style: TextStyle(color: CupertinoTheme.of(context).primaryColor.withBrightness(.2)),
                                                      ),
                                                    ),
                                                    CupertinoDialogAction(
                                                      onPressed: () {
                                                        homework.delete();
                                                        Navigator.pop(dialogContext);
                                                      },
                                                      child: Text("Supprimer", style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context))),
                                                    ),
                                                  ],
                                                ),
                                          ),
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
                                      child: Center(
                                        child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedAdd01,
                                          color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
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
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: timelineController,
            builder: (context, _) {
              final currentPage =
                  (timelineController.hasClients ? timelineController.page ?? timelineController.initialPage : timelineController.initialPage).round();
              final dayDistance = currentPage - tomorrowPageIndex;
              final isAtTomorrow = dayDistance.abs() < 0.1;

              return Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 20,
                right: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoPressable(
                      onTap: () => timelineController.animateToPage(tomorrowPageIndex, duration: Duration(milliseconds: 300), curve: Curves.easeOutExpo),

                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.secondarySystemBackground.resolveFrom(context).withOpacity(isAtTomorrow ? 0 : 1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: CupertinoColors.black.withAlpha(isAtTomorrow ? 0 : 30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5)),
                        ],
                      ),
                      child:
                          isAtTomorrow
                              ? SizedBox.shrink()
                              : HugeIcon(
                                icon: dayDistance > 0 ? HugeIcons.strokeRoundedCalendarCheckIn01 : HugeIcons.strokeRoundedCalendarCheckOut01,
                                color: CupertinoColors.label.resolveFrom(context),
                              ),
                    ),
                    SizedBox(height: 10),
                    CupertinoPressable(
                      onTap: showNewHomeworkPopup,

                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: CupertinoColors.black.withAlpha(30), blurRadius: 10, spreadRadius: 2, offset: const Offset(0, 5))],
                      ),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: CupertinoColors.label.resolveFrom(context)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
