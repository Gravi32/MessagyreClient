import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:messagyre_client/database/models/subjects/subject.dart' as isar_subject;
import 'package:messagyre_client/database/models/assignments/assignment.dart' as isar_assignment;
import 'package:messagyre_client/database/models/grades/grade.dart' as isar_grade;
import 'package:messagyre_client/database/models/chats/chat.dart' as isar_chat;
import 'package:messagyre_client/database/models/messages/message.dart' as isar_message;

import 'package:messagyre_client/utility/classes.dart'; // Hive classes
import 'package:messagyre_client/utility/subjects.dart'; // enum Subject

Future<void> migrateHiveToIsar(Isar isar) async {
  final subjectMap = <Subject, isar_subject.Subject>{};

  debugPrint("Starting Hive → Isar migration...");

  // --- SUBJECTS ---
  debugPrint("Migrating subjects...");
  await isar.writeTxn(() async {
    for (final s in Subject.values) {
      final subj =
          isar_subject.Subject()
            ..code = s.name
            ..name = SubjectHelper.toFrench(s);
      await isar.subjects.put(subj);
      subjectMap[s] = subj;
    }
  });
  debugPrint("Subjects migrated: ${subjectMap.length}");

  // --- ASSIGNMENTS ---
  final assignmentBox = Hive.box<Assignment>("Homework");
  debugPrint("Migrating assignments...");
  await isar.writeTxn(() async {
    int count = 0;
    for (final old in assignmentBox.values) {
      final a =
          isar_assignment.Assignment()
            ..title = old.title
            ..content = old.content
            ..dueDate = old.dueDate
            ..creationDate = old.creationDate
            ..isGraded = old.isGraded
            ..isTest = old.isTest
            ..isMarkedAsDone = old.isMarkedAsDone
            ..referenceId = old.referenceId
            ..calendarEventId = old.calendarEventId;

      a.subject.value = subjectMap[old.subject];
      await isar.assignments.put(a);
      await a.subject.save();

      count++;
      if (count % 10 == 0) debugPrint("  Migrated $count assignments...");
    }
    debugPrint("Total assignments migrated: $count");
  });

  // --- GRADES ---
  final gradeBox = Hive.box<Grade>("Grades");
  debugPrint("Migrating grades...");
  await isar.writeTxn(() async {
    int count = 0;
    for (final old in gradeBox.values) {
      final g =
          isar_grade.Grade()
            ..title = old.title
            ..grade = old.grade
            ..date = old.date
            ..details = old.details
            ..weight = old.weight
            ..groupName = old.groupName
            ..referenceId = old.referenceId;

      g.subject.value = subjectMap[old.subject];
      await isar.grades.put(g);
      await g.subject.save();

      count++;
      if (count % 10 == 0) debugPrint("  Migrated $count grades...");
    }
    debugPrint("Total grades migrated: $count");
  });

  // --- CHATS & MESSAGES ---
  final chatBox = Hive.box<Chat>("Chats");
  debugPrint("Migrating chats and messages...");
  await isar.writeTxn(() async {
    int chatCount = 0;
    for (final oldChat in chatBox.values) {
      final chat =
          isar_chat.Chat()
            ..recipientUsername = oldChat.recipientUsername
            ..recipientDisplayUsername = oldChat.recipientDisplayUsername
            ..unreadMessages = oldChat.unreadMessages
            ..isPinned = oldChat.isPinned;

      await isar.chats.put(chat);

      int messageCount = 0;
      for (final oldMessage in oldChat.content) {
        final message =
            isar_message.Message()
              ..content = oldMessage.content
              ..sentAt = oldMessage.sentAt
              ..isOwned = oldMessage.isOwned
              ..status = isar_message.MessageStatus.values[oldMessage.status.index]
              ..isDeleted = oldMessage.isDeleted;

        await isar.messages.put(message);
        chat.messages.add(message);

        messageCount++;
        if (messageCount % 20 == 0) debugPrint("    Migrated $messageCount messages in chat ${chat.recipientUsername}...");
      }

      await chat.messages.save();
      chatCount++;
      if (chatCount % 5 == 0) debugPrint("  Migrated $chatCount chats...");
    }
    debugPrint("Total chats migrated: $chatCount");
  });

  debugPrint("Migration completed successfully.");
}
