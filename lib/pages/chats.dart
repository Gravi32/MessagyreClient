import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/overlays/chat.dart';
import 'package:messagyre_client/singletons/connection_controller.dart';
import 'package:messagyre_client/singletons/data.dart';
import 'package:messagyre_client/utility/classes.dart';
import 'package:messagyre_client/utility/utility.dart';
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
                ProfilePictureDisplay(
                  accountUsername: data.recipientUsername,
                  radius: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Account.getDisplayableUsername(data.recipientUsername),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: adaptiveColor(
                            context,
                            CupertinoColors.black,
                            CupertinoColors.white,
                          ),
                        ),
                      ),
                      Text(
                        data.content.last.content.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontWeight:
                              hasUnreadMessages
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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

    router.onMessageDataReceived.listen((messageData) {
      if (!mounted || data.isChatOpen) return;

      var senderUsername = messageData["SenderUsername"]!.toString();
      var receivedMessage = Message.fromMessageData(messageData);

      var targetChat = allChats.get(senderUsername);

      if (targetChat == null) {
        targetChat = Chat(recipientUsername: senderUsername);
        targetChat.content.add(receivedMessage);
        targetChat.unreadMessages = 1;
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
            ValueListenableBuilder(
              valueListenable: data.isConnecting,
              builder:
                  (context, isConnecting, _) => CupertinoSliverNavigationBar(
                    leading:
                        isConnecting
                            ? Row(
                              spacing: 8,
                              children: [
                                CupertinoActivityIndicator(),
                                Text(
                                  "Connexion en cours...",
                                  style: TextStyle(
                                    color: adaptiveColor(
                                      context,
                                      CupertinoColors.systemGrey2,
                                      CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : null,
                    largeTitle: Text("Conversations"),
                    trailing: GestureDetector(
                      child: Icon(CupertinoIcons.add),
                      onTap: () => MainPage.tabController.index = 3,
                    ),
                  ),
            ),
          ];
        },
        body: SafeArea(
          top: false,
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

                return chatsList.isEmpty
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          size: 40,
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                        Text(
                          "Entamez une conversation !",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.separator.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ],
                    )
                    : ListView.builder(
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
