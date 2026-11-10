import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:messagyre_client/database/models/assignments/assignment.dart';
import 'package:messagyre_client/database/models/composite_subjects/composite_subject.dart';
import 'package:messagyre_client/database/models/grades/grade.dart';
import 'package:messagyre_client/database/models/subjects/subject.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/notifications_service.dart';
import 'package:messagyre_client/utility/utility.dart';

/// Keeps a copy of the school data (subjects, grades, assignments, archives included, and the report's
/// settings) on the server, for the signed-in account: deleting the app or changing phone loses nothing.
///
/// - At the start, once per account on this phone, the server's copy is read before anything is sent: on a
///   new install it brings everything back. Until then nothing is uploaded, so an empty phone can't
///   overwrite the copy.
/// - Then every change is sent a few seconds later (and right away when the app goes to the background).
/// - Another account signing in on the same phone gets its own data: the previous account's was saved.
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final database = DatabaseService();
  final globals = GlobalsService();
  final network = NetworkService();

  static const _syncedForKey = "BackupSyncedFor";
  static const _uploadedHashKey = "BackupUploadedHash";
  static const _delay = Duration(seconds: 4);

  /// The settings that belong with the grades (the report's rules, the end of year and first start prompts)
  static const settingsKeys = [
    "UseDoubleCompensation",
    "UseRestrictedGroup",
    "RestrictedGroupSubjects",
    "MaxFailingSubjects",
    "SubjectsSetupDone",
    "ArchivePromptAnsweredFor",
  ];

  Isar get _isar => database.isar;

  final List<StreamSubscription> _watchers = [];
  Timer? _timer;
  Future<void>? _syncing;
  bool _uploading = false;
  bool _changedWhileUploading = false;

  /// The account whose data is on this phone and may be uploaded (null until the server's copy was read)
  String? _activeFor;

  // #region -> Syncing

  /// Reads the server's copy if this phone hasn't yet for this account, then saves the changes from now on.
  /// Without a connection it does nothing: it is called again at the next start or connection.
  Future<void> sync() => _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<void> _sync() async {
    final username = globals.username;
    if (username == null || globals.token == null) return;
    if (_activeFor == username) return;

    try {
      final syncedFor = globals.persistent.getString(_syncedForKey);
      if (syncedFor != username) {
        final response = await network.get("/backup/get", timeout: 20);
        if (response.statusCode != 200 && response.statusCode != 204) {
          debugPrint("[Backup] The saved copy couldn't be read (${response.statusCode}): trying again later");
          return;
        }
        if (globals.username != username) return; // signed out meanwhile

        final saved = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
        final data = saved is Map ? tryJsonDecode(saved["Data"]?.toString() ?? "") : null;

        // Another account's data is on this phone: it is saved on the server, this account gets its own
        final replace = syncedFor != null;
        if (data is Map<String, dynamic>) {
          final counts = await restore(data, replace: replace);
          debugPrint("[Backup] Restored ${counts.grades} grades and ${counts.assignments} assignments");
        } else if (replace) {
          await restore(const {}, replace: true);
        }

        await globals.persistent.setString(_syncedForKey, username);
        await globals.persistent.remove(_uploadedHashKey);
      }

      _activeFor = username;
      _watch();
      _schedule(Duration.zero); // the first copy of an account that had none, or what changed while offline
    } catch (e, s) {
      debugPrint("[Backup] Sync failed: $e\n$s");
    }
  }

  void _watch() {
    if (_watchers.isNotEmpty) return;
    _watchers.addAll([
      _isar.subjects.watchLazy().listen((_) => _schedule()),
      _isar.compositeSubjects.watchLazy().listen((_) => _schedule()),
      _isar.grades.watchLazy().listen((_) => _schedule()),
      _isar.assignments.watchLazy().listen((_) => _schedule()),
    ]);
  }

  void _schedule([Duration delay = _delay]) {
    _timer?.cancel();
    _timer = Timer(delay, upload);
  }

  /// Sends a pending change now (the app goes to the background, or the account signs out)
  Future<void> flush() async {
    if (_timer?.isActive != true) return;
    _timer?.cancel();
    await upload();
  }

  /// Stops saving: the account signed out (its last changes are sent first)
  Future<void> stop() async {
    await flush().timeout(const Duration(seconds: 5), onTimeout: () {});
    for (final watcher in _watchers) {
      watcher.cancel();
    }
    _watchers.clear();
    _activeFor = null;
  }

  Future<void> upload() async {
    final username = _activeFor;
    if (username == null || username != globals.username || globals.token == null) return;
    if (_uploading) {
      _changedWhileUploading = true;
      return;
    }

    _uploading = true;
    try {
      final data = jsonEncode(export());
      final hash = data.hashCode.toString();
      if (globals.persistent.getString(_uploadedHashKey) == hash) return;

      final response = await network.post("/backup/save", {"Data": data}, timeout: 60);
      if (response.statusCode == 200) {
        debugPrint("[Backup] Saved (${data.length} characters)");
        if (_activeFor == username) await globals.persistent.setString(_uploadedHashKey, hash);
      } else {
        debugPrint("[Backup] Upload failed (${response.statusCode}): trying again in a minute");
        _schedule(const Duration(minutes: 1));
      }
    } catch (e) {
      debugPrint("[Backup] Upload failed: $e");
    } finally {
      _uploading = false;
      if (_changedWhileUploading) {
        _changedWhileUploading = false;
        _schedule();
      }
    }
  }

  // #endregion

  // #region -> Export and restore

  /// Everything to save, as JSON (subjects are referred to by their code)
  Map<String, dynamic> export() {
    final subjects = _isar.subjects.where().findAllSync();
    final composites = database.compositeSubjects.getAll();
    final grades = _isar.grades.where().findAllSync();
    final assignments = _isar.assignments.where().findAllSync();
    for (final grade in grades) {
      grade.subject.loadSync();
    }
    for (final assignment in assignments) {
      assignment.subject.loadSync();
    }

    return {
      "Version": 1,
      "Subjects": subjects.map(BackupFormat.subject).toList(),
      "CompositeSubjects": composites.map(BackupFormat.composite).toList(),
      "Grades": grades.map(BackupFormat.grade).toList(),
      "Assignments": assignments.map(BackupFormat.assignment).toList(),
      "Settings": {
        for (final key in settingsKeys)
          if (globals.persistent.get(key) case final value?) key: value,
      },
    };
  }

  /// Puts a saved copy on this phone. With [replace], the school data already here goes first (another
  /// account's); otherwise the copy is added to it: subjects updated by code, grades and assignments not
  /// already here added.
  Future<({int grades, int assignments})> restore(Map<String, dynamic> data, {bool replace = false}) async {
    List<Map> listOf(String key) => [...?(data[key] as List?)?.whereType<Map>()];

    var added = (grades: 0, assignments: 0);
    final reminders = <Assignment>[];

    await _isar.writeTxn(() async {
      if (replace) {
        await _isar.grades.clear();
        await _isar.assignments.clear();
        await _isar.compositeSubjects.clear();
        await _isar.subjects.clear();
      }

      // Subjects: the saved ones win over the default ones made at the first start
      final subjectsByCode = {for (final subject in await _isar.subjects.where().findAll()) subject.code: subject};
      for (final json in listOf("Subjects")) {
        final restored = BackupFormat.toSubject(json, existing: subjectsByCode[json["Code"]]);
        if (restored == null) continue;
        await _isar.subjects.put(restored);
        subjectsByCode[restored.code] = restored;
      }

      for (final json in listOf("CompositeSubjects")) {
        final code = json["Code"];
        if (code is! String) continue;
        final composite = await _isar.compositeSubjects.filter().codeEqualTo(code).findFirst() ?? CompositeSubject();
        if (!BackupFormat.fillComposite(composite, json, subjectsByCode)) continue;
        await _isar.compositeSubjects.put(composite);
        await composite.firstSubject.save();
        await composite.secondSubject.save();
        await composite.thirdSubject.save();
      }

      final existingGrades = (await _isar.grades.where().findAll())..forEach((grade) => grade.subject.loadSync());
      final gradeKeys = existingGrades.map(BackupFormat.gradeKey).toSet();
      var gradesAdded = 0;
      for (final json in listOf("Grades")) {
        final grade = BackupFormat.toGrade(json, subjectsByCode);
        if (grade == null || !gradeKeys.add(BackupFormat.gradeKey(grade))) continue;
        await _isar.grades.put(grade);
        await grade.subject.save();
        gradesAdded++;
      }

      final existingAssignments = (await _isar.assignments.where().findAll())..forEach((assignment) => assignment.subject.loadSync());
      final assignmentKeys = existingAssignments.map(BackupFormat.assignmentKey).toSet();
      var assignmentsAdded = 0;
      for (final json in listOf("Assignments")) {
        final assignment = BackupFormat.toAssignment(json, subjectsByCode);
        if (assignment == null || !assignmentKeys.add(BackupFormat.assignmentKey(assignment))) continue;
        await _isar.assignments.put(assignment);
        await assignment.subject.save();
        assignmentsAdded++;
        if (assignment.archivedYear == null && assignment.notificationDate?.isAfter(DateTime.now()) == true) reminders.add(assignment);
      }

      added = (grades: gradesAdded, assignments: assignmentsAdded);
    });

    final settings = data["Settings"];
    if (settings is Map) {
      for (final MapEntry(:key, :value) in settings.entries) {
        if (!settingsKeys.contains(key)) continue;
        switch (value) {
          case bool value:
            await globals.persistent.setBool(key, value);
          case int value:
            await globals.persistent.setInt(key, value);
          case double value:
            await globals.persistent.setDouble(key, value);
          case String value:
            await globals.persistent.setString(key, value);
          case List value:
            await globals.persistent.setStringList(key, value.map((item) => item.toString()).toList());
        }
      }
    }

    // The reminders are notifications of this phone: scheduled again
    for (final assignment in reminders) {
      await NotificationsService().scheduleAssignmentReminder(
        assignment,
        notificationId: (assignment.referenceId ?? "").hashCode.remainder(100000),
        at: assignment.notificationDate!,
      );
    }

    return added;
  }

  // #endregion
}

