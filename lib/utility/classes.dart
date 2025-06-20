import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messagyre_client/utility/utility.dart';

part 'classes.g.dart';

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  String content;

  @HiveField(1)
  DateTime sentAt;

  @HiveField(2)
  bool isOwned;

  Message({required this.content, required this.sentAt, required this.isOwned});

  factory Message.fromMessageData(Map<String, dynamic> messageData) {
    return Message(
      content: messageData["Content"],
      sentAt: messageData["SentAt"],
      isOwned: false,
    );
  }

  String pack(String recipientUsername) {
    var data = {
      "RecipientUsername": recipientUsername,
      "Content": content,
      "SentAt": sentAt,
    };

    return jsonEncode(data);
  }

  @override
  String toString() =>
      "[Message] $content (${sentAt.hour}:${sentAt.minute}, owned: $isOwned)";
}

@HiveType(typeId: 1)
class Chat {
  @HiveField(0)
  String recipientUsername;

  @HiveField(1)
  List<Message> content = [];

  @HiveField(2)
  int unreadMessages = 0;

  Chat({required this.recipientUsername});

  @override
  String toString() =>
      "[$recipientUsername's chat] messages: ${content.length}";
}

class Account {
  late String username;
  late String emailAddress;
  late String? classOrRole;
  late DateTime? creationDate;
  late DateTime? lastLogin;
  late Map<String, dynamic>? profile;

  void format() {
    
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
      debugPrintStack(
        stackTrace: stack,
        label: "Account.fromJson error: $e\nsource: $source",
      );
      return null;
    }
  }

  static Account? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;

    try {
      return Account()
        ..username = map["Username"] ?? "unknown"
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

  static String getDisplayableUsername(String username) {
    return username.replaceAll('.', ' ').capitalize();
  }

  @override
  String toString() {
    String profileString = "";
    profile?.forEach((key, value) => profileString += "\n\t\t$key: $value");
    return "[Account: $username]\n\tEmail: $emailAddress\n\tProfile: {$profileString\n}\n";
  }
}
