import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/backup_service.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/color_picker.dart';

Map<String, dynamic> throughJson(Map<String, dynamic> json) => jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  Subject subject(String code) => Subject()
    ..code = code
    ..name = code;

  Grade grade(Subject subject, double value) {
    final grade = Grade()
      ..title = "Test"
      ..grade = value
      ..weight = 1
      ..date = DateTime(2026, 11, 1);
    grade.subject.value = subject;
    return grade;
  }

  final biology = subject("biologie"), chemistry = subject("chimie");
  CompositeSubject bioChemistry({bool countWithMissingParts = false}) {
    final composite = CompositeSubject()
      ..code = "bio_chimie"
      ..name = "Bio-chimie"
      ..firstSubjectPeriodsPerWeek = 2
      ..secondSubjectPeriodsPerWeek = 2
      ..countWithMissingParts = countWithMissingParts;
    composite.firstSubject.value = biology;
    composite.secondSubject.value = chemistry;
    return composite;
  }

  group("Composite subject with a part without grades", () {
    test("doesn't count until every part has grades, unless asked", () {
      final grades = [grade(chemistry, 5)];
      expect(calculateCompositeSubjectAverage(bioChemistry(), grades: grades), isNull);
      expect(calculateCompositeSubjectAverage(bioChemistry(countWithMissingParts: true), grades: grades), 5);
    });

    test("the parts with grades keep their weights", () {
      final composite = bioChemistry(countWithMissingParts: true)..firstSubjectPeriodsPerWeek = 3;
      expect(calculateCompositeSubjectAverage(composite, grades: [grade(biology, 4), grade(chemistry, 6)]), closeTo((4 * 3 + 6 * 2) / 5, 1e-9));
    });

    test("nothing at all: no average", () {
      expect(calculateCompositeSubjectAverage(bioChemistry(countWithMissingParts: true), grades: const []), isNull);
    });

    test("a part in brackets is left out of the composite subject", () {
      final inBrackets = subject("chimie_parentheses")..excludedFromReport = true;
      final composite = bioChemistry();
      composite.secondSubject.value = inBrackets;
      expect(calculateCompositeSubjectAverage(composite, grades: [grade(biology, 4.5), grade(inBrackets, 2)]), 4.5);
    });
  });

  group("Saved copy", () {
    test("a subject in brackets stays in brackets", () {
      final restored = BackupFormat.toSubject(throughJson(BackupFormat.subject(subject("latin")..excludedFromReport = true)))!;
      expect(restored.excludedFromReport, isTrue);
      expect(BackupFormat.toSubject({"Code": "old", "Name": "Ancienne copie"})!.excludedFromReport, isFalse);
    });

    test("a composite subject keeps its two options", () {
      final composite = bioChemistry(countWithMissingParts: true)..excludedFromReport = true;
      final restored = CompositeSubject();
      expect(BackupFormat.fillComposite(restored, throughJson(BackupFormat.composite(composite)), {"biologie": biology, "chimie": chemistry}), isTrue);
      expect(restored.countWithMissingParts, isTrue);
      expect(restored.excludedFromReport, isTrue);
    });
  });

  test("colour codes of the announcements", () {
    expect(colorToHex(const Color(0xFF8B3FD9)), "#8B3FD9");
    expect(colorFromHex("#8b3fd9"), const Color(0xFF8B3FD9));
    expect(colorFromHex("8B3FD9"), const Color(0xFF8B3FD9));
    expect(colorFromHex("#12345"), isNull);
    expect(colorFromHex("accent"), isNull);
  });
}
