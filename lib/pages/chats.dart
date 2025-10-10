import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:hive_flutter/adapters.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

class _ChatsPageState extends State<ChatsPage> with AutomaticKeepAliveClientMixin {
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
            height: 50,
            child: Row(
              children: [
                ProfilePictureDisplay(accountUsername: data.recipientUsername, radius: 25),

                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.recipientDisplayUsername ?? Account.getDefaultDisplayName(data.recipientUsername),
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (data.content.isNotEmpty && data.content.last.isOwned)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: HugeIcon(icon: getStatusIcon(data.content.last.status), size: 20, color: CupertinoColors.systemGrey.resolveFrom(context)),
                                  ),
                                ),
                              TextSpan(
                                text: data.content.last.content.trim(),
                                style: TextStyle(
                                  fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
                                  color: CupertinoColors.systemGrey.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(data.content.last.sentAt),
                      style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey, fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w400),
                    ),
                    if (hasUnreadMessages)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: CupertinoTheme.of(context).primaryColor, borderRadius: BorderRadius.circular(12)),
                        child: Text(data.unreadMessages.toString(), style: TextStyle(color: CupertinoColors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => ChatOverlay(recipientUsername: data.recipientUsername)));
          },
        ),

        Divider(indent: 60, color: Theme.of(context).dividerColor.withAlpha(30)),
      ],
    );
  }

  // Overrides
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    allChats = Hive.box<Chat>("Chats");

    router.onMessageReceived.listen((messageData) {
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
    super.build(context);

    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            ValueListenableBuilder(
              valueListenable: router.connectionState,
              builder:
                  (context, connectionState, _) => CupertinoSliverNavigationBar(
                    leading:
                        connectionState != ConnectionState.Connected
                            ? Row(
                              spacing: 8,
                              children: [
                                Text("Connexion en cours", style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                                LoadingAnimationWidget.waveDots(color: CupertinoColors.secondaryLabel.resolveFrom(context), size: 14),
                              ],
                            )
                            : null,
                    largeTitle: Text("Conversations"),
                    trailing: GestureDetector(child: HugeIcon(icon: HugeIcons.strokeRoundedBubbleChatAdd), onTap: () => MainPage.pageIndex.value = 3),
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
                chatsList.sort((a, b) => b.content.last.sentAt.compareTo(a.content.last.sentAt));

                return chatsList.isEmpty
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedSparkles, strokeWidth: .5, size: 36, color: CupertinoColors.separator.resolveFrom(context)),
                        Text(
                          "Entamez une conversation !",
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20, color: CupertinoColors.separator.resolveFrom(context)),
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
