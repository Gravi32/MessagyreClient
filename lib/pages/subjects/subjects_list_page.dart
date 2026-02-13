import 'package:flutter/cupertino.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/pages/subjects/subpages/subject_edit_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectsListPage extends StatefulWidget {
  const SubjectsListPage({super.key});

  @override
  State<StatefulWidget> createState() => _SubjectsListPageState();
}

class _SubjectsListPageState extends State<SubjectsListPage> with WidgetsBindingObserver {
  final database = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text("Branches")),
      child: SafeArea(
        child: StreamBuilder(
          stream: database.subjects.watchAll(),
          builder: (context, _) {
            final allSubjects = database.subjects.getAll();

            return ListView(
              padding: EdgeInsets.only(bottom: 20),
              physics: const ClampingScrollPhysics(),
              children: [
                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.transparent,
                  header: Text("Branches"),
                  children: [
                    ...allSubjects.map(
                      (subject) => CupertinoListTile.notched(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        padding: EdgeInsets.all(10),
                        title: Row(
                          spacing: 16,
                          children: [SubjectBadge(subject: subject), Text(subject.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))],
                        ),
                        onTap: () => Navigator.push(context, CupertinoSheetRoute(builder: (context) => NewSubjectPage(toEdit: subject))),
                      ),
                    ),
                  ],

                  // CupertinoListSection.insetGrouped(
                  //   margin: EdgeInsets.symmetric(horizontal: 10),
                  //   backgroundColor: AppColors.transparent,
                  //   header: Text("Branches composées"),
                  //   children: [
                  //     ...allSubjects.map(
                  //       (subject) => CupertinoListTile(
                  //         backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  //         leading: SizedBox(
                  //           width: 28,
                  //           height: 28,
                  //           child: Container(
                  //             decoration: BoxDecoration(
                  //               color: subject.color.withBrightness(-.15),
                  //               border: Border.all(color: AppColors.tertiaryBackground.adaptTo(context)),
                  //               borderRadius: BorderRadius.circular(10),
                  //             ),
                  //             child: Center(child: Icon(subject.icon, color: subject.color, size: 18)),
                  //           ),
                  //         ),
                  //         title: Text(subject.name),
                  //       ),
                  //     ),

                  //     CupertinoListTile(
                  //       backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                  //       leading: HugeIcon(icon: HugeIcons.strokeRoundedAdd01),
                  //       title: Text("Ajouter"),
                  //     ),
                  //   ],
                  // ),
                ),

                CupertinoListSection.insetGrouped(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.transparent,
                  header: const SizedBox.shrink(),
                  children: [
                    CupertinoListTile(
                      backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                      leading: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: AppColors.secondaryText.adaptTo(context)),
                      title: Text("Ajouter", style: TextStyle(color: AppColors.secondaryText.adaptTo(context))),
                      onTap: () => Navigator.push(context, CupertinoSheetRoute(builder: (context) => NewSubjectPage())),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> askUserToAddTheirSubjects(BuildContext context) async {
  final database = DatabaseService();

  if (database.subjects.getAll().length > 5) return;
  if (!context.mounted) return;

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => SubjectsListPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: true,
          child: child,
        );
      },
    ),
  );
}
