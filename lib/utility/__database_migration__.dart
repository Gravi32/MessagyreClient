import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';

import 'package:messagyre_client/database/models/subjects/subject.dart' as isar_subject;
import 'package:messagyre_client/database/models/assignments/assignment.dart' as isar_assignment;
import 'package:messagyre_client/database/models/grades/grade.dart' as isar_grade;
import 'package:messagyre_client/database/models/chats/chat.dart' as isar_chat;
import 'package:messagyre_client/database/models/messages/message.dart' as isar_message;
import 'package:messagyre_client/services/database_service.dart';

import 'package:messagyre_client/utility/classes.dart'; // Hive classes
import 'package:messagyre_client/utility/subjects.dart'; // enum Subject

Future<void> migrateHiveToIsar() async {
  final database = DatabaseService().isar;
  final subjectMap = <Subject, isar_subject.Subject>{};
  final errors = <String, String>{};

  void logError(String key, Object e) {
    errors[key] = e.toString();
  }

  debugPrint("Starting Hive → database migration...");

  // #region -> ASSIGNMENTS
  final assignmentBox = Hive.box<Assignment>("Homework");
  debugPrint("Migrating assignments...");
  await database.writeTxn(() async {
    int count = 0;
    for (final old in assignmentBox.values) {
      try {
        final existing = await database.assignments.filter().referenceIdEqualTo(old.referenceId ?? '').findFirst();
        final a =
            existing ?? isar_assignment.Assignment()
              ..title = old.title
              ..content = old.content
              ..dueDate = old.dueDate
              ..isGraded = old.isGraded
              ..isTest = old.isTest
              ..isMarkedAsDone = old.isMarkedAsDone
              ..referenceId = old.referenceId
              ..calendarEventId = old.calendarEventId;

        a.subject.value = subjectMap[old.subject];

        if (existing == null) {
          try {
            await database.assignments.put(a);
            await a.subject.save();
          } on IsarError catch (e) {
            if (e.message.contains('Unique index violated')) {
              debugPrint("Assignment ${a.title} already exists, skipping...");
            } else {
              rethrow;
            }
          }
        }

        count++;
      } catch (e) {
        logError("Assignment ${old.title}", e);
      }
    }
    debugPrint("Total assignments migrated: $count");
  });
  // #endregion

  // #region -> GRADES
  final gradeBox = Hive.box<Grade>("Grades");
  debugPrint("Migrating grades...");
  await database.writeTxn(() async {
    int count = 0;
    for (final old in gradeBox.values) {
      try {
        final existing = await database.grades.filter().referenceIdEqualTo(old.referenceId ?? '').findFirst();
        final g =
            existing ?? isar_grade.Grade()
              ..title = old.title
              ..grade = old.grade
              ..date = old.date
              ..details = old.details
              ..weight = old.weight
              ..groupName = old.groupName
              ..referenceId = old.referenceId;

        g.subject.value = subjectMap[old.subject];

        if (existing == null) {
          try {
            await database.grades.put(g);
            await g.subject.save();
          } on IsarError catch (e) {
            if (e.message.contains('Unique index violated')) {
              debugPrint("Grade ${g.title} already exists, skipping...");
            } else {
              rethrow;
            }
          }
        }

        count++;
      } catch (e) {
        logError("Grade ${old.title}", e);
      }
    }
    debugPrint("Total grades migrated: $count");
  });
  // #endregion

  // #region -> SUBJECTS
  debugPrint("Migrating subjects...");
  final List<Subject> usedSubjects = [];
  for (final assignment in assignmentBox.values) {
    if (!usedSubjects.contains(assignment.subject)) usedSubjects.add(assignment.subject);
  }
  for (final grade in gradeBox.values) {
    if (!usedSubjects.contains(grade.subject)) usedSubjects.add(grade.subject);
  }

  await database.writeTxn(() async {
    for (final s in usedSubjects) {
      try {
        final existing = await database.subjects.filter().codeEqualTo(s.name).findFirst();
        final subj =
            existing ?? isar_subject.Subject()
              ..code = s.name
              ..name = SubjectHelper.toFrench(s);

        if (existing == null) {
          try {
            await database.subjects.put(subj);
          } on IsarError catch (e) {
            if (e.message.contains('Unique index violated')) {
              debugPrint("Subject ${subj.code} already exists, skipping...");
            } else {
              rethrow;
            }
          }
        }
        subjectMap[s] = subj;
      } catch (e) {
        logError("Subject ${s.name}", e);
      }
    }
  });
  debugPrint("Subjects migrated: ${subjectMap.length}");
  // #endregion

  // #region -> CHATS & MESSAGES
  final chatBox = Hive.box<Chat>("Chats");
  debugPrint("Migrating chats and messages...");

  for (final oldChat in chatBox.values) {
    try {
      final existingChat = await database.chats.filter().usernameEqualTo(oldChat.recipientUsername).findFirst();
      final chat =
          existingChat ?? isar_chat.Chat()
            ..username = oldChat.recipientUsername
            ..displayUsername = oldChat.recipientDisplayUsername
            ..unreadMessages = oldChat.unreadMessages
            ..isPinned = oldChat.isPinned;

      if (existingChat == null) {
        await database.writeTxn(() async {
          await database.chats.put(chat);
        });
      }

      for (final oldMessage in oldChat.content) {
        try {
          final message =
              isar_message.Message()
                ..uuid = oldMessage.id
                ..content = oldMessage.content
                ..sentAt = oldMessage.sentAt
                ..isOwned = oldMessage.isOwned
                ..status = isar_message.MessageStatus.values[oldMessage.status.index]
                ..isDeleted = oldMessage.isDeleted;

          await database.writeTxn(() async {
            await database.messages.put(message);
            chat.messages.add(message);
            await chat.messages.save();
          });
        } catch (e) {
          logError("Message in chat ${oldChat.recipientUsername}", e);
        }
      }
    } catch (e) {
      logError("Chat ${oldChat.recipientUsername}", e);
    }
  }
  // #endregion

  // #region -> SUMMARY
  if (errors.isEmpty) {
    debugPrint("Migration completed successfully.");
  } else {
    debugPrint("Migration completed with errors:");
    errors.forEach((key, value) {
      debugPrint(" - $key: $value");
    });
  }
  // #endregion
}
