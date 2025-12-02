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
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:uuid/uuid.dart';

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

  Widget buildChatBar(Chat chatData) {
    final isBlocked = data.blockedUsers.contains(chatData.recipientUsername);
    var hasUnreadMessages = chatData.unreadMessages > 0;

    final lastMessage = chatData.content.isNotEmpty ? chatData.content.last : null;
    final statusIconData = lastMessage != null ? getStatusIcon(lastMessage.status) : null;

    return Column(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  foregroundDecoration: isBlocked ? BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation) : null,
                  child: ProfilePictureDisplay(accountUsername: chatData.recipientUsername, radius: 25),
                ),

                SizedBox(width: 12),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          if (isBlocked)
                            Opacity(
                              opacity: .5,
                              child: HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                            ),
                          Text(
                            chatData.recipientDisplayUsername ?? Account.getDefaultDisplayName(chatData.recipientUsername),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: adaptiveColor(CupertinoColors.black, CupertinoColors.white)),
                          ),
                        ],
                      ),

                      Expanded(
                        child:
                            lastMessage != null
                                ? Text.rich(
                                  TextSpan(
                                    children: [
                                      if (lastMessage.isOwned)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 2),
                                            child: Opacity(opacity: .6, child: HugeIcon(icon: statusIconData!.icon, size: 20, color: statusIconData.color)),
                                          ),
                                        ),
                                      if (lastMessage.isDeleted)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 3),
                                            child: Opacity(
                                              opacity: .6,
                                              child: HugeIcon(
                                                icon: HugeIcons.strokeRoundedUnavailable,
                                                size: 14,
                                                strokeWidth: hasUnreadMessages ? 3 : 2,
                                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ...CustomText.parseSpans(
                                        lastMessage.isDeleted ? "Message supprimé" : lastMessage.content.trim(),
                                        style: TextStyle(
                                          fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
                                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                )
                                : Text(
                                  "Envoyez un message...",
                                  style: TextStyle(fontStyle: FontStyle.italic, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                                ),
                      ),
                    ],
                  ),
                ),
                if (lastMessage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        lastMessage.sentAt.isSameDayAs(DateTime.now()) ? DateFormat('HH:mm').format(lastMessage.sentAt) : formatDate(lastMessage.sentAt),
                        style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey, fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w400),
                      ),

                      Row(
                        spacing: 4,
                        children: [
                          if (chatData.isPinned)
                            Opacity(
                              opacity: .5,
                              child: HugeIcon(icon: HugeIcons.strokeRoundedPin, size: 16, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                            ),
                          if (hasUnreadMessages)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: CupertinoTheme.of(context).primaryColor, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                chatData.unreadMessages.toString(),
                                style: TextStyle(color: CupertinoColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          onPressed: () {
            Navigator.of(
              context,
              rootNavigator: true,
            ).push(CupertinoPageRoute(builder: (builder) => ChatOverlay(recipientUsername: chatData.recipientUsername)));
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

    router.connectionState.addListener(() {
      // FOR THE APPLE VERIFICATION TEAM \\
      if (data.username == "apple.verification" || data.username == "apple.verify.temp") {
        final now = DateTime.now();

        final abusiveChat = Chat(recipientUsername: "test.1");
        abusiveChat.content.addAll([
          Message(
            id: const Uuid().v4(),
            content: "Bonjour. Ceci est une conversation de démonstration.",
            sentAt: now.subtract(const Duration(minutes: 5)),
            isOwned: false,
          ),
          Message(id: const Uuid().v4(), content: "Salut, comment ça va ?", sentAt: now.subtract(const Duration(minutes: 4)), isOwned: true),
          Message(
            id: const Uuid().v4(),
            content: "Tu es vraiment nul, personne veut parler avec toi.",
            sentAt: now.subtract(const Duration(minutes: 3)),
            isOwned: false,
          ),
          Message(
            id: const Uuid().v4(),
            content: "Ce message est un exemple de contenu à signaler.",
            sentAt: now.subtract(const Duration(minutes: 2)),
            isOwned: false,
          ),
        ]);

        final normalChat = Chat(recipientUsername: "test.2");
        normalChat.content.addAll([
          Message(
            id: const Uuid().v4(),
            content: "Bonjour, ceci est un exemple de chat normal.",
            sentAt: now.subtract(const Duration(minutes: 6)),
            isOwned: false,
          ),
          Message(
            id: const Uuid().v4(),
            content: "Merci, c'est parfait pour la vérification.",
            sentAt: now.subtract(const Duration(minutes: 5)),
            isOwned: true,
          ),
          Message(
            id: const Uuid().v4(),
            content: "N'hésitez pas à signaler ou bloquer un utilisateur.",
            sentAt: now.subtract(const Duration(minutes: 4)),
            isOwned: false,
          ),
        ]);

        allChats.put("test.1", abusiveChat);
        allChats.put("test.2", normalChat);
      }
    });

    data.blockedUsersNotifier.addListener(() => setState(() {}));

    router.onMessageReceived.listen((messageData) {
      if (!mounted) return;

      var senderUsername = messageData["SenderUsername"]!.toString();
      if (data.openChatUsername == senderUsername) return;

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

    router.onMessageStatusUpdateReceived.listen((messageStatusUpdate) {
      var senderUsername = messageStatusUpdate["SenderUsername"]!.toString();
      if (data.openChatUsername == senderUsername) return;

      var targetChat = allChats.get(senderUsername);
      if (targetChat == null) return;

      final targetMessage = targetChat.content.firstWhere(
        (message) => message.isOwned && message.id == messageStatusUpdate["ID"],
        orElse: () => Message.empty(),
      );

      targetMessage.status = (messageStatusUpdate["Status"] as MessageStatus?) ?? MessageStatus.Failed;

      setState(() {});
    });

    router.onMessageDeletionReceived.listen((messageDeletion) {
      var senderUsername = messageDeletion["SenderUsername"]!.toString();
      if (data.openChatUsername == senderUsername) return;

      var targetChat = allChats.get(senderUsername);
      if (targetChat == null) return;

      final targetMessages = targetChat.content.where((message) => message.id == messageDeletion["ID"]);

      setState(() {
        for (var message in targetMessages) {
          message.isDeleted = true;
        }
      });
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
                chatsList.sort((a, b) {
                  if (a.isPinned && !b.isPinned) return -1;
                  if (!a.isPinned && b.isPinned) return 1;

                  final aDate = a.content.isNotEmpty ? a.content.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate = b.content.isNotEmpty ? b.content.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

                return chatsList.isEmpty
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        Opacity(
                          opacity: .25,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSleeping,
                            strokeWidth: 1.5,
                            size: 48,
                            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Silence total...",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel.resolveFrom(context), fontSize: 22),
                        ),
                        Text(
                          "Messagyre est fait pour discuter !",
                          style: TextStyle(fontWeight: FontWeight.w400, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                        ),
                        CupertinoButton(
                          onPressed: () => MainPage.pageIndex.value = 3,
                          padding: EdgeInsets.only(top: 40),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 6,
                            children: [
                              Text("Briser la glace", style: TextStyle(fontWeight: FontWeight.w400)),
                              HugeIcon(icon: HugeIcons.strokeRoundedBubbleChatAdd, size: 18),
                            ],
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
