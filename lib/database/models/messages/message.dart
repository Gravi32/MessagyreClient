import 'package:isar_community/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:messagyre_client/database/models/assignments/assignment_share.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message_reply.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

@collection
class Message {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  /// The other person of the conversation. Messages saved before 4.84 get it at the first start (ChatService.migrate).
  @Index(composite: [CompositeIndex('sentAt')])
  String? chatUsername;

  /// Who wrote it, in a class chat (where [chatUsername] is the class, "#1M05"). Null in a conversation with one person.
  String? senderUsername;

  late String content;

  late DateTime sentAt;

  late bool isOwned;

  @enumerated
  late MessageStatus status;

  bool isDeleted = false;

  /// The photo or file sent with this message, as JSON (see [Attachment]). Null for a text message.
  String? attachmentData;

  /// An assignment sent in the chat, as JSON (see [AssignmentShare]). Null for anything else.
  String? assignmentData;

  /// The message this one answers, as JSON (see [MessageReply]). Null for a message that answers nothing.
  String? replyData;

  /// Where the decrypted photo or file is on this device, once uploaded or downloaded
  String? localPath;

  @enumerated
  TransferState transfer = TransferState.none;

  Message();

  @ignore
  Attachment? get attachment => Attachment.tryParse(attachmentData);

  @ignore
  bool get hasAttachment => attachmentData != null;

  @ignore
  AssignmentShare? get sharedAssignment => AssignmentShare.tryParse(assignmentData);

  @ignore
  MessageReply? get reply => MessageReply.tryParse(replyData);

  bool get isFailed => status == MessageStatus.Failed;

  /// The text shown in the bubble: the caption of an attachment, or the message itself
  @ignore
  String get displayText => hasAttachment ? (attachment?.caption ?? "") : content;

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
    String? chatUsername,
    String? senderUsername,
    required String content,
    required DateTime sentAt,
    required bool isOwned,
    MessageStatus status = MessageStatus.Sending,
    bool isDeleted = false,
    Attachment? attachment,
    AssignmentShare? sharedAssignment,
    MessageReply? reply,
    String? localPath,
    TransferState transfer = TransferState.none,
  }) {
    return Message()
      ..uuid = uuid ?? const Uuid().v4()
      ..chatUsername = chatUsername
      ..senderUsername = senderUsername
      ..content = content
      ..sentAt = sentAt
      ..isOwned = isOwned
      ..status = status
      ..isDeleted = isDeleted
      ..attachmentData = attachment?.toJson()
      ..assignmentData = sharedAssignment?.toJson()
      ..replyData = reply?.toJson()
      ..localPath = localPath
      ..transfer = transfer;
  }

  @override
  String toString() {
    return 'Message $id ($formattedTime)'
        '${isOwned ? ' [Owned]' : ''}'
        '${isDeleted ? ' [Deleted]' : ''}'
        '${hasAttachment ? ' [Attachment]' : ''}';
  }
}

/// The order matters: a receipt only ever moves a message forward (Sent → Delivered → Read). Failed stays last
/// (saved as its index by Isar, like the other values).
enum MessageStatus { Sending, Sent, Delivered, Read, Failed }

/// The state of a message's photo or file on this device
enum TransferState {
  /// No attachment, or nothing to do
  none,

  /// Received, not downloaded yet
  pending,
  uploading,
  downloading,

  /// The decrypted file is at localPath
  ready,

  /// The upload or download failed: it can be retried
  failed,

  /// The server doesn't have the file any more
  expired,
}