/// The JSON of each saved item (kept apart from Isar: the tests check it without a database)
class BackupFormat {
  static Map<String, dynamic> subject(Subject subject) => {
    "Code": subject.code,
    "Name": subject.name,
    "Icon": subject.iconCodePoint,
    "Color": subject.colorValue,
    "IsLocked": subject.isLocked,
    "LockedGrade": subject.lockedGrade,
    "LockedYear": subject.lockedYear,
  };

  static Subject? toSubject(Map json, {Subject? existing}) {
    final code = json["Code"], name = json["Name"];
    if (code is! String || name is! String) return null;
    return (existing ?? Subject())
      ..code = code
      ..name = name
      ..iconCodePoint = _int(json["Icon"])
      ..colorValue = _int(json["Color"])
      ..isLocked = json["IsLocked"] == true
      ..lockedGrade = _double(json["LockedGrade"])
      ..lockedYear = json["LockedYear"] as String?;
  }

  static Map<String, dynamic> composite(CompositeSubject composite) => {
    "Code": composite.code,
    "Name": composite.name,
    "Parts": [
      for (final part in composite.parts) {"Subject": part.subject.code, "Periods": part.periods},
    ],
  };

  /// Fills [composite] from [json]; false when two of its subjects are missing
  static bool fillComposite(CompositeSubject composite, Map json, Map<String, Subject> subjectsByCode) {
    final name = json["Name"];
    final parts = [
      for (final part in (json["Parts"] as List? ?? const []).whereType<Map>())
        if (subjectsByCode[part["Subject"]] case final subject?) (subject: subject, periods: _double(part["Periods"]) ?? 1),
    ];
    if (name is! String || parts.length < 2) return false;

    composite
      ..code = json["Code"] as String
      ..name = name
      ..firstSubjectPeriodsPerWeek = parts[0].periods
      ..secondSubjectPeriodsPerWeek = parts[1].periods
      ..thirdSubjectPeriodsPerWeek = parts.length > 2 ? parts[2].periods : 0;
    composite.firstSubject.value = parts[0].subject;
    composite.secondSubject.value = parts[1].subject;
    composite.thirdSubject.value = parts.length > 2 ? parts[2].subject : null;
    return true;
  }

