import 'package:isar/isar.dart';
import '../messages/message.dart';

part 'chat.g.dart';

@collection
class Chat {
  Id id = Isar.autoIncrement;

  late String recipientUsername;

  String? recipientDisplayUsername;

  bool isPinned = false;

  int unreadMessages = 0;

  final messages = IsarLinks<Message>();

  Chat();

  @override
  String toString() =>
      "[$recipientUsername's chat] messages: ${messages.length}";
}
