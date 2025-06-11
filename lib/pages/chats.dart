import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/pages/overlays/search.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/extensions.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final router = ConnectionController();
  final data = Data();

  late Box<Chat> allChats;

  // Widgets

  Widget buildChatBar(Chat data) {
    var hasUnreadMessages = data.unreadMessages > 0;

    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 55,
            child: Row(
              children: [
                ProfilePictureDisplay(data.recipientUsername, radius: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.recipientUsername
                            .replaceAll('.', ' ')
                            .capitalize(),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        data.content.last.content,
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).dividerColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(data.content.last.sentAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                        fontWeight:
                            hasUnreadMessages
                                ? FontWeight.w400
                                : FontWeight.w400,
                      ),
                    ),
                    if (hasUnreadMessages)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data.unreadMessages.toString(),
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              CupertinoPageRoute(
                builder:
                    (builder) =>
                        ChatOverlay(recipientUsername: data.recipientUsername),
              ),
            );
          },
        ),

        Divider(
          indent: 60,
          color: Theme.of(context).dividerColor.withAlpha(30),
        ),
      ],
    );
  }

  // Overrides

  @override
  void initState() {
    super.initState();

    allChats = Hive.box<Chat>("Chats");

    router.onSignalReceived.listen((signal) {
      if (!mounted || data.isChatOpen || signal.type != SignalType.Message) {
        return;
      }

      var senderUsername = signal.data["SenderUsername"];
      var receivedMessage = Message.fromSignal(signal);
      if (senderUsername == null || receivedMessage == null) return;

      var targetChat = allChats.get(senderUsername);

      if (targetChat == null) {
        targetChat = Chat(recipientUsername: senderUsername);
        targetChat.content.add(receivedMessage);
        targetChat.unreadMessages = 1;
        debugPrint("SET UNREADMESSAGES TO 1");
      } else {
        targetChat.content.add(receivedMessage);
        targetChat.unreadMessages += 1;
      }

      allChats.put(senderUsername, targetChat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CupertinoSliverNavigationBar(
              largeTitle: Text("Conversations"),
              trailing: GestureDetector(
                child: Icon(CupertinoIcons.add),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => SearchPage()),
                  );
                },
              ),
            ),
          ];
        },
        body: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder(
              valueListenable: allChats.listenable(),
              builder: (context, Box<Chat> box, _) {
                final chatsList = box.values.toList();
                chatsList.sort(
                  (a, b) =>
                      b.content.last.sentAt.compareTo(a.content.last.sentAt),
                );

                return ListView.builder(
                  padding: EdgeInsets.only(top: 8),
                  itemCount: chatsList.length,
                  itemBuilder: (context, index) {
                    return buildChatBar(chatsList[index]);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
