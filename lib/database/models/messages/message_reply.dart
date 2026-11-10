import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The message a message answers ("Répondre", like WhatsApp): enough to show it above the answer and to find it in
/// the conversation. Sent inside the encrypted part of the message ("Reply" in the attachment's JSON, see
/// ChatService): the apps before 4.108 don't know it and just show the answer.
@immutable
class MessageReply {
  /// The UUID of the message answered
  final String uuid;

  /// Who wrote the message answered (a username; mine when I answer myself)
  final String sender;

  /// The beginning of its text ("📷 Photo" for a photo without a caption)
  final String text;

  const MessageReply({required this.uuid, required this.sender, required this.text});

  static const maxTextLength = 200;

  factory MessageReply.of({required String uuid, required String sender, required String text}) {
    final cleaned = text.trim().replaceAll(RegExp(r'\s+'), " ");
    return MessageReply(uuid: uuid, sender: sender, text: cleaned.length > maxTextLength ? "${cleaned.substring(0, maxTextLength)}…" : cleaned);
  }

  Map<String, dynamic> toMap() => {"Uuid": uuid, "Sender": sender, "Text": text};

  String toJson() => jsonEncode(toMap());

  static MessageReply? fromMap(Object? map) {
    if (map is! Map) return null;
    final uuid = map["Uuid"], sender = map["Sender"], text = map["Text"];
    if (uuid is! String || sender is! String || text is! String || uuid.isEmpty) return null;
    return MessageReply.of(uuid: uuid, sender: sender, text: text);
  }

  static MessageReply? tryParse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return fromMap(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  /// The JSON sent in the message's encrypted "Attachment": the attachment's or the assignment's, with the reply
  /// added ("Reply"). Null when there is nothing to send.
  static String? mergeInto(String? payloadJson, MessageReply? reply) {
    if (reply == null) return payloadJson;
    Map<String, dynamic> map = {};
    if (payloadJson != null) {
      try {
        final decoded = jsonDecode(payloadJson);
        if (decoded is Map<String, dynamic>) map = Map.of(decoded);
      } catch (_) {}
    }
    map["Reply"] = reply.toMap();
    return jsonEncode(map);
  }

  /// The reply inside a received payload, if any
  static MessageReply? fromPayload(String? payloadJson) {
    if (payloadJson == null || payloadJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(payloadJson);
      return decoded is Map ? fromMap(decoded["Reply"]) : null;
    } catch (_) {
      return null;
    }
  }
}
