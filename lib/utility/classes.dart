import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'classes.g.dart';

class Signal {
  SignalType type;
  Map<String, String> data;

  Signal({required this.type, Map<String, String>? data}) : data = data ?? {};

  static Signal? unpack(String source) {
    try {
      final map = jsonDecode(source);
      return Signal(
        type: SignalType.values[map['Type']],
        data: Map<String, String>.from(map['Data']),
      );
    } catch (e) {
      debugPrint("[!] Received invalid JSON: $source");
      return null;
    }
  }

  String pack() {
    return jsonEncode({'Type': type.index, 'Data': data});
  }

  @override
  String toString() => "[${type.name} Signal] $data";
}

enum SignalType { Login, Registration, Logout, Message, Search }

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  String content;
  
  @HiveField(1)
  DateTime sentAt;

  @HiveField(2)
  bool isOwned;

  Message({required this.content, required this.sentAt, required this.isOwned});

  static Message? fromSignal(Signal signal) {
    var messageContent = signal.data["Content"];
    var messageSentAt = signal.data["SentAt"];

    if (messageContent == null || messageSentAt == null) {
      return null;
    }

    return Message(
      content: messageContent,
      sentAt: DateTime.parse(messageSentAt),
      isOwned: false,
    );
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
  String username;
  String? className;
  bool isTeacher;

  Account({required this.username, this.className, this.isTeacher = false});
}