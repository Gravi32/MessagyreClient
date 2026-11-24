import 'package:isar_community/isar.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';

part 'composite_subject.g.dart';

@collection
class CompositeSubject {
  Id id = Isar.autoIncrement;

  /// identifier (ex: "maths", "history")
  @Index(unique: true)
  late String code;

  late String name;

  final firstSubject = IsarLink<Subject>();
  late double firstSubjectPeriodsPerWeek;

  final secondSubject = IsarLink<Subject>();
  late double secondSubjectPeriodsPerWeek;

  /// Optional (since 4.91): a composite subject can be made of three subjects
  final thirdSubject = IsarLink<Subject>();
  double thirdSubjectPeriodsPerWeek = 0;

  /// Since 4.111: counted as soon as one sub-subject has grades (the others are left out of its average until they
  /// have some). Otherwise every sub-subject needs grades.
  bool countWithMissingParts = false;

  /// "In brackets" (since 4.111): its average is shown but it doesn't count in the report
  bool excludedFromReport = false;

  CompositeSubject();

  @override
  String toString() => name;

  /// The sub-subjects (two or three) with their periods per week, in order
  @ignore
  List<({Subject subject, double periods})> get parts => [
    if (firstSubject.value != null) (subject: firstSubject.value!, periods: firstSubjectPeriodsPerWeek),
    if (secondSubject.value != null) (subject: secondSubject.value!, periods: secondSubjectPeriodsPerWeek),
    if (thirdSubject.value != null && thirdSubjectPeriodsPerWeek > 0) (subject: thirdSubject.value!, periods: thirdSubjectPeriodsPerWeek),
  ];

  @ignore
  List<Subject> get subjects => parts.map((part) => part.subject).toList();

  double get totalPeriodsPerWeek => parts.fold(0.0, (total, part) => total + part.periods);
}
