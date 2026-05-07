import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/repositories/assignment_repository.dart';
import 'package:messagyre_client/database/repositories/chat_repository.dart';
import 'package:messagyre_client/database/repositories/composite_subject_repository.dart';
import 'package:messagyre_client/database/repositories/grade_repository.dart';
import 'package:messagyre_client/database/repositories/message_repository.dart';
import 'package:messagyre_client/database/repositories/subject_repository.dart';
import 'package:path/path.dart';
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

  Isar? _isar;

  Isar get isar => _isar!;

  late MessageRepository messages;
  late ChatRepository chats;
  late AssignmentRepository assignments;
  late GradeRepository grades;
  late SubjectRepository subjects;
  late CompositeSubjectRepository compositeSubjects;

  Future<void> initialize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar =
          Isar.getInstance() ??
          Isar.openSync([SubjectSchema, AssignmentSchema, GradeSchema, ChatSchema, MessageSchema, CompositeSubjectSchema], directory: dir.path);

      messages = MessageRepository(_isar!);
      chats = ChatRepository(_isar!);
      assignments = AssignmentRepository(_isar!);
      grades = GradeRepository(_isar!);
      subjects = SubjectRepository(_isar!);
      compositeSubjects = CompositeSubjectRepository(_isar!);
    } catch (e, s) {
      debugPrint("[Database Failure] $e\n$s");
    }
  }

  Future<void> saveBackup() async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = join(tempDir.path, 'MessagyreTemporaryBackup.isar');
    final tempFile = File(tempPath);

    if (await tempFile.exists()) await tempFile.delete();

    await _isar!.copyToFile(tempPath);
    final bytes = await tempFile.readAsBytes();

    await FilePicker.platform.saveFile(
      dialogTitle: 'Choisir où enregistrer les données',
      fileName: 'MessagyreBackup-${DateTime.now().toIso8601String()}.isar',
      bytes: bytes,
    );

    await tempFile.delete();
  }

  Future<void> loadBackup() async {
    final dir = await getApplicationDocumentsDirectory();

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['isar']);

      if (result == null || result.files.single.path == null) return;

      final backupFilePath = result.files.single.path!;
      final dbPath = join(dir.path, 'default.isar');

      if (_isar != null && _isar!.isOpen) {
        await _isar!.close();
      }

      await File(backupFilePath).copy(dbPath);

      _isar = await Isar.open([SubjectSchema, AssignmentSchema, GradeSchema, ChatSchema, MessageSchema, CompositeSubjectSchema], directory: dir.path);

      await initialize();
    } catch (e) {
      debugPrint("Restore Error: $e");

      if (Isar.getInstance() == null) {
        _isar = await Isar.open([SubjectSchema, AssignmentSchema, GradeSchema, ChatSchema, MessageSchema, CompositeSubjectSchema], directory: dir.path);
        await initialize();
      }

      rethrow;
    }
  }
}
