import 'package:isar/isar.dart';
import '../subjects/subject.dart';

part 'assignment.g.dart';

@collection
class Assignment {
  Id id = Isar.autoIncrement;

  final subject = IsarLink<Subject>();

  String? title;
  String content = 'Exercices';

  late DateTime dueDate;

  bool isGraded = false;
  bool isTest = false;
  bool isMarkedAsDone = false;

  String? referenceId;
  String? calendarEventId;

  @override
  String toString() => title ?? content;
}
