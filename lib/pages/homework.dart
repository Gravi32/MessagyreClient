import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/pages/homework_subpages/new_homework.dart';
import 'package:messagyre_client/pages/homework_subpages/view_homework.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
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

  final timelineController = PageController(initialPage: DateTime.now().difference(Data().schoolStart).inDays + 1, viewportFraction: 0.95);

  late Box<Homework> allHomework;

  int get tomorrowPageIndex => DateTime.now().difference(data.schoolStart).inDays + 1;

  void showNewHomeworkPopup({Homework? toEdit, DateTime? dueDateOverride}) async {
    final newHomework = await showCupertinoModalBottomSheet<Homework?>(
      expand: false,
      enableDrag: false,
      clipBehavior: Clip.none,
      backgroundColor: CupertinoColors.transparent,
      context: context,
      builder: (context) => NewHomework(toEdit: toEdit, dueDateOverride: dueDateOverride,),
    );

    if (newHomework == null) return;

    if (toEdit != null) toEdit.delete();

    allHomework.add(newHomework);
  }

  void showViewHomeworkPopup(Homework homework) async {
    final action = await showCupertinoModalBottomSheet<int?>(context: context, builder: (context) => ViewHomework(homework: homework));

    if (action == 1) {
      showNewHomeworkPopup(toEdit: homework);
    } else if (action == 2) {
      homework.delete();
    }
  }

  @override
  void initState() {
    super.initState();
    allHomework = Hive.box<Homework>("Homework");

    timelineController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeworkList = allHomework.values.toList();
    homeworkList.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    final now = DateTime.now();
    final days = data.schoolEnd.difference(data.schoolStart).inDays;
    int currentPage = timelineController.initialPage;
    try {
      // Accessing timelineController.page throws an error if the PageView hasn't been built yet
      currentPage = (timelineController.page ?? timelineController.initialPage).round();
    } catch (_) {}

    final isAtTomorrow = (currentPage - tomorrowPageIndex).abs() < 0.1;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [CupertinoSliverNavigationBar(largeTitle: Text("Devoirs"))];
            },
            body: SafeArea(
              top: false,
              child: SizedBox(
                height: 120,
                child: ValueListenableBuilder(
                  valueListenable: allHomework.listenable(),
                  builder: (context, currentAllHomework, _) {
                    return PageView.builder(
                      controller: timelineController,
                      itemCount: days,
                      scrollDirection: Axis.horizontal,
                      physics: PageScrollPhysics(),
                      itemBuilder: (context, index) {
                        final date = data.schoolStart.add(Duration(days: index));
                        final isPassed = date.isBefore(now);
                        final opacity = isPassed ? 0.5 : 1.0;
                        final formattedDate = formatDate(date);

                        final thisDaysHomework =
                            currentAllHomework.values
                                .where(
                                  (savedHomework) =>
                                      savedHomework.dueDate.year == date.year &&
                                      savedHomework.dueDate.month == date.month &&
                                      savedHomework.dueDate.day == date.day,
                                )
                                .toList();

                        return Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 6,
                            children: [
                              Text(
                                "Pour${(int.tryParse(formattedDate[0]) == null) ? "" : " le"} $formattedDate",
                                style: TextStyle(
                                  fontSize: 22,
                                  color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ...thisDaysHomework.map(
                                      (homework) =>
                                          Padding(padding: EdgeInsets.only(bottom: 12), child: HomeworkCard(homework: homework, onTap: showNewHomeworkPopup)),
                                    ),
                                    GestureDetector(
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
                                          child: Center(child: Icon(CupertinoIcons.add, color: CupertinoColors.secondarySystemBackground.resolveFrom(context))),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            right: 20,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 10,
              children: [
                if (!isAtTomorrow)
                  GestureDetector(
                    onTap:
                        () => timelineController.animateToPage(
                          DateTime.now().difference(data.schoolStart).inDays + 1,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(20)),
                      child: Icon(CupertinoIcons.calendar_today, color: CupertinoColors.label.resolveFrom(context)),
                    ),
                  ),
                GestureDetector(
                  onTap: showNewHomeworkPopup,
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(color: CupertinoColors.secondarySystemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(20)),
                    child: Icon(CupertinoIcons.add, color: CupertinoColors.label.resolveFrom(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
