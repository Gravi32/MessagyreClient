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
    final compositeCodes = allCompositeSubjects.expand((c) => c.subjects.map((s) => s.code)).toSet();

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
  List<double> get restrictedGroupAverages => restrictedGroupCodes.map((code) => allAverages[code]).whereType<double>().toList();

  /// The averages the limits (insufficient grades, negative points) are counted on: all of them, or only the
  /// restricted group's (the école de commerce counts them on the maturité professionnelle's subjects)
  Iterable<double> get _limitedAverages =>
      usingRestrictedGroup && limitsOnRestrictedGroup && restrictedGroupCodes.isNotEmpty ? restrictedGroupAverages : allAverages.values;

  bool get limitsOnRestrictedGroup => globals.persistent.getBool("LimitsOnRestrictedGroup") ?? false;

  // Failing grades
  int get failingGrades => _limitedAverages.where((grade) => grade < 3.75).length;
  int get maxFailingGrades => globals.persistent.getInt("MaxFailingSubjects") ?? 4;

  // Negative points: how far below 4 the insufficient averages are, added up (at most 2 in the ECG and the EC)
  bool get usingMaxNegativePoints => globals.persistent.getBool("UseMaxNegativePoints") ?? false;
  double get maxNegativePoints => _number("MaxNegativePoints") ?? 2;
  double get negativePoints => _limitedAverages.where((v) => v < 4).fold(0.0, (sum, v) => sum + (4 - v));

  /// A number saved as an int or a double (a backup can turn 2.0 into 2)
  double? _number(String key) {
    final value = globals.persistent.get(key);
    return value is num ? value.toDouble() : null;
  }

  // Restricted group points
  double get restrictedGroupPoints => restrictedGroupAverages.sum;
  double get minRestrictedGroupPoints => restrictedGroupAverages.length * 4;
  double get maxRestrictedGroupPoints => restrictedGroupAverages.length * 6;

  // Total points
  double get totalPoints => allAverages.values.sum;
  double get maxTotalPoints => fixedMinTotalPoints != null ? fixedMinTotalPoints! / 4 * 6 : allAverages.length * 6;

  /// 4 points per average of the bulletin. Chosen by the user (36 for the 9 averages of the 1st year of the ECG),
  /// otherwise 4 times the subjects that have an average (the missing ones would be forgotten early in the year)
  double get minTotalPoints => fixedMinTotalPoints ?? allAverages.length * 4.0;
  double? get fixedMinTotalPoints {
    final value = _number("MinTotalPoints");
    return value == null || value <= 0 ? null : value;
  }

  // Double compensation
  double get surplus => allAverages.values.where((v) => v > 4).fold(0.0, (sum, v) => sum + (v - 4));
  double get deficit => allAverages.values.where((v) => v < 4).fold(0.0, (sum, v) => sum + (v - 4));
  double get doubleCompensation => surplus + (deficit * 2);

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
