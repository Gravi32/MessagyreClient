import 'package:isar/isar.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';

class CompositeSubjectRepository {
  final Isar isar;

  CompositeSubjectRepository(this.isar);

  List<CompositeSubject> getAll() {
    final all = isar.compositeSubjects.where().sortByName().findAllSync();
    for (final composite in all) {
      composite.firstSubject.loadSync();
      composite.secondSubject.loadSync();
      composite.thirdSubject.loadSync();
    }
    return all;
  }

  CompositeSubject? getByCode(String code) {
    return isar.compositeSubjects.filter().codeEqualTo(code).findFirstSync();
  }

  Future<void> save(CompositeSubject compositeSubject) async {
    await isar.writeTxn(() async {
      await isar.compositeSubjects.put(compositeSubject);

      await compositeSubject.firstSubject.save();
      await compositeSubject.secondSubject.save();
      await compositeSubject.thirdSubject.save();
    });
  }

  Future<void> saveAll(List<CompositeSubject> compositeSubjects) async {
    await isar.writeTxn(() async {
      await isar.compositeSubjects.putAll(compositeSubjects);

      for (final composite in compositeSubjects) {
        await composite.firstSubject.save();
        await composite.secondSubject.save();
        await composite.thirdSubject.save();
      }
    });
  }

  Stream<List<CompositeSubject>> watchAll() {
    return isar.compositeSubjects.where().watch(fireImmediately: true);
  }

  Future<void> delete(CompositeSubject compositeSubject) async {
    await isar.writeTxn(() async {
      await isar.compositeSubjects.delete(compositeSubject.id);
    });
  }
}
