import 'package:isar/isar.dart';
import '../subjects/subject.dart';

part 'assignment.g.dart';

@collection
class Assignment {
  Id id = Isar.autoIncrement;

  final subject = IsarLink<Subject>();

  String? title;
  String content = 'Exercices';
  bool isMarkedAsDone = false;

  late DateTime dueDate;
  late DateTime? notificationDate;

  String? referenceId;

  int get getNotificationId => referenceId.hashCode.remainder(100000);

  @enumerated
  AssignmentType type = AssignmentType.assignment;

  @override
  String toString() => title ?? content;
}

enum AssignmentType { assignment, test, leave }
