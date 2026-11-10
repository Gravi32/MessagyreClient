import 'package:isar_community/isar.dart';
import '../subjects/subject.dart';

part 'assignment.g.dart';

@collection
class Assignment {
  Id id = Isar.autoIncrement;

  final subject = IsarLink<Subject>();

  String? title;
  String content = 'Exercices';
  bool isMarkedAsDone = false;
  bool isShared = true;

  late DateTime dueDate;
  late DateTime? notificationDate;

  String? referenceId;

  /// The school year it was archived with ("2025-2026"), null while it is current. Archived ones are kept,
  /// hidden from the lists and the averages (see ArchiveService).
  @Index()
  String? archivedYear;

  int get getNotificationId => referenceId.hashCode.remainder(100000);

  @enumerated
  AssignmentType type = AssignmentType.assignment;

  @override
  String toString() => title ?? content;
}

enum AssignmentType { assignment, test, leave }
