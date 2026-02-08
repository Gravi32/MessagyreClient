import 'package:isar/isar.dart';
import '../subjects/subject.dart';

part 'grade.g.dart';

@collection
class Grade {
  Id id = Isar.autoIncrement;

  final subject = IsarLink<Subject>();

  late String title;
  double grade = 4;
  late DateTime date;

  String? details;
  double weight = 1;

  String? groupName;
  String? referenceId;

  @override
  String toString() => '$title ($grade)';
}
