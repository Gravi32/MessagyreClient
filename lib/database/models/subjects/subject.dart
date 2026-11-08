import 'package:isar/isar.dart';
import 'package:flutter/material.dart';
import 'package:messagyre_client/configuration/app_colors.dart';

part 'subject.g.dart';

@collection
class Subject {
  Id id = Isar.autoIncrement;

  /// identifier (ex: "maths", "history")
  @Index(unique: true)
  late String code;

  late String name;

  int? iconCodePoint;

  int? colorValue;

  /// A finished subject: it keeps [lockedGrade] in the report (its final average, rounded to the half point)
  bool isLocked = false;

  double? lockedGrade;

  /// The school year it was locked with at the end of the year ("2025-2026"): restoring that year unlocks it.
  /// Null when it was locked by hand.
  String? lockedYear;

  Subject();

  @ignore
  Color get color => colorValue != null ? Color(colorValue!) : AppColors.grey;

  @ignore
  IconData get icon => iconCodePoint != null ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons') : Icons.question_mark_rounded;

  @override
  String toString() => name;
}
