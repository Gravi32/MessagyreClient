import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/services/class_service.dart';

void main() {
  group("A class", () {
    test("is written like the school writes it", () {
      expect(const SchoolClass(1, "M", "05").name, "1M05");
      expect(const SchoolClass(3, "M", "b11").name, "3Mb11");
      expect(const SchoolClass(2, "EC", "3").name, "2EC3");
      expect(const SchoolClass(2, "C", "ci1").name, "2Cci1");
    });

    test("every class of the school's list (gyre.ch, 2026-2027) is a class", () {
      const list = [
        "1M01", "1M10", "2M09", "3M10", "3Mb11", "3Mb17", // maturité
        "1EC1", "2EC2", "3EC3", "4EC1", // commerce
        "1C1", "1C4", "2Cadts", "2Cci1", "2Cci3", "2Csa", "3Cad", "3Cci2", "3Csa", "3Cts", // culture générale
      ];
      for (final value in list) {
        expect(SchoolClass.tryParse(value)?.name, value, reason: value);
        expect(SchoolClass.sectionsOf(int.parse(value[0]), SchoolClass.tryParse(value)!.school), contains(SchoolClass.tryParse(value)!.section));
      }
    });

    test("is read however it is written", () {
      expect(SchoolClass.tryParse("1m5")?.name, "1M05");
      expect(SchoolClass.tryParse("3MB11")?.name, "3Mb11");
      expect(SchoolClass.tryParse(" 2cci1 ")?.name, "2Cci1");
      expect(SchoolClass.tryParse("2CTsAd")?.name, "2Cadts");
      expect(SchoolClass.tryParse("2CSA")?.name, "2Csa");
    });

    test("nothing else is a class", () {
      for (final value in [
        "4M01", "1M00", "1M21", "1Mb11", "5EC1", "1EC", "1Cci1", "4C1", "2C1", "2Cxx", "2Ccici", "2Cadts1", "2Cci4", "1C9",
        "Externe", "Enseignant", "", null,
      ]) {
        expect(SchoolClass.tryParse(value), isNull, reason: "$value");
      }
    });

    test("says what it is", () {
      expect(SchoolClass.tryParse("1EC1")!.description, "École de commerce");
      expect(SchoolClass.tryParse("1C2")!.description, "École de culture générale");
      expect(SchoolClass.tryParse("2Cci1")!.description, "Communication et information");
      expect(SchoolClass.tryParse("2Cadts")!.description, "Arts et design et Travail social");
      expect(SchoolClass.tryParse("3Mb11")!.description, "École de maturité, bilingue");
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
