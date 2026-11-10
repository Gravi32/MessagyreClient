import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/services/class_service.dart';

void main() {
  group("A class", () {
    // The app's copy of the server's catalog (Server/Assets/Classes.json)
    final catalog = ClassCatalog.tryParse(File("assets/classes.json").readAsStringSync())!;

    test("the app's catalog is the same as the server's", () {
      expect(File("assets/classes.json").readAsStringSync(), File("../Server/Assets/Classes.json").readAsStringSync());
    });

    test("every class of the school's list (gyre.ch, 2026-2027) is in the catalog", () {
      const list = [
        "1M01", "1M10", "2M09", "3M10", "3Mb11", "3Mb17", // maturité
        "1EC1", "2EC2", "3EC3", // commerce
        "1C1", "1C4", "2Cadts", "2Cci1", "2Cci3", "2Csa", "3Cad", "3Cci2", "3Csa", "3Cts", // culture générale
      ];
      for (final value in list) {
        expect(catalog.find(value), value, reason: value);
        final schoolClass = SchoolClass.tryParse(value, catalog: catalog)!;
        expect(catalog.schoolNamed(schoolClass.school)!.classes[schoolClass.year], contains(value));
      }
      expect([for (final school in catalog.schools) school.code], ["M", "EC", "C"]);
    });

    test("is read however it is written", () {
      expect(SchoolClass.tryParse("2cci1", catalog: catalog)?.name, "2Cci1");
      expect(SchoolClass.tryParse("3MB11", catalog: catalog)?.name, "3Mb11");
      expect(SchoolClass.tryParse(" 2CSA ", catalog: catalog)?.name, "2Csa");
      // Not in the catalog any more, but still a class (nobody is taken out of their class during the year)
      expect(SchoolClass.tryParse("2M10", catalog: catalog)?.name, "2M10");
    });

    test("nothing else is a class", () {
      for (final value in ["5M01", "Externe", "Enseignant", "-", "", null]) {
        expect(SchoolClass.tryParse(value, catalog: catalog), isNull, reason: "$value");
      }
    });

    test("says what it is", () {
      String describe(String name) => SchoolClass.tryParse(name, catalog: catalog)!.describe(catalog);
      expect(describe("1EC1"), "École de commerce");
      expect(describe("1C2"), "École de culture générale");
      expect(describe("2Cci1"), "Communication et information");
      expect(describe("2Cadts"), "Arts et design et Travail social");
      expect(describe("3Mb11"), "École de maturité, bilingue");
      expect(describe("2M04"), "École de maturité");
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
