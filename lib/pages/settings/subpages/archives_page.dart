import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:messagyre_client/configuration/app_icons.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/configuration/app_theme.dart';
import 'package:messagyre_client/services/archive_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';
import 'package:messagyre_client/utility/widgets/basics/empty_state.dart';
import 'package:messagyre_client/utility/widgets/basics/list_section.dart';
import 'package:messagyre_client/utility/widgets/basics/list_tile.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/subject_badge.dart';
import 'package:messagyre_client/utility/workarounds/bottom_spacing.dart';

/// The school years archived at the end of the year (see ArchiveService): read-only, and restorable
class ArchivesPage extends StatefulWidget {
  const ArchivesPage({super.key});

  @override
  State<ArchivesPage> createState() => _ArchivesPageState();
}

class _ArchivesPageState extends State<ArchivesPage> {
  final archives = ArchiveService();
  late List<ArchivedYear> years = archives.archivedYears();

  void confirmRestore(String label) {
    showCupertinoDialog(
      context: context,
      builder: (_) => Dialog.confirm(
        content: "Les notes et les devoirs de *$label* reviendront avec ceux de l'année en cours.",
        onConfirm: () async {
          await archives.restore(label);
          if (mounted) setState(() => years = archives.archivedYears());
        },
      ),
    );
  }

  Widget buildYear(ArchivedYear year) {
    final bySubject = groupBy(year.grades, (grade) => grade.subject.value?.code ?? "");
    final subjects = bySubject.entries.sortedBy((entry) => entry.value.first.subject.value?.name ?? "");
    final average = year.grades.isEmpty ? null : calculateAverage(year.grades);

    return ListSection(
      title: year.label,
      useLargeTitle: true,
      margin: const .only(top: AppSpacing.section),
      footer:
          "${year.grades.length} note${year.grades.length == 1 ? "" : "s"} · ${year.assignments.length} devoir${year.assignments.length == 1 ? "" : "s"}"
          "${average != null ? " · moyenne générale ${average.toStringAsFixed(2)}" : ""}",
      children: [
        for (final MapEntry(value: grades) in subjects)
          ListTile(
            buildChevron: false,
            child: Row(
              spacing: AppSpacing.m,
              children: [
                SubjectBadge(subject: grades.first.subject.value, size: 28),
                Expanded(child: Text(grades.first.subject.value?.name ?? "Sans branche", style: AppStyles.primaryText(context))),
                Text("${grades.length} · ", style: AppStyles.secondaryText(context)),
                Text(calculateAverage(grades).toStringAsFixed(2), style: AppStyles.strongText(context)),
              ],
            ),
          ),
        ListTile.simple(context, icon: HugeIcons.strokeRoundedArchive02, title: "Restaurer cette année", buildChevron: false, onTap: () => confirmRestore(year.label)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Page(
      topBar: TopBar.tab(context, title: "Archives"),
      child: years.isEmpty
          ? const EmptyState(
              icon: AppIcons.emptyList,
              title: "Aucune année archivée",
              subtitle: "À la fin de l'année scolaire, Messagyre vous proposera d'archiver vos notes et vos devoirs pour repartir de zéro.",
            )
          : ListView(children: [...years.map(buildYear), const BottomSpacing()]),
    );
  }
}