  static Map<String, dynamic> grade(Grade grade) => {
    "Subject": grade.subject.value?.code,
    "Title": grade.title,
    "Grade": grade.grade,
    "Date": grade.date.toUtc().toIso8601String(),
    "Details": grade.details,
    "Weight": grade.weight,
    "Group": grade.groupName,
    "ReferenceId": grade.referenceId,
    "ArchivedYear": grade.archivedYear,
  };

  static Grade? toGrade(Map json, Map<String, Subject> subjectsByCode) {
    final title = json["Title"], value = _double(json["Grade"]), date = DateTime.tryParse(json["Date"]?.toString() ?? "");
    if (title is! String || value == null || date == null) return null;
    final grade = Grade()
      ..title = title
      ..grade = value
      ..date = date.toLocal()
      ..details = json["Details"] as String?
      ..weight = _double(json["Weight"]) ?? 1
      ..groupName = json["Group"] as String?
      ..referenceId = json["ReferenceId"] as String?
      ..archivedYear = json["ArchivedYear"] as String?;
    grade.subject.value = subjectsByCode[json["Subject"]];
    return grade;
  }

  static Map<String, dynamic> assignment(Assignment assignment) => {
    "Subject": assignment.subject.value?.code,
    "Title": assignment.title,
    "Content": assignment.content,
    "Done": assignment.isMarkedAsDone,
    "Shared": assignment.isShared,
    "DueDate": assignment.dueDate.toUtc().toIso8601String(),
    "NotificationDate": assignment.notificationDate?.toUtc().toIso8601String(),
    "ReferenceId": assignment.referenceId,
    "ArchivedYear": assignment.archivedYear,
    "Type": assignment.type.name,
  };

