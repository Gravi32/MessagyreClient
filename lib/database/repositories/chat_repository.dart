import 'package:isar/isar.dart';
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
      await chat.messages.save();
    });
    return;
  }

  Future<void> addMessage(Chat chat, Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.put(message);
      await isar.chats.put(chat);

      chat.messages.add(message);
      await chat.messages.save();
    });
  }

  Future<void> incrementUnread(Chat chat) async {
    await isar.writeTxn(() async {
      chat.unreadMessages++;
      await isar.chats.put(chat);
    });
    return;
  }

  Future<void> resetUnread(Chat chat) async {
    await isar.writeTxn(() async {
      chat.unreadMessages = 0;
      await isar.chats.put(chat);
    });
    return;
  }

  Stream<List<Chat>> watchAll() {
    return isar.chats.where().watch(fireImmediately: true);
  }

  Future<void> deleteChat(Chat? chat) async {
    if (chat == null) return;
    await isar.writeTxn(() async {
      await isar.chats.delete(chat.id);
    });
    return;
  }
}
