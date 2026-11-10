import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/settings/subpages/year_end_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/school_calendar.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/dialog.dart';

/// A school year put aside: its grades and assignments
typedef ArchivedYear = ({String label, List<Grade> grades, List<Assignment> assignments});

/// At the end of the school year, grades and assignments can be archived to start again from zero.
/// Nothing is deleted: they only get the year in `archivedYear`, which hides them, and can be restored.
class ArchiveService {
  static final ArchiveService _instance = ArchiveService._internal();
  factory ArchiveService() => _instance;
  ArchiveService._internal();

  final database = DatabaseService();
  final globals = GlobalsService();

  Isar get _isar => database.isar;

  bool get hasCurrentData => _isar.grades.filter().archivedYearIsNull().countSync() > 0 || _isar.assignments.filter().archivedYearIsNull().countSync() > 0;

  /// The final average of each subject with current grades, rounded to the half point (what a finished
  /// subject keeps once locked). Locked subjects are left out: they already have theirs.
  Map<Subject, double> finalAverages() {
    final grades = database.grades.getAll();
    return {
      for (final subject in database.subjects.getAll())
        if (!subject.isLocked)
          if (grades.where((grade) => grade.subject.value?.code == subject.code).toList() case final subjectGrades when subjectGrades.isNotEmpty)
            subject: clampDouble(calculateAverage(subjectGrades, round: true), 1, 6),
    };
  }

  /// Archives every current grade and assignment under [label] ("2025-2026"). The [finished] subjects are
  /// locked with their final average first: they keep it in the report (and in the composite subjects).
  Future<({int grades, int assignments})> archive(String label, {Map<Subject, double> finished = const {}}) async {
    var result = (grades: 0, assignments: 0);
    await _isar.writeTxn(() async {
      final grades = await _isar.grades.filter().archivedYearIsNull().findAll();
      final assignments = await _isar.assignments.filter().archivedYearIsNull().findAll();
      for (final grade in grades) {
        grade.archivedYear = label;
      }
      for (final assignment in assignments) {
        assignment.archivedYear = label;
      }
      for (final MapEntry(key: subject, value: finalGrade) in finished.entries) {
        subject
          ..isLocked = true
          ..lockedGrade = finalGrade
          ..lockedYear = label;
      }
      await _isar.grades.putAll(grades);
      await _isar.assignments.putAll(assignments);
      await _isar.subjects.putAll(finished.keys.toList());
      result = (grades: grades.length, assignments: assignments.length);
    });
    return result;
  }

  /// Puts an archived year back with the current data. The subjects locked when it was archived are
  /// unlocked: their grades are back, the average comes from them again.
  Future<void> restore(String label) async {
    await _isar.writeTxn(() async {
      final grades = await _isar.grades.filter().archivedYearEqualTo(label).findAll();
      final assignments = await _isar.assignments.filter().archivedYearEqualTo(label).findAll();
      final subjects = await _isar.subjects.filter().lockedYearEqualTo(label).findAll();
      for (final grade in grades) {
        grade.archivedYear = null;
      }
      for (final assignment in assignments) {
        assignment.archivedYear = null;
      }
      for (final subject in subjects) {
        subject
          ..isLocked = false
          ..lockedGrade = null
          ..lockedYear = null;
      }
      await _isar.grades.putAll(grades);
      await _isar.assignments.putAll(assignments);
      await _isar.subjects.putAll(subjects);
    });
  }

  /// The archived years, newest first
  List<ArchivedYear> archivedYears() {
    final grades = _isar.grades.filter().archivedYearIsNotNull().findAllSync();
    final assignments = _isar.assignments.filter().archivedYearIsNotNull().findAllSync();
    for (final grade in grades) {
      grade.subject.loadSync();
    }
    for (final assignment in assignments) {
      assignment.subject.loadSync();
    }

    final labels = {...grades.map((g) => g.archivedYear!), ...assignments.map((a) => a.archivedYear!)}.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final label in labels)
        (label: label, grades: grades.where((g) => g.archivedYear == label).toList(), assignments: assignments.where((a) => a.archivedYear == label).toList()),
    ];
  }

  // #region -> End of year prompt

  static const _answeredKey = "ArchivePromptAnsweredFor";
  static const _postponedKey = "ArchivePromptPostponedUntil";

  /// After the end of the school year, asks once whether to archive it (shown at the app's start)
  Future<void> askToArchiveIfYearEnded(BuildContext context) async {
    final now = DateTime.now();
    if (!SchoolCalendar.isArchivePeriod(now) || !hasCurrentData) return;

    final label = SchoolCalendar.endedYearLabel(now);
    if (globals.persistent.getString(_answeredKey) == label) return;
    if (now.millisecondsSinceEpoch < (globals.persistent.getInt(_postponedKey) ?? 0)) return;

    await showCupertinoDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        title: "Fin de l'année 🎓",
        content:
            "L'année scolaire *$label* est terminée ! Voulez-vous *archiver* vos notes et vos devoirs pour repartir de zéro ?\n\nRien n'est supprimé : vous les retrouverez dans *Réglages → Archives* et pourrez les restaurer.",
        options: {
          // The year's end page lets the finished subjects keep their final average, then archives
          "Archiver l'année": () => WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!context.mounted) return;
            final archived = await showCupertinoSheet<bool>(context: context, builder: (_) => YearEndPage(label: label));
            if (archived == true) await globals.persistent.setString(_answeredKey, label);
          }),
          "Plus tard": () => globals.persistent.setInt(_postponedKey, now.add(const Duration(days: 7)).millisecondsSinceEpoch),
          "Tout garder": () => globals.persistent.setString(_answeredKey, label),
        },
      ),
    );
  }

  // #endregion
}
