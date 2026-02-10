import 'package:isar/isar.dart';
import '../models/subjects/subject.dart';

class SubjectRepository {
  final Isar isar;

  SubjectRepository(this.isar);

  List<Subject> getAll() => isar.subjects.where().sortByName().findAllSync();

  Future<void> save(Subject subject) async {
    await isar.writeTxn(() async {
      await isar.subjects.put(subject);
    });
    return;
  }

  Future<void> saveAll(List<Subject> subjects) async {
    await isar.writeTxn(() async {
      await isar.subjects.putAll(subjects);
    });
    return;
  }

  Future<Subject?> getByCode(String code) async {
    return await isar.subjects.filter().codeEqualTo(code).findFirst();
  }

  Stream<List<Subject>> watchAll() {
    return isar.subjects.where().watch(fireImmediately: true);
  }

  Future<void> delete(Subject subject) async {
    await isar.writeTxn(() async {
      await isar.subjects.delete(subject.id);
    });
    return;
  }
}