  static Assignment? toAssignment(Map json, Map<String, Subject> subjectsByCode) {
    final dueDate = DateTime.tryParse(json["DueDate"]?.toString() ?? "");
    if (dueDate == null) return null;
    final assignment = Assignment()
      ..title = json["Title"] as String?
      ..content = json["Content"] as String? ?? ""
      ..isMarkedAsDone = json["Done"] == true
      ..isShared = json["Shared"] != false
      ..dueDate = dueDate.toLocal()
      ..notificationDate = DateTime.tryParse(json["NotificationDate"]?.toString() ?? "")?.toLocal()
      ..referenceId = json["ReferenceId"] as String?
      ..archivedYear = json["ArchivedYear"] as String?
      ..type = AssignmentType.values.firstWhere((type) => type.name == json["Type"], orElse: () => AssignmentType.assignment);
    assignment.subject.value = subjectsByCode[json["Subject"]];
    return assignment;
  }

  /// What makes two grades the same one (a grade restored twice is added once). Not the reference: it is the
  /// test the grade belongs to, shared by its grades.
  static String gradeKey(Grade grade) =>
      "${grade.subject.value?.code}|${grade.title}|${grade.date.millisecondsSinceEpoch}|${grade.grade}|${grade.weight}";

  /// An assignment's reference is its own UUID
  static String assignmentKey(Assignment assignment) =>
      assignment.referenceId ??
      "${assignment.subject.value?.code}|${assignment.title}|${assignment.content}|${assignment.dueDate.millisecondsSinceEpoch}|${assignment.type.name}";

  static int? _int(Object? value) => value is num ? value.toInt() : null;
  static double? _double(Object? value) => value is num ? value.toDouble() : null;
}
