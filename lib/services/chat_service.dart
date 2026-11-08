import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:messagyre_client/configuration/app_strings.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/attachment.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/services/class_service.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/encryption_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' show RSAPublicKey;
import 'package:uuid/uuid.dart';

/// Whether messages to someone are end-to-end encrypted
enum EncryptionState {
  /// Not known yet (the public key is being fetched, or couldn't be fetched)
  unknown,
  available,

  /// The recipient's app is too old to have a key: texts go unencrypted, attachments are disabled
  unavailable,
}

/// Why an attachment couldn't be sent
class AttachmentException implements Exception {
  final String message;
  const AttachmentException(this.message);
  @override
  String toString() => message;
}

/// Everything about conversations: sending (with a queue: what is written offline leaves at the next connection),
/// receiving, receipts, deletions, photos and files. Pages only display what this service stores in the database.
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final network = NetworkService();
  final database = DatabaseService();
  final encryption = EncryptionService();
  final globals = GlobalsService();

  /// Largest photo or file that can be sent
  static const maxAttachmentBytes = 16 * 1024 * 1024;

  /// Received photos up to this size are downloaded without asking
  static const autoDownloadBytes = 8 * 1024 * 1024;

  /// Received messages, after they were saved (the chat page uses it to scroll and animate)
  final incomingMessages = StreamController<Message>.broadcast();

  final Set<String> _sending = {};
  final Set<String> _transferring = {};
  final Map<String, ValueNotifier<double?>> _progress = {};
  final Map<String, ValueNotifier<EncryptionState>> _encryptionStates = {};
  final Map<String, RSAPublicKey> _publicKeys = {};

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    network.connectionState.addListener(_onConnectionStateChanged);
    _migrate();
  }

  /// Messages saved before 4.84 only knew their chat through IsarLinks
  Future<void> _migrate() async {
    const flag = "MessagesHaveChatUsername";
    if (globals.persistent.getBool(flag) == true) return;
    try {
      final count = await database.chats.migrateLinkedMessages();
      await globals.persistent.setBool(flag, true);
      debugPrint("[Chat] $count messages migrated to the 4.84 format");
    } catch (e) {
      debugPrint("[Chat] Migrating the messages failed: $e");
    }
  }

  void _onConnectionStateChanged() {
    if (network.connectionState.value != ConnectionState.Connected) return;
    _seedReviewChats();
    if (ClassService().current.value != null) unawaited(ClassService().loadMembers(force: true));
    resendPending();
    _resumeDownloads();
    final openChat = globals.openChatUsername;
    if (openChat != null) markRead(openChat);
  }

  /// Upload or download progress of a message's attachment (0 to 1, null when unknown)
  ValueNotifier<double?> progressOf(String uuid) => _progress.putIfAbsent(uuid, () => ValueNotifier(null));

  // #region -> Encryption

  ValueNotifier<EncryptionState> encryptionStateOf(String username) => _encryptionStates.putIfAbsent(username, () => ValueNotifier(EncryptionState.unknown));

  /// The recipient's public key (null when they have none or it couldn't be fetched: see [encryptionStateOf])
  Future<RSAPublicKey?> publicKeyOf(String username, {bool refresh = false}) async {
    if (!refresh && _publicKeys.containsKey(username)) return _publicKeys[username];

    final lookup = await network.fetchPublicKey(username);
    final state = encryptionStateOf(username);

    switch (lookup) {
      case PublicKeyFound(:final key):
        _publicKeys[username] = key;
        state.value = EncryptionState.available;
        return key;
      case PublicKeyMissing():
        _publicKeys.remove(username);
        state.value = EncryptionState.unavailable;
        return null;
      case PublicKeyError():
        // Unknown: nothing is sent unencrypted because of a network error
        return _publicKeys[username];
    }
  }

  // #endregion

  // #region -> Sending

  /// [chatId] is a username, or "#" and a class for a class chat (see [ClassService.chatIdOf])
  Future<Chat> _chatFor(String chatId) async {
    final className = ClassService.classOfChat(chatId);
    return database.chats.getByUsername(chatId) ?? Chat.custom(username: chatId, displayUsername: className == null ? null : ClassService.chatTitleOf(className));
  }

  Future<void> sendText(String username, String text) async {
    final content = text.trim();
    if (content.isEmpty) return;

    final message = Message.custom(chatUsername: username, content: content, sentAt: DateTime.now(), isOwned: true);
    await database.chats.addMessage(await _chatFor(username), message);
    unawaited(_deliver(message.uuid));
  }

  /// Sends a photo (from the gallery or the camera, already resized by image_picker) or any file.
  /// Throws an [AttachmentException] with a sentence for the user when it can't be sent.
  Future<void> sendAttachment(String username, {required String path, required AttachmentKind kind, String? name, String? caption}) async {
    if (encryptionStateOf(username).value == EncryptionState.unavailable) throw const AttachmentException(AppStrings.encryptionOff);

    final source = File(path);
    final size = await source.length();
    if (size > maxAttachmentBytes) throw AttachmentException(AppStrings.fileTooBig(maxAttachmentBytes ~/ (1024 * 1024)));

    final uuid = const Uuid().v4();
    final fileName = _safeFileName(name ?? p.basename(path));
    final bytes = await source.readAsBytes();

    // Kept on this device: the server deletes its copy once the recipient has it
    final localPath = await _attachmentPath(uuid, fileName);
    await File(localPath).writeAsBytes(bytes, flush: true);

    final imageInfo = kind == AttachmentKind.image ? await compute(_imageInfo, bytes) : null;
    final encrypted = await EncryptionService.encryptFile(bytes);

    final attachment = Attachment(
      kind: imageInfo != null ? AttachmentKind.image : AttachmentKind.file,
      key: encrypted.key,
      iv: encrypted.iv,
      name: fileName,
      mimeType: _mimeTypeOf(fileName),
      size: size,
      width: imageInfo?.width,
      height: imageInfo?.height,
      thumbnail: imageInfo?.thumbnail,
      caption: caption?.trim().isEmpty ?? true ? null : caption!.trim(),
    );

    final message = Message.custom(
      uuid: uuid,
      chatUsername: username,
      content: attachment.previewText,
      sentAt: DateTime.now(),
      isOwned: true,
      attachment: attachment,
      localPath: localPath,
      transfer: TransferState.uploading,
    );

    await database.chats.addMessage(await _chatFor(username), message);
    unawaited(_deliver(uuid, encryptedBytes: encrypted.bytes));
  }

  /// Tries again a message that failed
  Future<void> retry(Message message) async {
    final updated = await database.messages.update(message.uuid, (m) {
      m.status = MessageStatus.Sending;
      if (m.transfer == TransferState.failed) m.transfer = TransferState.uploading;
    });
    if (updated != null) await _deliver(updated.uuid);
  }

  Timer? _resendTimer;

  void _scheduleResend() {
    if (_resendTimer?.isActive ?? false) return;
    _resendTimer = Timer(const Duration(seconds: 15), resendPending);
  }

  /// Sends every message still waiting (written offline, or interrupted)
  Future<void> resendPending() async {
    for (final message in database.messages.pendingOwned()) {
      if (!network.isConnected) return;
      await _deliver(message.uuid);
    }
  }

  Future<void> _deliver(String uuid, {Uint8List? encryptedBytes}) async {
    if (!_sending.add(uuid)) return;

    try {
      var message = database.messages.getByUuid(uuid);
      if (message == null || !message.isOwned || message.isDeleted || message.status != MessageStatus.Sending) return;

      final username = message.chatUsername!;
      var attachment = message.attachment;

      // 1. The file, if not on the server yet
      if (attachment != null && attachment.fileId == null) {
        final fileId = await _upload(message, attachment, encryptedBytes);
        if (fileId == null) return;
        attachment = attachment.copyWith(fileId: fileId);
        message = await database.messages.update(uuid, (m) {
          m.attachmentData = attachment!.toJson();
          m.transfer = TransferState.ready;
        });
        if (message == null) return;
      }

      // 2. The message: without a connection it waits for the next one (resendPending)
      if (!network.isConnected) return;

      if (ClassService.isClassChat(username)) {
        await _deliverToClass(message, attachment);
        return;
      }

      final key = await publicKeyOf(username);
      final encryptionState = encryptionStateOf(username).value;
      if (key == null && encryptionState == EncryptionState.unknown) {
        // The key couldn't be fetched (network): never sent unencrypted, tried again in a moment
        _scheduleResend();
        return;
      }

      final payload = <String, dynamic>{"CommunicationType": "Message", "Uuid": uuid, "RecipientUsername": username};
      if (key != null) {
        payload.addAll(encryption.encryptMessage(message.content, key, attachmentJson: attachment?.toJson()));
      } else if (attachment != null) {
        await _setStatus(uuid, MessageStatus.Failed);
        return;
      } else {
        payload["Content"] = message.content;
      }

      final acknowledged = await network.sendAndWaitForAcknowledgement(uuid, payload);

      if (acknowledged) {
        await _setStatus(uuid, MessageStatus.Sent);
      } else if (network.isConnected) {
        await _setStatus(uuid, MessageStatus.Failed);
      }
      // Disconnected meanwhile: still Sending, sent again at the next connection
    } catch (e, s) {
      debugPrint("[Chat] Sending $uuid failed: $e\n$s");
      await _setStatus(uuid, MessageStatus.Failed);
    } finally {
      _sending.remove(uuid);
    }
  }

  /// A message of a class chat: encrypted once, its key encrypted for every member who has a key
  Future<void> _deliverToClass(Message message, Attachment? attachment) async {
    final className = ClassService.classOfChat(message.chatUsername!)!;
    final classes = ClassService();

    // Not (or no longer) in this class: the server would refuse it
    if (classes.current.value?.name != className) {
      await _setStatus(message.uuid, MessageStatus.Failed);
      return;
    }

    final members = await classes.loadMembers();
    final keys = {
      for (final member in members)
        if (member.username != globals.username && member.publicKey != null) member.username: member.publicKey!,
    };

    final payload = <String, dynamic>{
      "CommunicationType": "GroupMessage",
      "Uuid": message.uuid,
      "Group": className,
      ...encryption.encryptForMany(message.content, keys, attachmentJson: attachment?.toJson()),
    };

    final acknowledged = await network.sendAndWaitForAcknowledgement(message.uuid, payload);
    if (acknowledged) {
      await _setStatus(message.uuid, MessageStatus.Sent);
    } else if (network.isConnected) {
      await _setStatus(message.uuid, MessageStatus.Failed);
    }
  }

  /// Uploads the encrypted file and returns its ID on the server (null after a failure, already saved in the message)
  Future<String?> _upload(Message message, Attachment attachment, Uint8List? encryptedBytes) async {
    final progress = progressOf(message.uuid);
    try {
      if (encryptedBytes == null) {
        final localPath = message.localPath;
        if (localPath == null || !await File(localPath).exists()) throw const AttachmentException(AppStrings.genericError);
        encryptedBytes = (await EncryptionService.encryptFile(await File(localPath).readAsBytes(), key: attachment.key, iv: attachment.iv)).bytes;
      }

      progress.value = 0;
      final result = await network.uploadFile(encryptedBytes, recipientUsername: message.chatUsername!, onProgress: (value) => progress.value = value);
      progress.value = null;

      if (result.id != null) return result.id;
      debugPrint("[Chat] Upload refused: ${result.error}");
    } catch (e) {
      debugPrint("[Chat] Upload failed: $e");
      progress.value = null;
    }

    await database.messages.update(message.uuid, (m) {
      m.transfer = TransferState.failed;
      m.status = MessageStatus.Failed;
    });
    return null;
  }

  /// Changes the status of one of my messages without ever moving it backwards (a receipt can come first)
  Future<void> _setStatus(String uuid, MessageStatus status) async {
    await database.messages.update(uuid, (m) {
      if (status == MessageStatus.Failed) {
        if (m.status == MessageStatus.Sending) m.status = MessageStatus.Failed;
      } else if (m.status == MessageStatus.Failed || m.status == MessageStatus.Sending || status.index > m.status.index) {
        m.status = status;
      }
    });
  }

  // #endregion

  // #region -> Receiving

  /// Every communication from the server except acknowledgements (handled by NetworkService)
  Future<void> handleCommunication(Map<String, dynamic> data) async {
    try {
      switch (data["CommunicationType"]) {
        case "Message":
        case "GroupMessage":
          await _onMessage(data);
        case "Receipt":
          await _onReceipt(data);
        case "Deletion":
          await _onDeletion(data);
      }
    } catch (e, s) {
      debugPrint("[Chat] A communication couldn't be handled: $e\n$s");
    }
  }

  Future<void> _onMessage(Map<String, dynamic> data) async {
    final sender = data["SenderUsername"]?.toString();
    final uuid = data["Uuid"]?.toString() ?? const Uuid().v4();
    final sentAt = DateTime.tryParse(data["SentAt"]?.toString() ?? "")?.toLocal() ?? DateTime.now();
    if (sender == null) return;

    // A message of a class chat goes to the class's conversation, with who wrote it
    final group = data["CommunicationType"] == "GroupMessage" ? data["Group"]?.toString() : null;
    final chatId = group != null ? ClassService.chatIdOf(group) : sender;

    // Acknowledged even when ignored: otherwise the server would deliver it again at every connection
    void acknowledge() => network.sendRaw({"CommunicationType": "Acknowledgement", "Uuid": uuid});

    if (globals.blockedUsers.contains(sender)) {
      acknowledge();
      return;
    }

    String content;
    Attachment? attachment;

    final cipherText = data["CipherText"], iv = data["Iv"] ?? data["IV"], encryptedKey = data["EncryptedKey"];
    if (cipherText is String && iv is String && encryptedKey is String) {
      try {
        final decrypted = await encryption.decryptPayload(cipherText, iv, encryptedKey, rawAttachment: data["Attachment"]?.toString());
        content = decrypted.$1;
        attachment = Attachment.tryParse(decrypted.$2);
      } catch (e) {
        debugPrint("[Chat] A message from $sender couldn't be decrypted: $e");
        content = "🔒 Ce message n'a pas pu être déchiffré.";
      }
    } else {
      content = data["Content"]?.toString() ?? "";
    }

    final message = Message.custom(
      uuid: uuid,
      chatUsername: chatId,
      senderUsername: group != null ? sender : null,
      content: content,
      sentAt: sentAt,
      isOwned: false,
      status: MessageStatus.Delivered,
      attachment: attachment,
      transfer: attachment != null ? TransferState.pending : TransferState.none,
    );

    final isChatOpen = globals.openChatUsername == chatId;
    final added = await database.chats.addMessage(await _chatFor(chatId), message, countAsUnread: !isChatOpen);
    acknowledge();
    if (!added) return;

    HapticFeedback.mediumImpact();
    incomingMessages.add(message);

    if (isChatOpen) markRead(chatId);
    if (attachment != null && attachment.isImage && attachment.size <= autoDownloadBytes) unawaited(download(message));
  }

  Future<void> _onReceipt(Map<String, dynamic> data) async {
    final from = data["SenderUsername"]?.toString();
    final uuids = data["Uuids"];
    final status = switch (data["Status"]) {
      "Delivered" => MessageStatus.Delivered,
      "Read" => MessageStatus.Read,
      _ => null,
    };
    if (from == null || uuids is! List || status == null) return;

    for (final uuid in uuids.map((u) => u.toString())) {
      final message = database.messages.getByUuid(uuid);
      if (message == null || !message.isOwned || message.chatUsername != from) continue;
      await _setStatus(uuid, status);
    }
  }

  Future<void> _onDeletion(Map<String, dynamic> data) async {
    final sender = data["SenderUsername"]?.toString();
    final rawUuids = data["Uuids"];
    if (sender == null || rawUuids == null) return;

    final group = data["Group"]?.toString();
    final uuids = rawUuids is List ? rawUuids.map((u) => u.toString()) : [rawUuids.toString()];
    for (final uuid in uuids) {
      final message = database.messages.getByUuid(uuid);
      // Only the sender can delete their message for everybody
      if (message == null || message.isOwned) continue;
      if (group != null ? (message.chatUsername != ClassService.chatIdOf(group) || message.senderUsername != sender) : message.chatUsername != sender) continue;
      await _deleteLocalFile(message);
      await database.messages.update(uuid, (m) {
        m.isDeleted = true;
        m.localPath = null;
        m.transfer = TransferState.none;
      });
    }
  }

  /// Opening a conversation reads its messages: their senders are told so (newer apps show it)
  Future<void> markRead(String username) async {
    final chat = database.chats.getByUsername(username);
    if (chat != null) await database.chats.resetUnread(chat);
    if (!network.isConnected) return;

    final unread = database.messages.unreadReceived(username);
    if (unread.isEmpty) return;

    // No read receipts in a class chat
    if (!ClassService.isClassChat(username) && (globals.persistent.getBool("SendReadReceipts") ?? true)) {
      // The newest 500 at most (the server's limit): older ones don't matter any more
      final uuids = unread.reversed.take(500).map((m) => m.uuid).toList();
      if (!network.sendRaw({"CommunicationType": "Read", "RecipientUsername": username, "Uuids": uuids})) return;
    }

    for (final message in unread) {
      message.status = MessageStatus.Read;
    }
    await database.messages.saveAll(unread);
  }

  // #endregion

  // #region -> Attachments

  /// Downloads and decrypts a received photo or file
  Future<void> download(Message message) async {
    final attachment = message.attachment;
    if (attachment == null || attachment.fileId == null || !_transferring.add(message.uuid)) return;

    final progress = progressOf(message.uuid);
    try {
      await database.messages.update(message.uuid, (m) => m.transfer = TransferState.downloading);
      progress.value = 0;

      final result = await network.downloadFile(attachment.fileId!, onProgress: (value) => progress.value = value);

      if (result.statusCode == 404) {
        await database.messages.update(message.uuid, (m) => m.transfer = TransferState.expired);
        return;
      }
      if (result.bytes == null) throw Exception("HTTP ${result.statusCode}");

      final plain = await EncryptionService.decryptFile(result.bytes!, attachment.key, attachment.iv);
      final localPath = await _attachmentPath(message.uuid, attachment.name);
      await File(localPath).writeAsBytes(plain, flush: true);

      await database.messages.update(message.uuid, (m) {
        m.localPath = localPath;
        m.transfer = TransferState.ready;
      });
    } catch (e) {
      debugPrint("[Chat] Downloading an attachment failed: $e");
      await database.messages.update(message.uuid, (m) => m.transfer = TransferState.failed);
    } finally {
      progress.value = null;
      _transferring.remove(message.uuid);
    }
  }

  /// Photos received while their download couldn't start (the app was closed, offline...)
  void _resumeDownloads() {
    for (final message in database.messages.pendingDownloads()) {
      final attachment = message.attachment;
      if (attachment != null && attachment.isImage && attachment.size <= autoDownloadBytes) unawaited(download(message));
    }
  }

  static Future<String> _attachmentPath(String uuid, String fileName) async {
    final directory = Directory(p.join((await getApplicationDocumentsDirectory()).path, "attachments", uuid));
    await directory.create(recursive: true);
    return p.join(directory.path, fileName);
  }

  static String _safeFileName(String name) {
    final cleaned = p.basename(name).replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), "_").trim();
    if (cleaned.isEmpty || cleaned == "." || cleaned == "..") return "fichier";
    return cleaned.length > 120 ? cleaned.substring(cleaned.length - 120) : cleaned;
  }

  static String _mimeTypeOf(String name) => switch (p.extension(name).toLowerCase()) {
    ".jpg" || ".jpeg" => "image/jpeg",
    ".png" => "image/png",
    ".gif" => "image/gif",
    ".webp" => "image/webp",
    ".heic" => "image/heic",
    ".pdf" => "application/pdf",
    ".txt" => "text/plain",
    ".zip" => "application/zip",
    ".doc" => "application/msword",
    ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".xls" => "application/vnd.ms-excel",
    ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".ppt" => "application/vnd.ms-powerpoint",
    ".pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ".mp3" => "audio/mpeg",
    ".m4a" => "audio/mp4",
    ".mp4" => "video/mp4",
    ".mov" => "video/quicktime",
    _ => "application/octet-stream",
  };

  /// Size and a tiny preview of a photo (in a background isolate)
  static ({int width, int height, String thumbnail})? _imageInfo(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final image = img.bakeOrientation(decoded);
      final preview = image.width >= image.height ? img.copyResize(image, width: 32) : img.copyResize(image, height: 32);
      return (width: image.width, height: image.height, thumbnail: base64.encode(img.encodeJpg(preview, quality: 60)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteLocalFile(Message message) async {
    final path = message.localPath;
    if (path == null) return;
    try {
      final directory = Directory(p.dirname(path));
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (e) {
      debugPrint("[Chat] A local attachment couldn't be deleted: $e");
    }
  }

  // #endregion

  // #region -> Deleting and reporting

  Future<void> deleteForMe(Message message) async {
    await _deleteLocalFile(message);
    await database.messages.delete(message);
  }

  Future<void> deleteForEveryone(Message message) async {
    final fileId = message.attachment?.fileId;
    await _deleteLocalFile(message);
    await database.messages.update(message.uuid, (m) {
      m.isDeleted = true;
      m.localPath = null;
      m.transfer = TransferState.none;
    });
    final className = ClassService.classOfChat(message.chatUsername!);
    if (className != null) {
      network.sendRaw({"CommunicationType": "Deletion", "Group": className, "Uuids": [message.uuid]});
    } else {
      network.sendMessageDelete([message.uuid], message.chatUsername!);
    }
    if (fileId != null) unawaited(network.post("/files/delete", {"ID": fileId}));
  }

  Future<void> deleteChat(Chat chat) async {
    for (final message in database.messages.ofChat(chat.username)) {
      await _deleteLocalFile(message);
    }
    await database.chats.deleteChat(chat);
  }

  /// Sends the message to the team (the reporter chooses to share its content). Returns false when it failed.
  Future<bool> report(Message message, {String? reason}) async {
    final response = await network.post("/reports/add", {
      "ReportedUsername": message.senderUsername ?? message.chatUsername,
      "MessageUuid": message.uuid,
      "Content": message.hasAttachment ? "[${message.attachment?.name}] ${message.displayText}" : message.content,
      "Reason": ?reason,
    });
    return response.statusCode == 200;
  }

  // #endregion

  // #region -> Review accounts

  /// Apple and Google reviewers need conversations to try reporting and blocking
  Future<void> _seedReviewChats() async {
    if (globals.username != "apple.verification" && globals.username != "google.verification") return;
    if (database.chats.getByUsername("test.1") != null) return;

    final now = DateTime.now();
    final conversations = {
      "test.1": [
        ("Bonjour. Ceci est une conversation de démonstration.", false, 5),
        ("Salut, comment ça va ?", true, 4),
        ("Tu es vraiment nul, personne veut parler avec toi.", false, 3),
        ("Ce message est un exemple de contenu à signaler.", false, 2),
      ],
      "test.2": [
        ("Bonjour, ceci est un exemple de chat normal.", false, 6),
        ("Merci, c'est parfait pour la vérification.", true, 5),
        ("N'hésitez pas à signaler ou bloquer un utilisateur.", false, 4),
      ],
    };

    for (final MapEntry(key: username, value: messages) in conversations.entries) {
      final chat = Chat.custom(username: username);
      for (final (content, isOwned, minutesAgo) in messages) {
        await database.chats.addMessage(
          chat,
          Message.custom(
            content: content,
            sentAt: now.subtract(Duration(minutes: minutesAgo)),
            isOwned: isOwned,
            status: isOwned ? MessageStatus.Read : MessageStatus.Delivered,
          ),
        );
      }
    }
  }

  // #endregion
}
