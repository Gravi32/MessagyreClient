import 'package:isar_community/isar.dart';
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

  /// The school year it was archived with ("2025-2026"), null while it is current. Archived ones are kept,
  /// hidden from the lists and the averages (see ArchiveService).
  @Index()
  String? archivedYear;

  @override
  String toString() => '$title ($grade)';
}
