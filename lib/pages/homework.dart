import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/pages/homework_subpages/new_homework.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<StatefulWidget> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  final router = ConnectionController();
  final data = Data();

  late Box<Homework> allHomework;

  void showNewHomeworkPopup() async {
    final newHomework = await showCupertinoSheet<Homework?>(
      context: context,
      pageBuilder: (context) => NewHomework(),
    );

    if (newHomework == null) return;
    allHomework.add(newHomework);
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
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ValueListenableBuilder(
                  valueListenable: allHomework.listenable(),
                  builder: (context, Box<Homework> box, _) {
                    // Page Content

                    final homeworkList = box.values.toList();
                    homeworkList.sort((a, b) => b.dueDate.compareTo(a.dueDate));

                    return Column(
                      children: [
                        if (homeworkList.isNotEmpty)
                          Text(
                            "Vos devoirs pour ${DateFormat('EEEE', 'fr_FR').format(homeworkList.first.dueDate)}",
                          ),

                        ListView.builder(
                          padding: EdgeInsets.only(top: 8),
                          itemCount: homeworkList.length,
                          itemBuilder: (context, index) {
                            return Text(homeworkList[index].title);
                          },
                        ),
                      ],
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
                children: [Icon(CupertinoIcons.add), Text("Nouveau devoir")],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
