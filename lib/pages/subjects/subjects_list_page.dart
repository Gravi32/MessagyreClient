import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:flutter/material.dart' hide Dialog, Page, ListTile;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_composite_subject_page.dart';
import 'package:messagyre_client/pages/subjects/subpages/new_subject_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
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

  /// Closing the first-start sheet: later (it comes back in a few days) or never
  void onCloseBootstrap() {
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog(
        title: "Configurer plus tard ?",
        content: "Vos branches servent à ajouter des *notes* et des *devoirs*. Vous pouvez aussi les gérer dans *Réglages → Branches*.",
        options: {
          "Plus tard": () {
            SubjectsSetup.postpone();
            Navigator.pop(context);
          },
          "Ne plus demander": () {
            SubjectsSetup.markDone();
            Navigator.pop(context);
          },
          "Annuler": () {},
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.form(
        context,
        onPop: widget.isBootstrap ? onCloseBootstrap : null,
        title: "Vos branches",
        trailing: widget.isBootstrap
            ? CupertinoButton(
                padding: .zero,
                onPressed: () {
                  SubjectsSetup.markDone();
                  Navigator.of(context).pop();
                },
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
                      leading: SubjectBadge(subject: subject, size: 32),
                      child: Row(
                        spacing: 6,
                        children: [
                          Text(subject.name, style: AppStyles.strongText(context)),
                          if (subject.isLocked) HugeIcon(icon: AppIcons.locked, size: 18, color: AppColors.tertiaryText.adaptTo(context)),
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
                        leading: CompositeSubjectBadge(compositeSubject: compositeSubject, size: 32),
                        child: Text(compositeSubject.name, style: AppStyles.strongText(context)),
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

/// The "Vos branches" sheet for new users: shown at the start until they finish it or say never; "Plus tard"
/// postpones it by a few days. Accounts that already have their subjects never see it.
class SubjectsSetup {
  static const _doneKey = "SubjectsSetupDone";
  static const _postponedKey = "SubjectsSetupPostponedUntil";
  static const postponement = Duration(days: 3);

  static final _globals = GlobalsService();

  static bool get isDone => _globals.persistent.getBool(_doneKey) ?? false;

  static Future<void> markDone() => _globals.persistent.setBool(_doneKey, true);

  static Future<void> postpone() => _globals.persistent.setInt(_postponedKey, DateTime.now().add(postponement).millisecondsSinceEpoch);

  /// Whether to show it now, for this many subjects
  static bool shouldAsk(int subjectsCount, DateTime now) {
    if (isDone) return false;
    if (subjectsCount > 5) return false; // set up before this sheet could be postponed
    return now.millisecondsSinceEpoch >= (_globals.persistent.getInt(_postponedKey) ?? 0);
  }
}

Future<void> askUserToAddTheirSubjects(BuildContext context) async {
  final database = DatabaseService();

  final count = database.subjects.getAll().length;
  if (count > 5 && !SubjectsSetup.isDone) await SubjectsSetup.markDone();
  if (!SubjectsSetup.shouldAsk(count, DateTime.now())) return;
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

  // A start for a new user only: subjects deleted on purpose don't come back
  if (count == 0) await database.subjects.saveAll(defaultSubjects);
  if (!context.mounted) return;

  await Navigator.of(context).push(
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

  // Closed without an answer (Android's back button): like "Plus tard"
  if (!SubjectsSetup.isDone) await SubjectsSetup.postpone();
}
