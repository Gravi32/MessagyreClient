import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/database/models/messages/message_reply.dart';
import 'package:messagyre_client/services/chat_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';

/// What the server says about me in the global chat (GET /global/status)
@immutable
class GlobalChatStatus {
  /// Its notifications are off
  final bool isMuted;

  /// Why I can't write (reported by several people), or null
  final String? cantWrite;
  final bool isBanned;

  const GlobalChatStatus({this.isMuted = false, this.cantWrite, this.isBanned = false});
}

/// The global chat ("Conversation générale"): one conversation with every Messagyre user. It isn't end-to-end
/// encrypted (everyone reads it): the server keeps it 30 days, limits the spam and moderates it (see the server's
/// GlobalChatService). Its messages are saved on the phone like the others, in the chat "@general".
///
/// At every connection the app joins it ("GlobalJoin": the new messages arrive live) and reads the ones it missed.
class GlobalChatService {
  static final GlobalChatService _instance = GlobalChatService._internal();
  factory GlobalChatService() => _instance;
  GlobalChatService._internal();

  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  static const chatId = "@general";
  static const title = "Conversation générale";
  static bool isGlobal(String? chat) => chat == chatId;

  /// Rules shown in the chat and in its information sheet
  static const rules =
      "Ouverte à tous les utilisateurs de Messagyre : les messages ne sont *pas chiffrés de bout en bout* et sont gardés 30 jours. "
      "Pas de spam (un message toutes les 3 secondes au plus), pas de fichiers, et les photos s'affichent floutées. "
      "Une personne signalée par *3 personnes* ne peut plus écrire pendant 3 jours ; par *5 personnes*, elle est exclue.";

  final status = ValueNotifier<GlobalChatStatus>(const GlobalChatStatus());

  /// Why a message was refused by the server (spam, sanction...), by UUID: the chat shows it
  final rejections = StreamController<({String uuid, String reason})>.broadcast();

  static const _namesKey = "GlobalChatNames";
  static const _syncedKey = "GlobalChatSyncedOnce";
  Map<String, String>? _names;

  // #region -> Names

  /// The display names of the people who wrote, kept on the phone (they come with each message)
  Map<String, String> get _nameMap => _names ??= () {
    try {
      final decoded = jsonDecode(globals.persistent.getString(_namesKey) ?? "{}");
      return decoded is Map ? {for (final MapEntry(:key, :value) in decoded.entries) key.toString(): value.toString()} : <String, String>{};
    } catch (_) {
      return <String, String>{};
    }
  }();

  String displayNameOf(String username) => _nameMap[username] ?? Account.getDefaultDisplayName(username);

  Future<void> _rememberName(String username, String? name) async {
    if (name == null || name.trim().isEmpty || _nameMap[username] == name) return;
    _nameMap[username] = name.trim();
    await globals.persistent.setString(_namesKey, jsonEncode(_nameMap));
  }

  // #endregion

  // #region -> Connection

  /// The conversation is in the list from the first start, pinned
  Future<Chat> ensureChat() async {
    final existing = database.chats.getByUsername(chatId);
    if (existing != null) return existing;
    final chat = Chat.custom(username: chatId, displayUsername: title)..isPinned = true;
    await database.chats.save(chat);
    return chat;
  }

  /// At every connection: joins the live chat, reads what was missed, and my status
  Future<void> onConnected() async {
    if (globals.username == null) return;
    network.sendRaw({"CommunicationType": "GlobalJoin"});
    await ensureChat();
    await Future.wait([sync(), refreshStatus()]);
  }

  /// The messages written since the newest one on this phone (the last 30 days the first time)
  Future<void> sync() async {
    try {
      final newest = database.messages.ofChat(chatId).where((message) => message.status != MessageStatus.Sending && message.status != MessageStatus.Failed).lastOrNull;
      final after = newest?.sentAt.toUtc().toIso8601String();
      final response = await network.get("/global/messages?Limit=200${after == null ? "" : "&After=${Uri.encodeQueryComponent(after)}"}", timeout: 20);
      if (response.statusCode != 200) {
        debugPrint("[Global] The messages couldn't be read: ${response.statusCode}");
        return;
      }
      final data = tryJsonDecode(response.body);
      if (data is! List) return;
      // The first time, the history isn't counted as unread
      final firstTime = globals.persistent.getBool(_syncedKey) != true;
      for (final item in data.whereType<Map>()) {
        await _onMessage(Map<String, dynamic>.from(item), live: false, countAsUnread: !firstTime);
      }
      await globals.persistent.setBool(_syncedKey, true);
    } catch (e) {
      debugPrint("[Global] Syncing failed: $e");
    }
  }

  Future<void> refreshStatus() async {
    try {
      final response = await network.get("/global/status", timeout: 10);
      final data = response.statusCode == 200 ? tryJsonDecode(response.body) : null;
      if (data is! Map) return;
      status.value = GlobalChatStatus(isMuted: data["Muted"] == true, cantWrite: data["CantWrite"] as String?, isBanned: data["Banned"] == true);
    } catch (e) {
      debugPrint("[Global] The status couldn't be read: $e");
    }
  }

  /// Turns its notifications off ([muted]) or on. Returns why it failed (null when it worked)
  Future<String?> setMuted(bool muted) async {
    final response = await network.post("/global/notifications", {"Muted": muted});
    if (response.statusCode != 200) return AppStrings.errorFor(response);
    status.value = GlobalChatStatus(isMuted: muted, cantWrite: status.value.cantWrite, isBanned: status.value.isBanned);
    return null;
  }

  // #endregion

