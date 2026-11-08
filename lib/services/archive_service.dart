import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/school_calendar.dart';
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

  /// Archives every current grade and assignment under [label] ("2025-2026")
  Future<({int grades, int assignments})> archive(String label) async {
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
      await _isar.grades.putAll(grades);
      await _isar.assignments.putAll(assignments);
      result = (grades: grades.length, assignments: assignments.length);
    });
    return result;
  }

  /// Puts an archived year back with the current data
  Future<void> restore(String label) async {
    await _isar.writeTxn(() async {
      final grades = await _isar.grades.filter().archivedYearEqualTo(label).findAll();
      final assignments = await _isar.assignments.filter().archivedYearEqualTo(label).findAll();
      for (final grade in grades) {
        grade.archivedYear = null;
      }
      for (final assignment in assignments) {
        assignment.archivedYear = null;
      }
      await _isar.grades.putAll(grades);
      await _isar.assignments.putAll(assignments);
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
          "Archiver l'année": () async {
            await archive(label);
            await globals.persistent.setString(_answeredKey, label);
          },
          "Plus tard": () => globals.persistent.setInt(_postponedKey, now.add(const Duration(days: 7)).millisecondsSinceEpoch),
          "Tout garder": () => globals.persistent.setString(_answeredKey, label),
        },
      ),
    );
  }

  // #endregion
}
