import 'package:isar/isar.dart';
import 'package:messagyre_client/database/models/messages/message.dart';

class MessageRepository {
  final Isar isar;

  MessageRepository(this.isar);

  List<Message> getAll() => isar.messages.where().findAllSync();
  Message? getByUuid(String uuid) => isar.messages.filter().uuidEqualTo(uuid).findFirstSync();

  /// The messages of a conversation, oldest first
  List<Message> ofChat(String username) => isar.messages.where().chatUsernameEqualToAnySentAt(username).findAllSync();

  /// The messages of a conversation, newest first, refreshed at every change
  Stream<List<Message>> watchChat(String username) =>
      isar.messages.where(sort: Sort.desc).chatUsernameEqualToAnySentAt(username).watch(fireImmediately: true);

  Message? lastOfChat(String username) => isar.messages.where(sort: Sort.desc).chatUsernameEqualToAnySentAt(username).findFirstSync();

  /// Messages of mine still waiting to be sent, oldest first
  List<Message> pendingOwned() =>
      isar.messages.filter().isOwnedEqualTo(true).statusEqualTo(MessageStatus.Sending).isDeletedEqualTo(false).sortBySentAt().findAllSync();

  /// Received messages of a conversation that the server must still tell the sender were read
  List<Message> unreadReceived(String username) => isar.messages
      .where()
      .chatUsernameEqualToAnySentAt(username)
      .filter()
      .isOwnedEqualTo(false)
      .not()
      .statusEqualTo(MessageStatus.Read)
      .findAllSync();

  /// Received photos waiting to be downloaded
  List<Message> pendingDownloads() => isar.messages.filter().isOwnedEqualTo(false).transferEqualTo(TransferState.pending).findAllSync();

  Future<void> save(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.put(message);
    });
  }

  Future<void> saveAll(List<Message> messages) async {
    if (messages.isEmpty) return;
    await isar.writeTxn(() async {
      await isar.messages.putAll(messages);
    });
  }

  /// Applies [change] to the stored copy of the message (if it still exists) and saves it
  Future<Message?> update(String uuid, void Function(Message message) change) async {
    Message? result;
    await isar.writeTxn(() async {
      final message = await isar.messages.filter().uuidEqualTo(uuid).findFirst();
      if (message == null) return;
      change(message);
      await isar.messages.put(message);
      result = message;
    });
    return result;
  }

  Future<void> markAsDeleted(Message message) async {
    await isar.writeTxn(() async {
      message.isDeleted = true;
      await isar.messages.put(message);
    });
  }

  Future<void> delete(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(message.id);
    });
  }

  Future<void> deleteAllOfChat(String username) async {
    await isar.writeTxn(() async {
      await isar.messages.where().chatUsernameEqualToAnySentAt(username).deleteAll();
    });
  }

  Stream<List<Message>> watchAll() {
    return isar.messages.where().watch(fireImmediately: true);
  }
}
