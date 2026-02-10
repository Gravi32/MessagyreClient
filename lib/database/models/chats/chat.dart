import 'package:isar/isar.dart';
import '../messages/message.dart';

part 'chat.g.dart';

@collection
class Chat {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String username;

  String? displayUsername;

  bool isPinned = false;

  int unreadMessages = 0;

  final messages = IsarLinks<Message>();

  Chat();

  factory Chat.custom({required String username, String? displayUsername, bool isPinned = false, int unreadMessages = 0}) {
    return Chat()
      ..username = username
      ..displayUsername = displayUsername
      ..isPinned = isPinned
      ..unreadMessages = unreadMessages;
  }

  @override
  String toString() => "[Instance of the chat with $username] messages: ${messages.length}";
}
