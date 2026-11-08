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

  const SharedAssignment({required this.id, this.title, required this.content, this.authorUsername, required this.dueDate, required this.type});

  String get displayTitle => switch (type) {
    AssignmentType.test => (title?.trim().isNotEmpty ?? false) ? title!.trim() : "Test sans titre",
    _ => content.trim(),
  };

  bool matches(String filter) => "${title ?? ""} $content ${authorUsername ?? ""}".toLowerCase().contains(filter);

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
    );
  }

  static List<SharedAssignment> parseList(dynamic json) => json is List ? json.map(tryParse).whereType<SharedAssignment>().toList() : [];
}
