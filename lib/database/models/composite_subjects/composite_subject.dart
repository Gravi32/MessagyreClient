import 'package:isar/isar.dart';
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
  late double firstSubjectWeight;

  final secondSubject = IsarLink<Subject>();
  late double secondSubjectWeight;

  CompositeSubject();

  @override
  String toString() => name;
}
