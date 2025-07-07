import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/pages/homework_subpages/new_homework.dart';
import 'package:messagyre_client/pages/homework_subpages/view_homework.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final router = ConnectionController();
  final data = Data();

  late Box<Homework> allHomework;

  void showNewHomeworkPopup({Homework? toEdit}) async {
    final newHomework = await showCupertinoSheet<Homework?>(
      context: context,
      pageBuilder: (context) => NewHomework(toEdit: toEdit),
    );

    if (newHomework == null) return;

    if (toEdit != null) toEdit.delete();

    allHomework.add(newHomework);
  }

  void showViewHomeworkPopup(Homework homework) async {
    final action = await showCupertinoSheet<int>(
      context: context,
      pageBuilder: (context) => ViewHomework(homework: homework),
    );

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
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                CupertinoSliverNavigationBar(largeTitle: Text("Devoirs")),
              ];
            },
            body: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder(
                  valueListenable: allHomework.listenable(),
                  builder: (context, Box<Homework> box, _) {
                    // Deleting old homework
                    for (int key in box.keys) {
                      if (box.containsKey(key) &&
                          (box.get(key)!.dueDate.isBefore(DateTime.now()) ||
                              box
                                  .get(key)!
                                  .creationDate
                                  .isAfter(DateTime.now()))) {
                        box.delete(key);
                      }
                    }

                    // Page Content

                    final homeworkList = box.values.toList();
                    homeworkList.sort((a, b) => b.dueDate.compareTo(a.dueDate));

                    return homeworkList.isEmpty
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 40,
                              color: CupertinoColors.separator.resolveFrom(
                                context,
                              ),
                            ),
                            Text(
                              "Pas de devoirs !",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          padding: EdgeInsets.only(top: 8),
                          itemCount: homeworkList.length,
                          itemBuilder: (context, index) {
                            final homework = homeworkList[index];
                            final previousHomework =
                                index > 0 ? homeworkList[index - 1] : null;

                            final isOnSameDay =
                                previousHomework != null &&
                                homework.dueDate.year ==
                                    previousHomework.dueDate.year &&
                                homework.dueDate.month ==
                                    previousHomework.dueDate.month &&
                                homework.dueDate.day ==
                                    previousHomework.dueDate.day;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!isOnSameDay) ...[
                                  Row(
                                    children: [
                                      Text(
                                        "Pour ${formatDate(homework.dueDate)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        DateFormat(
                                          "d MMMM y",
                                          'fr_CH',
                                        ).format(homework.dueDate),
                                        style: TextStyle(
                                          color: CupertinoColors.inactiveGray
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                ],

                                GestureDetector(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: adaptiveColor(
                                        context,
                                        CupertinoColors.systemGroupedBackground
                                            .resolveFrom(context),
                                        CupertinoColors
                                            .secondarySystemGroupedBackground
                                            .resolveFrom(context),
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                SubjectHelper.toFrench(
                                                  homework.subject,
                                                ),
                                                style: TextStyle(
                                                  color:
                                                      CupertinoTheme.of(
                                                        context,
                                                      ).primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              if (homework.isGraded)
                                                Icon(CupertinoIcons.chart_bar),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            homework.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 18,
                                            ),
                                          ),
                                          if (homework.description != null &&
                                              homework.description!.isNotEmpty)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                top: 16,
                                                bottom: 28,
                                              ),
                                              child: Text(
                                                homework.description!,
                                              ),
                                            ),

                                          Text(
                                            "Ajouté ${formatDate(homework.creationDate)}",
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                              color: CupertinoColors
                                                  .inactiveGray
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  onTap: () => showViewHomeworkPopup(homework),
                                ),

                                SizedBox(height: 16),
                              ],
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
            child: CupertinoButton.tinted(
              onPressed: showNewHomeworkPopup,
              sizeStyle: CupertinoButtonSize.medium,
              child: Row(
                spacing: 8,
                children: [Icon(CupertinoIcons.add), Text("Ajouter un devoir")],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
