import 'package:collection/collection.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/utility.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final database = DatabaseService();
  final globals = GlobalsService();

  List<Grade> get allGrades => database.grades.getAll();

  List<Subject> get allSubjects {
    final compositeCodes = allCompositeSubjects.expand((c) => [c.firstSubject.value?.code, c.secondSubject.value?.code]).whereType<String>().toSet();

    return database.subjects.getAll().where((s) => !compositeCodes.contains(s.code)).sorted((a, b) {
      if (a.isLocked != b.isLocked) return a.isLocked ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  List<CompositeSubject> get allCompositeSubjects => database.compositeSubjects.getAll().sortedBy((s) => s.name.toLowerCase());

  bool get usingDoubleCompensation => globals.persistent.getBool("UseDoubleCompensation") ?? false;
  bool get usingRestrictedGroup => globals.persistent.getBool("UseRestrictedGroup") ?? false;

  List<String> get restrictedGroupCodes => globals.persistent.getStringList("RestrictedGroupSubjects") ?? [];
  List<Subject> get restrictedGroupSubjects => allSubjects.where((s) => restrictedGroupCodes.contains(s.code)).toList();
  List<CompositeSubject> get restrictedGroupCompositeSubjects => allCompositeSubjects.where((c) => restrictedGroupCodes.contains(c.code)).toList();

  double get totalPoints => allAverages.values.sum;

  /// A list of the average of all subjects and composite subjects.
  Map<String, double> get allAverages {
    final averages = <String, double>{};
    final grades = allGrades;

    for (final subject in allSubjects) {
      if (subject.isLocked && subject.lockedGrade != null) {
        averages[subject.code] = subject.lockedGrade!;
      } else {
        final subjectGrades = grades.where((g) => g.subject.value?.code == subject.code).toList();
        if (subjectGrades.isNotEmpty) {
          averages[subject.code] = calculateAverage(subjectGrades, round: true);
        }
      }
    }

    for (final composite in allCompositeSubjects) {
      final avg = calculateCompositeSubjectAverage(composite, round: true);
      if (avg != null) averages[composite.code] = avg;
    }
    return averages;
  }

  /// A list of the unrounded average of all subjects and composite subjects.
  Map<String, double> get allAveragesRaw {
    final averages = <String, double>{};
    final grades = allGrades;

    for (final subject in allSubjects) {
      final subjectGrades = grades.where((g) => g.subject.value?.code == subject.code).toList();
      if (subjectGrades.isNotEmpty) {
        averages[subject.code] = calculateAverage(subjectGrades, round: false);
      }
    }

    for (final composite in allCompositeSubjects) {
      final avg = calculateCompositeSubjectAverage(composite, round: false);
      if (avg != null) averages[composite.code] = avg;
    }
    return averages;
  }
}
