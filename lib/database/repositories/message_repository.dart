import 'package:isar/isar.dart';
import 'package:messagyre_client/database/models/messages/message.dart';

class MessageRepository {
  final Isar isar;

  MessageRepository(this.isar);

  List<Message> getAll() => isar.messages.where().findAllSync();
  Message? getByUuid(String uuid) => isar.messages.filter().uuidEqualTo(uuid).findFirstSync();

  Future<void> save(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.put(message);
    });
    return;
  }

  Future<void> delete(Message message) async {
    await isar.writeTxn(() async {
      await isar.messages.delete(message.id);
    });
    return;
  }

  Stream<List<Message>> watchAll() {
    return isar.messages.where().watch(fireImmediately: true);
  }
}
