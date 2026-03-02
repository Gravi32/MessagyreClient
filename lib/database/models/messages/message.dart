import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String content;

  late DateTime sentAt;

  late bool isOwned;

  @enumerated
  late MessageStatus status;

  bool isDeleted = false;

  Message();

  bool get isFailed => status == MessageStatus.Failed;

  String get formattedTime => sentAt.toIso8601String().split('.').first;

  factory Message.fromMessageData(Map<String, dynamic> data) {
    try {
      return Message()
        ..uuid = data['ID'] ?? const Uuid().v4()
        ..content = data['Content']
        ..sentAt = data['SentAt']
        ..isOwned = false
        ..status = MessageStatus.Delivered;
    } catch (e) {
      debugPrint('[Message] creation failed: $e');
      rethrow;
    }
  }

  factory Message.empty() {
    return Message()
      ..uuid = const Uuid().v4()
      ..content = ''
      ..sentAt = DateTime.fromMillisecondsSinceEpoch(0)
      ..isOwned = false
      ..status = MessageStatus.Sending;
  }

  factory Message.custom({
    String? uuid,
    required String content,
    required DateTime sentAt,
    required bool isOwned,
    MessageStatus status = MessageStatus.Sending,
    bool isDeleted = false,
  }) {
    return Message()
      ..uuid = uuid ?? Uuid().v4()
      ..content = content
      ..sentAt = sentAt
      ..isOwned = isOwned
      ..status = status
      ..isDeleted = isDeleted;
  }

  String pack(String recipientUsername) {
    return jsonEncode({'RecipientUsername': recipientUsername, 'Content': content, 'SentAt': sentAt.toIso8601String(), 'Status': status.index, 'ID': uuid});
  }

  @override
  String toString() {
    return 'Message $id ($formattedTime)'
        '${isOwned ? ' [Owned]' : ''}'
        '${isDeleted ? ' [Deleted]' : ''}: $content';
  }
}

enum MessageStatus { Sending, Sent, Delivered, Read, Failed }
