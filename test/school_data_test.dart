import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/pages/subjects/subjects_list_page.dart';
import 'package:messagyre_client/services/backup_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/school_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// JSON and back, like a copy saved on the server and read on a new install
Map<String, dynamic> throughJson(Map<String, dynamic> json) => jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  final physics = Subject()
    ..code = "physics"
    ..name = "Physique"
    ..iconCodePoint = 0xe0b0
    ..colorValue = 0xFF1976D2
    ..isLocked = true
    ..lockedGrade = 4.5
    ..lockedYear = "2025-2026";
  final biology = Subject()
    ..code = "biology"
    ..name = "Biologie";
  final subjectsByCode = {"physics": physics, "biology": biology};

  group("Saved copy of the school data", () {
    test("a locked subject keeps its final grade and the year it was locked with", () {
      final restored = BackupFormat.toSubject(throughJson(BackupFormat.subject(physics)))!;
      expect([restored.code, restored.name, restored.iconCodePoint, restored.colorValue], ["physics", "Physique", 0xe0b0, 0xFF1976D2]);
      expect([restored.isLocked, restored.lockedGrade, restored.lockedYear], [true, 4.5, "2025-2026"]);
    });

    test("a saved subject updates the default one with the same code instead of adding another", () {
      final existing = Subject()
        ..code = "physics"
        ..name = "Physique (défaut)";
      final restored = BackupFormat.toSubject(throughJson(BackupFormat.subject(physics)), existing: existing);
      expect(identical(restored, existing), isTrue);
      expect(existing.name, "Physique");
    });

    test("a grade comes back with its subject, weight, date and archive year", () {
      final grade = Grade()
        ..title = "TE 3"
        ..grade = 5.25
        ..weight = 2
        ..date = DateTime(2026, 3, 14, 10, 30)
        ..groupName = "Semestre 2"
        ..referenceId = "test-uuid"
        ..archivedYear = "2025-2026";
      grade.subject.value = physics;

      final restored = BackupFormat.toGrade(throughJson(BackupFormat.grade(grade)), subjectsByCode)!;
      expect(restored.subject.value, same(physics));
      expect([restored.title, restored.grade, restored.weight, restored.date, restored.groupName, restored.referenceId, restored.archivedYear], [
        "TE 3",
        5.25,
        2.0,
        DateTime(2026, 3, 14, 10, 30),
        "Semestre 2",
        "test-uuid",
        "2025-2026",
      ]);
      // Restored twice, it is recognised as the same grade
      expect(BackupFormat.gradeKey(restored), BackupFormat.gradeKey(grade));
    });

    test("two grades of the same test are different grades", () {
      Grade make(String title) => Grade()
        ..title = title
        ..grade = 4
        ..date = DateTime(2026, 1, 1)
        ..referenceId = "same-test";
      expect(BackupFormat.gradeKey(make("Oral")), isNot(BackupFormat.gradeKey(make("Écrit"))));
    });

    test("an assignment comes back with its type, state and reminder", () {
      final assignment = Assignment()
        ..title = "Exposé"
        ..content = "Préparer les slides"
        ..isMarkedAsDone = true
        ..isShared = false
        ..dueDate = DateTime(2026, 11, 20)
        ..notificationDate = DateTime(2026, 11, 19, 18)
        ..referenceId = "a-uuid"
        ..type = AssignmentType.test;
      assignment.subject.value = biology;

      final restored = BackupFormat.toAssignment(throughJson(BackupFormat.assignment(assignment)), subjectsByCode)!;
      expect(restored.subject.value, same(biology));
      expect([restored.title, restored.content, restored.isMarkedAsDone, restored.isShared, restored.dueDate, restored.notificationDate, restored.type], [
        "Exposé",
        "Préparer les slides",
        true,
        false,
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 19, 18),
        AssignmentType.test,
      ]);
      expect(BackupFormat.assignmentKey(restored), "a-uuid");
    });

    test("a composite subject comes back with its parts, and is skipped when they are missing", () {
      final composite = CompositeSubject()
        ..code = "sciences"
        ..name = "Sciences"
        ..firstSubjectPeriodsPerWeek = 2
        ..secondSubjectPeriodsPerWeek = 3;
      composite.firstSubject.value = physics;
      composite.secondSubject.value = biology;

      final json = throughJson(BackupFormat.composite(composite));
      final restored = CompositeSubject();
      expect(BackupFormat.fillComposite(restored, json, subjectsByCode), isTrue);
      expect(restored.parts.map((part) => (part.subject.code, part.periods)), [("physics", 2.0), ("biology", 3.0)]);
      expect(restored.thirdSubject.value, isNull);

      expect(BackupFormat.fillComposite(CompositeSubject(), json, {"physics": physics}), isFalse);
    });

    test("broken items are left out instead of failing the whole restore", () {
      expect(BackupFormat.toSubject({"Name": "Sans code"}), isNull);
      expect(BackupFormat.toGrade({"Title": "Sans note", "Date": "2026-01-01"}, subjectsByCode), isNull);
      expect(BackupFormat.toAssignment({"Title": "Sans date"}, subjectsByCode), isNull);
    });
  });

  group("\"Vos branches\" at the start", () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      GlobalsService().persistent = await SharedPreferences.getInstance();
    });
    setUp(() => GlobalsService().persistent.clear());

    final now = DateTime(2026, 11, 8, 12);

    test("is shown to a new user, not to one who already has their subjects", () {
      expect(SubjectsSetup.shouldAsk(3, now), isTrue);
      expect(SubjectsSetup.shouldAsk(8, now), isFalse);
    });

    test("\"Plus tard\" hides it for a few days, then it comes back", () async {
      await SubjectsSetup.postpone();
      final postponedAt = DateTime.now();
      expect(SubjectsSetup.shouldAsk(3, postponedAt), isFalse);
      expect(SubjectsSetup.shouldAsk(3, postponedAt.add(SubjectsSetup.postponement + const Duration(minutes: 1))), isTrue);
    });

    test("\"Terminé\" or \"Ne plus demander\" hide it for good", () async {
      await SubjectsSetup.markDone();
      expect(SubjectsSetup.shouldAsk(0, now.add(const Duration(days: 365))), isFalse);
    });
  });

  test("closing the year by hand archives the current year, or the one that just ended in the summer", () {
    expect(SchoolCalendar.yearToArchiveLabel(DateTime(2026, 11, 8)), "2026-2027");
    expect(SchoolCalendar.yearToArchiveLabel(DateTime(2027, 3, 1)), "2026-2027");
    expect(SchoolCalendar.yearToArchiveLabel(DateTime(2026, 7, 10)), "2025-2026");
  });
}
