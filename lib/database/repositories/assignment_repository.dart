import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import '../models/assignments/assignment.dart';

class AssignmentRepository {
  final Isar isar;

  AssignmentRepository(this.isar);

  List<Assignment> getAll() {
    try {
      final allAssignments = isar.assignments.where().sortByDueDate().findAllSync();
      for (final assignment in allAssignments) {
        assignment.subject.loadSync();
      }
      return allAssignments;
    } catch (e) {
      debugPrint("[SEVERE] Assignments 'getAll' Failed ! $e");
      return [];
    }
  }

  Future<void> save(Assignment assignment) async {
    await isar.writeTxn(() async {
      await isar.assignments.put(assignment);
      await assignment.subject.save();
    });
    return;
  }

  Future<void> markDone(Assignment assignment, bool done) async {
    await isar.writeTxn(() async {
      assignment.isMarkedAsDone = done;
      await isar.assignments.put(assignment);
    });
    return;
  }

  Future<void> delete(Assignment message) async {
    await isar.writeTxn(() async {
      await isar.assignments.delete(message.id);
    });
    return;
  }

  Stream<List<Assignment>> watchAll() {
    return isar.assignments.where().watch(fireImmediately: true).map((list) {
      for (final a in list) {
        a.subject.loadSync();
      }
      return list;
    });
  }
}
