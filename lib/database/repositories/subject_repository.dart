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

  Subject? getByCode(String code) {
    return isar.subjects.filter().codeEqualTo(code).findFirstSync();
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
