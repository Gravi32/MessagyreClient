import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';

/// An assignment sent in a chat (apps from 4.105), so that the others can add it to their own list. It travels
/// end-to-end encrypted in the message's "Attachment" field, like the description of a photo. It has no "Key":
/// the apps from 4.84 to 4.104 don't take it for a file and show the message's text instead ("📚 Devoir…").
class AssignmentShare {
  final AssignmentType type;
  final String? title;
  final String content;

  /// The subject's name on the sender's phone (the receiver's subjects may be named a little differently)
  final String? subjectName;
  final DateTime dueDate;

  const AssignmentShare({required this.type, this.title, required this.content, this.subjectName, required this.dueDate});

  factory AssignmentShare.of(Assignment assignment) => AssignmentShare(
    type: assignment.type,
    title: assignment.title,
    content: assignment.content,
    subjectName: assignment.subject.value?.name,
    dueDate: assignment.dueDate,
  );

  /// The main line: the test's title, or what has to be done
  String get headline => type == AssignmentType.test && (title?.trim().isNotEmpty ?? false) ? title!.trim() : content.trim();

  /// The text of the message: what the apps without this feature (and the notifications) show
  String get previewText {
    final date = DateFormat("EEEE d MMMM", "fr_CH").format(dueDate);
    final label = switch (type) {
      AssignmentType.test => "📝 Test",
      AssignmentType.leave => "🌴 Congé",
      AssignmentType.assignment => "📚 Devoir",
    };
    final subject = subjectName != null && subjectName!.trim().isNotEmpty ? " de ${subjectName!.trim()}" : "";
    return "$label$subject pour le $date : $headline";
  }

  Map<String, dynamic> toMap() => {
    "Version": 1,
    "Kind": "Assignment",
    "Type": type.name,
    if (title != null) "Title": title,
    "Content": content,
    if (subjectName != null) "Subject": subjectName,
    "DueDate": "${dueDate.year.toString().padLeft(4, "0")}-${dueDate.month.toString().padLeft(2, "0")}-${dueDate.day.toString().padLeft(2, "0")}",
  };

  String toJson() => jsonEncode(toMap());

  /// Null for anything else (a photo's description, a message from a newer app with something unknown...)
  static AssignmentShare? tryParse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json);
      if (map is! Map || map["Kind"] != "Assignment") return null;
      final dueDate = DateTime.tryParse(map["DueDate"]?.toString() ?? "");
      final content = map["Content"];
      if (dueDate == null || content is! String) return null;
      String? text(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;
      return AssignmentShare(
        type: AssignmentType.values.asNameMap()[map["Type"]?.toString()] ?? AssignmentType.assignment,
        title: text(map["Title"]),
        content: content.length > 5000 ? content.substring(0, 5000) : content,
        subjectName: text(map["Subject"]),
        dueDate: DateTime(dueDate.year, dueDate.month, dueDate.day),
      );
    } catch (_) {
      return null;
    }
  }

  /// The subject of this phone with the same name (ignoring case and accents' absence is too clever: exact name)
  Subject? matchingSubject(Iterable<Subject> subjects) {
    final name = subjectName?.trim().toLowerCase();
    if (name == null) return null;
    for (final subject in subjects) {
      if (subject.name.trim().toLowerCase() == name) return subject;
    }
    return null;
  }

  /// Whether an assignment of this phone is this one (already added)
  bool isSameAs(Assignment assignment) =>
      assignment.type == type &&
      assignment.content.trim() == content.trim() &&
      assignment.dueDate.year == dueDate.year &&
      assignment.dueDate.month == dueDate.month &&
      assignment.dueDate.day == dueDate.day;
}
