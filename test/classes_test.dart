import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/services/class_service.dart';

void main() {
  group("A class", () {
    test("is written like the school writes it", () {
      expect(const SchoolClass(1, "M", 5).name, "1M05");
      expect(const SchoolClass(3, "M", 12).name, "3M12");
      expect(const SchoolClass(2, "EC", 3).name, "2EC3");
      expect(const SchoolClass(1, "C", 2).name, "1C2");
    });

    test("is read with or without the leading zero, and nothing else is a class", () {
      expect(SchoolClass.tryParse("1M05"), const SchoolClass(1, "M", 5));
      expect(SchoolClass.tryParse("1m5"), const SchoolClass(1, "M", 5));
      expect(SchoolClass.tryParse("4EC15")?.name, "4EC15");
      for (final value in ["5M01", "1M16", "1M00", "2Cci1", "Externe", "Enseignant", "", null]) {
        expect(SchoolClass.tryParse(value), isNull, reason: "$value");
      }
    });

    test("is chosen for a school year that changes in the middle of August", () {
      expect(SchoolClass.yearLabel(DateTime(2026, 11, 8)), "2026-2027");
      expect(SchoolClass.yearLabel(DateTime(2027, 6, 30)), "2026-2027");
      expect(SchoolClass.yearLabel(DateTime(2027, 8, 14)), "2026-2027");
      expect(SchoolClass.yearLabel(DateTime(2027, 8, 15)), "2027-2028");
    });
  });

  group("The class is asked", () {
    final now = DateTime(2026, 11, 8);

    test("to a new account and to an account without one", () {
      expect(ClassService.needsAnswer(null, null, now), isTrue);
      expect(ClassService.needsAnswer("", null, now), isTrue);
      expect(ClassService.needsAnswer("-", null, now), isTrue);
    });

    test("again when the class was chosen for an earlier school year, or before the picker existed", () {
      expect(ClassService.needsAnswer("1M05", "2025-2026", now), isTrue);
      expect(ClassService.needsAnswer("3M01", null, now), isTrue);
      expect(ClassService.needsAnswer("2Cci1", null, now), isTrue);
      expect(ClassService.needsAnswer("1M05", "2026-2027", now), isFalse);
    });

    test("never to someone outside the Gymnase or with a role", () {
      expect(ClassService.needsAnswer(SchoolClass.outside, "2026-2027", now), isFalse);
      expect(ClassService.needsAnswer("Enseignant", null, now), isFalse);
      expect(ClassService.needsAnswer("Directeur", null, now), isFalse);
    });
  });

  test("a class chat is told apart from a conversation with someone", () {
    expect(ClassService.chatIdOf("1M05"), "#1M05");
    expect(ClassService.classOfChat("#1M05"), "1M05");
    expect(ClassService.classOfChat("lea.martin"), isNull);
    expect(ClassService.isClassChat("support.messagyre"), isFalse);
  });
}
