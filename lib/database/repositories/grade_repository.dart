import 'package:isar/isar.dart';
import '../models/grades/grade.dart';

class GradeRepository {
  final Isar isar;

  GradeRepository(this.isar);

  List<Grade> getAll() {
    final grades = isar.grades.where().findAllSync();

    for (final grade in grades) {
      grade.subject.loadSync();
    }

    return grades;
  }

  Grade? getByReferenceId(String id) => isar.grades.filter().referenceIdEqualTo(id).findFirstSync();

  Future<void> save(Grade grade) async {
    await isar.writeTxn(() async {
      await isar.grades.put(grade);
      await grade.subject.save();
    });
  }

  Future<void> delete(Grade grade) async {
    await isar.writeTxn(() async {
      await isar.grades.delete(grade.id);
    });
  }

  Stream<List<Grade>> watchAll() {
    return isar.grades.where().watch(fireImmediately: true);
  }
}
