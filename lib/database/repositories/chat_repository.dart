import 'package:isar_community/isar.dart';
import '../models/chats/chat.dart';
import '../models/messages/message.dart';

class ChatRepository {
  final Isar isar;

  ChatRepository(this.isar);

  List<Chat> getAll() => isar.chats.where().findAllSync();

  Chat? getByUsername(String username) => isar.chats.filter().usernameEqualTo(username).findFirstSync();

  Future<void> save(Chat chat) async {
    await isar.writeTxn(() async {
      await isar.chats.put(chat);
    });
  }

  /// Saves a message in its conversation (created if needed). Returns false when the message was already
  /// there (the server can deliver a message twice): it is then left untouched.
  Future<bool> addMessage(Chat chat, Message message, {bool countAsUnread = false}) async {
    var added = false;
    await isar.writeTxn(() async {
      if (await isar.messages.filter().uuidEqualTo(message.uuid).isEmpty() == false) return;

      message.chatUsername = chat.username;
      if (countAsUnread) chat.unreadMessages++;

      await isar.messages.put(message);
      await isar.chats.put(chat);
      added = true;
    });
    return added;
  }

  Future<void> setPinned(Chat chat, bool isPinned) async {
    await isar.writeTxn(() async {
      chat.isPinned = isPinned;
      await isar.chats.put(chat);
    });
  }

  Future<void> resetUnread(Chat chat) async {
    if (chat.unreadMessages == 0) return;
    await isar.writeTxn(() async {
      chat.unreadMessages = 0;
      await isar.chats.put(chat);
    });
  }

  Stream<List<Chat>> watchAll() {
    return isar.chats.where().watch(fireImmediately: true);
  }

  Stream<void> watchAllLazy() => isar.chats.watchLazy(fireImmediately: true);

  Stream<Chat?> watchChat(String username) {
    return isar.chats.filter().usernameEqualTo(username).watch(fireImmediately: true).map((chats) => chats.isNotEmpty ? chats.first : null);
  }

  /// Removes the conversation and all its messages from this device
  Future<void> deleteChat(Chat? chat) async {
    if (chat == null) return;
    await isar.writeTxn(() async {
      await isar.messages.where().chatUsernameEqualToAnySentAt(chat.username).deleteAll();
      await isar.chats.delete(chat.id);
    });
  }

  /// Removes every conversation and message from this device (another account signed in)
  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.messages.clear();
      await isar.chats.clear();
    });
  }

  /// Before 4.84 messages were only linked to their chat (IsarLinks, without order): gives them their chatUsername
  Future<int> migrateLinkedMessages() async {
    var migrated = 0;
    final chats = getAll();
    await isar.writeTxn(() async {
      for (final chat in chats) {
        await chat.messages.load();
        final toFix = chat.messages.where((m) => m.chatUsername == null).toList();
        for (final message in toFix) {
          message.chatUsername = chat.username;
        }
        await isar.messages.putAll(toFix);
        migrated += toFix.length;
      }
    });
    return migrated;
  }
}
