import 'package:messagyre_client/database/models/assignments/assignment.dart';

/// An assignment shared with the whole class, as the server sends it (GET /shared/assignments/get).
/// Parsing never throws: a malformed row is skipped instead of breaking the assignments page.
class SharedAssignment {
  final int id;
  final String? title;
  final String content;
  final String? authorUsername;
  final DateTime dueDate;
  final AssignmentType type;

  /// The subject's name on the author's phone (apps from 4.112; null for the older ones)
  final String? subjectName;

  /// Whether I can change or remove it: I wrote it, or I am a delegate of the class (the server decides)
  final bool canEdit;

  /// Who changed it last, when it isn't its author (a delegate)
  final String? editedBy;

  const SharedAssignment({
    required this.id,
    this.title,
    required this.content,
    this.authorUsername,
    required this.dueDate,
    required this.type,
    this.subjectName,
    this.canEdit = false,
    this.editedBy,
  });

  String get displayTitle => switch (type) {
    AssignmentType.test => (title?.trim().isNotEmpty ?? false) ? title!.trim() : "Test sans titre",
    _ => content.trim(),
  };

  bool matches(String filter) => "${title ?? ""} $content ${subjectName ?? ""} ${authorUsername ?? ""}".toLowerCase().contains(filter);

  static SharedAssignment? tryParse(dynamic json) {
    if (json is! Map) return null;
    final dueDate = DateTime.tryParse(json["DueDate"]?.toString() ?? "");
    if (dueDate == null) return null;

    return SharedAssignment(
      id: int.tryParse(json["ID"]?.toString() ?? "") ?? 0,
      title: json["Title"]?.toString(),
      content: json["Content"]?.toString() ?? "",
      authorUsername: json["AuthorUsername"]?.toString(),
      dueDate: dueDate,
      type: AssignmentType.values.asNameMap()[(json["Type"]?.toString() ?? "assignment").toLowerCase()] ?? AssignmentType.assignment,
      subjectName: (json["Subject"]?.toString().trim().isEmpty ?? true) ? null : json["Subject"].toString().trim(),
      canEdit: json["CanEdit"] == true,
      editedBy: json["EditedBy"]?.toString(),
    );
  }

  static List<SharedAssignment> parseList(dynamic json) => json is List ? json.map(tryParse).whereType<SharedAssignment>().toList() : [];
}
