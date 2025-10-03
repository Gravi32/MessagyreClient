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

  void showNewHomeworkPopup({Homework? toEdit}) async {
    final newHomework = await showCupertinoModalBottomSheet<Homework?>(
      expand: false,
      enableDrag: false,
      clipBehavior: Clip.none,
      backgroundColor: CupertinoColors.transparent,
      context: context,
      builder: (context) => NewHomework(toEdit: toEdit),
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
                                      onTap: showNewHomeworkPopup,
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

                              // Container(
                              //   decoration: BoxDecoration(
                              //     color: CupertinoColors.secondarySystemBackground.resolveFrom(context),
                              //     borderRadius: BorderRadius.circular(12),
                              //   ),
                              //   padding: EdgeInsets.all(12),
                              //   child: Column(
                              //     children: [
                              //       Text(
                              //         "Pour ${formatDate(date)}",
                              //         style: TextStyle(
                              //           fontSize: 18,
                              //           color: CupertinoColors.label.resolveFrom(context).withOpacity(opacity),
                              //           fontWeight: FontWeight.w500,
                              //           decoration: isPassed ? TextDecoration.lineThrough : null,
                              //         ),
                              //       ),
                              //       SizedBox(height: 8),
                              //       Text("Ex 1,2,3 pag 94"),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // return Column(
              //   spacing: 20,
              //   children: [
              //     Expanded(child: CustomTimelineCalendar(onDateSelected: (value) => print(value))),

              //     homeworkList.isEmpty
              //         ? Column(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           spacing: 10,
              //           children: [
              //             Icon(CupertinoIcons.sparkles, size: 36, color: CupertinoColors.separator.resolveFrom(context)),
              //             Text(
              //               "Pas de devoirs !",
              //               style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: CupertinoColors.separator.resolveFrom(context)),
              //             ),
              //           ],
              //         )
              //         : ListView.builder(
              //           padding: EdgeInsets.only(top: 8),
              //           itemCount: homeworkList.length,
              //           itemBuilder: (context, index) {
              //             final homework = homeworkList[index];
              //             final previousHomework = index > 0 ? homeworkList[index - 1] : null;

              //             final isOnSameDay =
              //                 previousHomework != null &&
              //                 homework.dueDate.year == previousHomework.dueDate.year &&
              //                 homework.dueDate.month == previousHomework.dueDate.month &&
              //                 homework.dueDate.day == previousHomework.dueDate.day;

              //             return Column(
              //               crossAxisAlignment: CrossAxisAlignment.stretch,
              //               children: [
              //                 if (!isOnSameDay) ...[
              //                   Row(
              //                     children: [
              //                       Text("Pour ${formatDate(homework.dueDate)}", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
              //                       Spacer(),
              //                       Text(
              //                         DateFormat("d MMMM y", 'fr_CH').format(homework.dueDate),
              //                         style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context)),
              //                       ),
              //                     ],
              //                   ),
              //                   SizedBox(height: 12),
              //                 ],

              //                 GestureDetector(
              //                   child: Container(
              //                     decoration: BoxDecoration(
              //                       color: adaptiveColor(
              //                         context,
              //                         CupertinoColors.systemGroupedBackground.resolveFrom(context),
              //                         CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
              //                       ),
              //                       borderRadius: BorderRadius.all(Radius.circular(8)),
              //                     ),
              //                     child: Padding(
              //                       padding: EdgeInsets.all(12),
              //                       child: Column(
              //                         crossAxisAlignment: CrossAxisAlignment.stretch,
              //                         children: [
              //                           Row(
              //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //                             children: [
              //                               Text(
              //                                 SubjectHelper.toFrench(homework.subject),
              //                                 style: TextStyle(color: CupertinoTheme.of(context).primaryColor, fontWeight: FontWeight.w500, fontSize: 18),
              //                               ),
              //                               if (homework.isGraded) Icon(CupertinoIcons.chart_bar),
              //                             ],
              //                           ),
              //                           SizedBox(height: 5),
              //                           Text(homework.title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
              //                           if (homework.description != null && homework.description!.isNotEmpty)
              //                             Padding(padding: EdgeInsets.only(top: 16, bottom: 28), child: Text(homework.description!)),

              //                           Text(
              //                             "Ajouté ${formatDate(homework.creationDate)}",
              //                             textAlign: TextAlign.end,
              //                             style: TextStyle(color: CupertinoColors.inactiveGray.resolveFrom(context)),
              //                           ),
              //                         ],
              //                       ),
              //                     ),
              //                   ),

              //                   onTap: () => showViewHomeworkPopup(homework),
              //                 ),

              //                 SizedBox(height: 16),
              //               ],
              //             );
              //           },
              //         ),
              //   ],
              // );
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
