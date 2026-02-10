import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:messagyre_client/database/repositories/assignment_repository.dart';
import 'package:messagyre_client/database/repositories/chat_repository.dart';
import 'package:messagyre_client/database/repositories/grade_repository.dart';
import 'package:messagyre_client/database/repositories/message_repository.dart';
import 'package:messagyre_client/database/repositories/subject_repository.dart';
import 'package:path_provider/path_provider.dart';

import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late final Isar _isar;

  Isar get isar => _isar;

  // #region Repositories

  late final messages = MessageRepository(_isar);
  late final chats = ChatRepository(_isar);
  late final assignments = AssignmentRepository(_isar);
  late final grades = GradeRepository(_isar);
  late final subjects = SubjectRepository(_isar);

  // #endregion

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar = Isar.openSync([SubjectSchema, AssignmentSchema, GradeSchema, ChatSchema, MessageSchema], directory: dir.path);
    } catch (e, s) {
      debugPrint("[Database Failure] Could not open Isar. $e\n\n$s");
    }
  }
}