  // #region -> Receiving

  Future<void> handleCommunication(Map<String, dynamic> data) async {
    switch (data["CommunicationType"]) {
      case "GlobalMessage":
        await _onMessage(data, live: true, countAsUnread: true);
      case "GlobalDeletion":
        final uuids = data["Uuids"];
        if (uuids is List) await _removeAll(uuids.map((uuid) => uuid.toString()).toList());
      case "GlobalRejected":
        final uuid = data["Uuid"]?.toString();
        final reason = data["Reason"]?.toString() ?? "Le serveur a refusé ce message.";
        if (uuid == null) return;
        await database.messages.update(uuid, (m) => m.status = MessageStatus.Failed);
        rejections.add((uuid: uuid, reason: reason));
        unawaited(refreshStatus());
      case "GlobalStatus":
        await refreshStatus();
    }
  }

  Future<void> _onMessage(Map<String, dynamic> data, {required bool live, required bool countAsUnread}) async {
    final uuid = data["Uuid"]?.toString();
    final sender = data["SenderUsername"]?.toString();
    if (uuid == null || sender == null) return;

    if (data["Deleted"] == true) {
      await _removeAll([uuid]);
      return;
    }
    await _rememberName(sender, data["SenderName"]?.toString());

    final isMine = sender == globals.username;
    if (isMine) {
      // My own message coming back: already on the phone (sent from here), or written on another phone
      final mine = database.messages.getByUuid(uuid);
      if (mine != null) {
        if (mine.status == MessageStatus.Sending || mine.status == MessageStatus.Failed) await database.messages.update(uuid, (m) => m.status = MessageStatus.Sent);
        return;
      }
    }
    if (globals.blockedUsers.contains(sender)) return;

    final photo = data["Photo"];
    Attachment? attachment;
    if (photo is Map && photo["ID"] is String) {
      attachment = Attachment(
        kind: AttachmentKind.image,
        fileId: photo["ID"] as String,
        key: "",
        iv: "",
        name: "photo.jpg",
        mimeType: "image/jpeg",
        size: 0,
        width: (photo["Width"] as num?)?.toInt(),
        height: (photo["Height"] as num?)?.toInt(),
        caption: (data["Content"]?.toString().trim().isNotEmpty ?? false) ? data["Content"].toString().trim() : null,
        isPublic: true,
      );
    }
    final content = data["Content"]?.toString() ?? "";

    final message = Message.custom(
      uuid: uuid,
      chatUsername: chatId,
      senderUsername: isMine ? null : sender,
      content: attachment != null ? attachment.previewText : content,
      sentAt: DateTime.tryParse(data["SentAt"]?.toString() ?? "")?.toLocal() ?? DateTime.now(),
      isOwned: isMine,
      status: isMine ? MessageStatus.Sent : MessageStatus.Delivered,
      attachment: attachment,
      reply: MessageReply.fromMap(data["Reply"]),
      transfer: attachment != null ? TransferState.pending : TransferState.none,
    );

    final isOpen = globals.openChatUsername == chatId;
    final added = await database.chats.addMessage(await ensureChat(), message, countAsUnread: countAsUnread && !isMine && !isOpen);
    if (!added) return;
    if (live) ChatService().incomingMessages.add(message);
    // Photos are small (re-encoded by the server): downloaded right away, shown blurred until touched
    if (attachment != null) unawaited(ChatService().download(message));
  }

  Future<void> _removeAll(List<String> uuids) async {
    for (final uuid in uuids) {
      final message = database.messages.getByUuid(uuid);
      if (message == null) continue;
      await ChatService().markDeleted(message);
    }
  }

  // #endregion

  // #region -> Sending

  /// Sends one of my messages (already saved, its photo already uploaded). The server answers with an
  /// acknowledgement, or "GlobalRejected" with why (spam, sanction).
  Future<void> deliver(Message message, Attachment? attachment) async {
    final reply = message.reply;
    final payload = <String, dynamic>{
      "CommunicationType": "GlobalMessage",
      "Uuid": message.uuid,
      "Content": attachment != null ? (attachment.caption ?? "") : message.content,
      if (attachment?.fileId != null) "Photo": {"ID": attachment!.fileId, "Width": attachment.width ?? 0, "Height": attachment.height ?? 0},
      if (reply != null) "Reply": reply.toMap(),
    };
    final acknowledged = await network.sendAndWaitForAcknowledgement(message.uuid, payload);
    final current = database.messages.getByUuid(message.uuid);
    if (current == null || current.status == MessageStatus.Failed) return; // refused meanwhile
    await database.messages.update(message.uuid, (m) {
      if (acknowledged) {
        if (m.status == MessageStatus.Sending) m.status = MessageStatus.Sent;
      } else if (network.isConnected) {
        m.status = MessageStatus.Failed;
      }
    });
  }

  /// Deletes my message for everyone (an admin can delete anyone's)
  void deleteForEveryone(Message message) => network.sendRaw({
    "CommunicationType": "GlobalDeletion",
    "Uuids": [message.uuid],
  });

  /// Reports who wrote [message]. Returns what the server says (thanks, or why it failed).
  Future<({bool sent, String text})> report(Message message, {String? reason}) async {
    final response = await network.post("/global/report", {"Uuid": message.uuid, "Reason": ?reason});
    if (response.statusCode == 200) {
      final data = tryJsonDecode(response.body);
      return (sent: true, text: data is Map && data["Message"] is String ? data["Message"] as String : AppStrings.reportSent);
    }
    return (sent: false, text: AppStrings.errorFor(response));
  }

  // #endregion
}
