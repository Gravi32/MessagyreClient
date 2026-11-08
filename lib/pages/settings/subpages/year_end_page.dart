import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/archive_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

/// The end of a school year: the subjects that are finished keep their final average (locked, rounded to the
/// half point), then every grade and assignment is archived. Pops `true` once archived.
class YearEndPage extends StatefulWidget {
  final String label;

  const YearEndPage({super.key, required this.label});

  @override
  State<YearEndPage> createState() => _YearEndPageState();
}

class _YearEndPageState extends State<YearEndPage> {
  final archives = ArchiveService();

  late final averages = archives.finalAverages().entries.toList()..sort((a, b) => a.key.name.toLowerCase().compareTo(b.key.name.toLowerCase()));
  final finished = <Subject>{};
  bool isArchiving = false;

  Future<void> confirm() async {
    if (isArchiving) return;
    setState(() => isArchiving = true);

    try {
      await archives.archive(widget.label, finished: {for (final MapEntry(key: subject, value: grade) in averages) if (finished.contains(subject)) subject: grade});
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => isArchiving = false);
      showCupertinoDialog(context: context, builder: (_) => Dialog.error(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.form(
        context,
        title: "Fin de l'année",
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedTick02, onTap: confirm),
      ),
      child: ListView(
        children: [
          CustomText(
            "Les notes et les devoirs de *${widget.label}* vont être archivés : vous les retrouverez dans *Réglages → Archives*.",
            style: AppStyles.secondaryText(context),
            padding: const EdgeInsets.only(top: AppSpacing.m),
          ),
          ListSection(
            title: "Branches terminées",
            margin: const EdgeInsets.only(top: AppSpacing.section),
            footer: averages.isEmpty
                ? "Aucune branche n'a de notes cette année."
                : "Une branche terminée est *bloquée* : elle garde sa moyenne finale, arrondie au demi-point, dans le bulletin et dans les branches composées. Les autres repartent de zéro.",
            children: [
              for (final MapEntry(key: subject, value: grade) in averages)
                ListTile(
                  buildChevron: false,
                  onTap: () => setState(() => finished.contains(subject) ? finished.remove(subject) : finished.add(subject)),
                  child: Row(
                    spacing: AppSpacing.m,
                    children: [
                      SubjectBadge(subject: subject, size: 28),
                      Expanded(child: Text(subject.name, style: AppStyles.primaryText(context))),
                      Text(grade.removeTrailingZero(), style: AppStyles.strongText(context)),
                      CupertinoSwitch(activeTrackColor: AppColors.accent, 
                        value: finished.contains(subject),
                        onChanged: (value) => setState(() => value ? finished.add(subject) : finished.remove(subject)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const BottomSpacing(),
        ],
      ),
    );
  }
}
