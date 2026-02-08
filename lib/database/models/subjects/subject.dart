import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

part 'subject.g.dart';

@collection
class Subject {
  Id id = Isar.autoIncrement;

  /// identificatore logico (es: "maths", "history")
  late String code;

  late String name;

  String? imagePath;

  int? iconCodePoint;

  int? colorValue;

  Subject();

  @ignore
  Color? get color => colorValue != null ? Color(colorValue!) : null;

  @ignore
  IconData? get icon => iconCodePoint != null ? IconData(iconCodePoint!, fontFamily: 'MaterialIcons') : null;

  @override
  String toString() => name;
}
