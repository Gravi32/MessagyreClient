import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/database/models/assignments/shared_assignment.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/utility/subject_matching.dart';

Subject subject(String name) => Subject()
  ..code = name
  ..name = name;

void main() {
  final mine = [subject("Français"), subject("Mathématiques"), subject("Biologie"), subject("Histoire"), subject("Physique"), subject("Philosophie")];

  String? match(String? name, [List<Subject>? subjects]) => matchSubjectByName(name, subjects ?? mine)?.name;

  test("A classmate's subject is found even named a little differently", () {
    expect(match("Francais"), "Français");
    expect(match("FRANÇAIS "), "Français");
    expect(match("Math"), "Mathématiques");
    expect(match("Maths"), "Mathématiques");
    expect(match("Bio"), "Biologie");
    expect(match("histoire"), "Histoire");
  });

  test("Nothing is guessed when no subject fits or several could", () {
    expect(match(null), isNull);
    expect(match(""), isNull);
    expect(match("Ph"), isNull);
    expect(match("Allemand"), isNull);
    expect(match("Math", [subject("Mathématiques"), subject("Math appliquées")]), isNull);
    // The exact name wins over the other candidates
    expect(match("Math", [subject("Math"), subject("Mathématiques")]), "Math");
  });

  test("A class-shared assignment keeps its subject", () {
    final parsed = SharedAssignment.parseList([
      {"ID": 1, "Content": "Ex. 3", "DueDate": "2026-11-26T00:00:00", "Type": "Assignment", "Subject": "Francais"},
      {"ID": 2, "Content": "Ex. 4", "DueDate": "2026-11-27T00:00:00", "Type": "Assignment", "Subject": null},
    ]);
    expect(parsed.map((a) => a.subjectName), ["Francais", null]);
  });
}
