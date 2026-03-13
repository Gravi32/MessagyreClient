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

  late final List<Grade> allGrades = database.grades.getAll();
  late final List<Subject> allSubjects = database.subjects.getAll();

  bool get usingDoubleCompensation => globals.persistent.getBool("UseDoubleCompensation") ?? false;
  bool get usingRestrictedGroup => globals.persistent.getBool("UseRestrictedGroup") ?? false;

  List<String> get restrictedGroupSubjectCodes => globals.persistent.getStringList("RestrictedGroupSubjects") ?? [];
  List<Subject> get restrictedGroupSubjects => allSubjects.where((subject) => restrictedGroupSubjectCodes.contains(subject.code)).toList();

  double get totalPoints => allAverages.values.sum;

  Map<String, double> get allAverages {
    final averages = <String, double>{};

    for (final subject in allSubjects) {
      if (subject.isLocked) {
        averages[subject.code] = subject.lockedGrade ?? 0;
        continue;
      }

      final subjectGrades = allGrades.where((g) => g.subject.value?.code == subject.code).toList();

      averages[subject.code] = subjectGrades.isEmpty ? 0 : calculateAverage(subjectGrades, round: true);
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
