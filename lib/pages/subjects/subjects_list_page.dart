import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';

class SubjectsListPage extends StatefulWidget {
  final bool isBootstrap;

  const SubjectsListPage({super.key, this.isBootstrap = false});

  @override
  State<StatefulWidget> createState() => _SubjectsListPageState();
}

class _SubjectsListPageState extends State<SubjectsListPage> with WidgetsBindingObserver {
  final database = DatabaseService();

  void onSkipButtonPressed() {
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text("Êtes-vous sûr de vouloir passer ?"),
          content: const Text("Vous ne pourrez pas ajouter de notes et de devoirs pour les branches qui ne sont pas dans la liste."),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("Annuler"),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Passer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: widget.isBootstrap ? CupertinoButton(padding: EdgeInsets.zero, onPressed: onSkipButtonPressed, child: Text("Passer")) : null,
        middle: Text("Branches"),
        trailing:
            widget.isBootstrap && database.subjects.getAll().length >= 5
                ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Terminé", style: TextStyle(fontWeight: FontWeight.w800)),
                )
                : null,
      ),
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
                  header: Text("Vos branches"),

                  children: [
                    ...allSubjects.map(
                      (subject) => CupertinoListTile.notched(
                        backgroundColor: AppColors.secondaryBackground.adaptTo(context),
                        padding: EdgeInsets.all(10),
                        title: Row(
                          spacing: 6,
                          children: [
                            SubjectBadge(subject: subject),
                            const SizedBox(width: 4),
                            Text(subject.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            if (subject.isLocked) Icon(CupertinoIcons.lock_fill, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
                          ],
                        ),
                        trailing: CupertinoListTileChevron(),
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
                  footer: Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CustomText(
                      "Ajoutez ici les branches pour lesquelles vous souhaitez ajouter des notes et des devoirs. Vous pourrez toujours en ajouter ou en supprimer plus tard dans *Réglages > Branches*.",
                      style: TextStyle(color: AppColors.secondaryText.adaptTo(context), fontSize: 12),
                    ),
                  ),
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

  final defaultSubjects = [
    Subject()
      ..name = "Français"
      ..code = "french"
      ..iconCodePoint = Icons.translate.codePoint
      ..colorValue = const Color(0xFF1976D2).toInt(),

    Subject()
      ..name = "Mathématiques"
      ..code = "math"
      ..iconCodePoint = Icons.calculate.codePoint
      ..colorValue = const Color(0xFF388E3C).toInt(),

    Subject()
      ..name = "Anglais"
      ..code = "english"
      ..iconCodePoint = Icons.language.codePoint
      ..colorValue = const Color(0xFF7B1FA2).toInt(),
  ];

  for (var subject in defaultSubjects) {
    database.subjects.save(subject);
  }

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => SubjectsListPage(isBootstrap: true),
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
