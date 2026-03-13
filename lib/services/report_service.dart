import 'package:collection/collection.dart';
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
  List<Subject> get allSubjects => database.subjects.getAll().sorted(
    (a, b) => (a.isLocked ? 1 : 0).compareTo(b.isLocked ? 1 : 0) == 0 ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) : (a.isLocked ? 1 : -1),
  );

  bool get usingDoubleCompensation => globals.persistent.getBool("UseDoubleCompensation") ?? false;
  bool get usingRestrictedGroup => globals.persistent.getBool("UseRestrictedGroup") ?? false;

  List<String> get restrictedGroupSubjectCodes =>
      globals.persistent.getStringList("RestrictedGroupSubjects")?.where((code) => database.subjects.getByCode(code) != null).toList() ?? [];
  List<Subject> get restrictedGroupSubjects => allSubjects.where((subject) => restrictedGroupSubjectCodes.contains(subject.code)).toList();

  double get totalPoints => allAverages.values.sum;

  Map<String, double> get allAverages {
    final averages = <String, double>{};

    for (final subject in allSubjects) {
      if (subject.isLocked && subject.lockedGrade != null) {
        averages[subject.code] = subject.lockedGrade!;
        continue;
      }

      final subjectGrades = allGrades.where((g) => g.subject.value?.code == subject.code).toList();

      if (subjectGrades.isNotEmpty) averages[subject.code] = calculateAverage(subjectGrades, round: true);
    }

    return averages;
  }

  double doubleCompensation(Map<String, double> averages) {
    double deficit = 0;
    double surplus = 0;

    for (final avg in averages.values) {
      if (avg < 4) deficit += avg - 4;
      if (avg > 4) surplus += avg - 4;
    }

    return surplus + deficit * 2;
  }
}
