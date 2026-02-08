import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  late String content;
  late DateTime sentAt;
  late bool isOwned;

  @enumerated
  late MessageStatus status;

  bool isDeleted = false;

  Message();

  bool get isFailed => status == MessageStatus.Failed;

  String get formattedTime =>
      sentAt.toIso8601String().split('.').first;

  factory Message.fromMessageData(Map<String, dynamic> data) {
    try {
      return Message()
        ..content = data['Content']
        ..sentAt = DateTime.parse(data['SentAt'])
        ..isOwned = false
        ..status = MessageStatus.Delivered;
    } catch (e) {
      debugPrint('[Message] creation failed: $e');
      rethrow;
    }
  }

  factory Message.empty() {
    return Message()
      ..content = ''
      ..sentAt = DateTime.fromMillisecondsSinceEpoch(0)
      ..isOwned = false
      ..status = MessageStatus.Sending;
  }

  String pack(String recipientUsername) {
    return jsonEncode({
      'RecipientUsername': recipientUsername,
      'Content': content,
      'SentAt': sentAt.toIso8601String(),
      'Status': status.index,
    });
  }

  @override
  String toString() {
    return 'Message $id ($formattedTime)'
        '${isOwned ? ' [Owned]' : ''}'
        '${isDeleted ? ' [Deleted]' : ''}: $content';
  }
}

enum MessageStatus {
  Sending,
  Sent,
  Delivered,
  Read,
  Failed,
}
