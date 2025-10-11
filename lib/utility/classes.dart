import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/subjects.dart';
import 'package:messagyre_client/utility/utility.dart';

part 'classes.g.dart';

@HiveType(typeId: 0)
class Message extends HiveObject {
  @HiveField(0)
  String content;

  @HiveField(1)
  DateTime sentAt;

  @HiveField(2)
  bool isOwned;

  @HiveField(4)
  int _status;

  late ValueNotifier<int> statusNotifier;

  Message({required this.content, required this.sentAt, required this.isOwned, int status = 0}) : _status = status {
    statusNotifier = ValueNotifier<int>(_status);
  }

  set status(int value) {
    _status = value;
    statusNotifier.value = value;
    if (isInBox) {
      save();
    }
  }

  int get status => _status;

  factory Message.fromMessageData(Map<String, dynamic> messageData) {
    try {
      return Message(content: messageData["Content"], sentAt: messageData["SentAt"], isOwned: false);
    } catch (e) {
      debugPrint("[Classes.dart] Message could not be created: $e");
      throw Exception();
    }
  }

  void initNotifier() {
    statusNotifier = ValueNotifier<int>(_status);
  }

  String pack(String recipientUsername) {
    final data = {"RecipientUsername": recipientUsername, "Content": content, "SentAt": sentAt.toIso8601String(), "Status": status};
    return jsonEncode(data);
  }
}

@HiveType(typeId: 1)
class Chat extends HiveObject {
  @HiveField(0)
  String recipientUsername;

  @HiveField(1)
  List<Message> content = [];

  @HiveField(2)
  int unreadMessages = 0;

  @HiveField(3)
  String? recipientDisplayUsername;

  @HiveField(4)
  bool isPinned = false;

  Chat({required this.recipientUsername});

  @override
  String toString() => "[$recipientUsername's chat] messages: ${content.length}";
}

@HiveType(typeId: 2)
class Homework extends HiveObject {
  @HiveField(0)
  Subject subject = Subject.Maths;

  @HiveField(1)
  String content = "Exercices";

  @HiveField(2)
  DateTime dueDate = DateTime.now().add(Duration(days: 1));

  @HiveField(3)
  DateTime creationDate = DateTime.now();

  @HiveField(4)
  bool isGraded = false;

  @HiveField(5)
  bool isTest = false;

  @HiveField(6)
  bool isMarkedAsDone = false;
}

// Subject uses HiveType 3

@HiveType(typeId: 4)
class Grade extends HiveObject {
  @HiveField(0)
  Subject subject = Subject.Maths;

  @HiveField(1)
  String title = "Test sans titre";

  @HiveField(2)
  double grade = 4;

  @HiveField(3)
  DateTime date = DateTime.now();

  @HiveField(4)
  String? details;

  @HiveField(5)
  double weight = 1;

  @HiveField(6)
  String? groupName;
}

@HiveType(typeId: 5)
class Settings extends HiveObject {
  // Homework page
  @HiveType(typeId: 0)
  bool includeWeekends = false;
}

class Account {
  late String username;
  late String? displayName;
  late String emailAddress;
  late String? classOrRole;
  late DateTime? creationDate;
  late DateTime? lastLogin;
  late Map<String, dynamic>? profile;

  String get defaultDisplayName => getDefaultDisplayName(username);

  static String getDefaultDisplayName(String fromUsername) {
    return fromUsername.replaceAll('.', ' ').capitalize(everyWord: true);
  }

  static Account? fromJson(String? source) {
    if (source == null || source.trim().isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        debugPrint("Account.fromJson error: JSON is not a valid map.");
        return null;
      }
      return fromMap(decoded);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: "Account.fromJson error: $e\nsource: $source");
      return null;
    }
  }

  static Account? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    try {
      return Account()
        ..username = map["Username"] ?? "unknown"
        ..displayName = map["DisplayName"]
        ..emailAddress = map["EmailAddress"] ?? "unknown"
        ..classOrRole = map["ClassOrRole"]
        ..creationDate = DateTime.tryParse(map["CreationDate"] ?? "")
        ..lastLogin = DateTime.tryParse(map["LastLogin"] ?? "")
        ..profile = _parseProfile(map["Profile"]);
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack, label: "Account.fromMap error: $e");
      return null;
    }
  }

  static Map<String, dynamic> _parseProfile(dynamic data) {
    if (data == null) return {};

    if (data is String) {
      if (data.trim().isEmpty) return {};
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        debugPrint("[classes.dart] Account Parse Error: $e");
        return {};
      }
    }

    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  @override
  String toString() {
    String profileString = "";
    profile?.forEach((key, value) => profileString += "\n\t\t$key: $value");
    return "[Account: $username]\n\tEmail: $emailAddress\n\tProfile: {$profileString\n}\n";
  }
}
