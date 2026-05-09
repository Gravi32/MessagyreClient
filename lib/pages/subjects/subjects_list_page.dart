import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/material.dart' hide Dialog, Page, ListTile;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_composite_subject_page.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/composite_subject_badge.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

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
      builder: (_) => Dialog.confirm(
        content: "Êtes-vous sûr de vouloir *passer* ?\n*Vous ne pourrez pas ajouter de notes et de devoirs* pour les branches qui ne sont pas dans la liste.",
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.form(
        context,
        onCloseConfirmed: widget.isBootstrap ? () => onSkipButtonPressed() : null,
        title: "Vos branches",
        trailing: widget.isBootstrap && database.subjects.getAll().length >= 5
            ? CupertinoButton(
                padding: .zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Terminé", style: TextStyle(fontWeight: .w800)),
              )
            : null,
      ),
      child: StreamBuilder(
        stream: database.subjects.watchAll(),
        builder: (context, _) {
          final allSubjects = database.subjects.getAll().sorted((a, b) {
            if (a.isLocked != b.isLocked) {
              return a.isLocked ? 1 : -1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          final allCompositeSubjects = database.compositeSubjects.getAll().sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return ListView(
            children: [
              ListSection(
                title: "Branches",
                margin: .only(top: 16),
                children: [
                  ...allSubjects.map(
                    (subject) => ListTile(
                      leading: SubjectBadge(subject: subject),
                      child: Row(
                        spacing: 6,
                        children: [
                          Text(subject.name, style: AppStyles.secondaryHeader(context)),
                          if (subject.isLocked) Icon(CupertinoIcons.lock_fill, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
                        ],
                      ),
                      onTap: () => showCupertinoSheet(
                        context: context,
                        builder: (context) => NewSubjectPage(toEdit: subject),
                      ),
                    ),
                  ),
                ],
              ),

              if (allCompositeSubjects.isNotEmpty)
                ListSection(
                  title: "Branches composées",
                  margin: .only(top: 16),
                  children: [
                    ...allCompositeSubjects.map(
                      (compositeSubject) => ListTile(
                        leading: CompositeSubjectBadge(compositeSubject: compositeSubject),
                        child: Text(compositeSubject.name, style: AppStyles.secondaryHeader(context)),
                        onTap: () => showCupertinoSheet(
                          context: context,
                          builder: (context) => NewCompositeSubjectPage(toEdit: compositeSubject),
                        ),
                      ),
                    ),
                  ],
                ),

              ListSection(
                margin: .only(top: 24),
                children: [
                  ListTile.simple(
                    context,
                    icon: HugeIcons.strokeRoundedAdd01,
                    title: "Ajouter",
                    onTap: () => showCupertinoSheet(context: context, builder: (context) => NewSubjectPage()),
                  ),
                  ListTile.simple(
                    context,
                    icon: HugeIcons.strokeRoundedNodeAdd,
                    title: "Ajouter une branche composée",
                    onTap: () => showCupertinoSheet(context: context, builder: (context) => NewCompositeSubjectPage()),
                  ),
                ],
              ),
              const BottomSpacing(),
            ],
          );
        },
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
