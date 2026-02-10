import 'package:flutter/cupertino.dart' hide ConnectionState;
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  List<Chat> get allChats =>
      database.chats.getAll()..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;

        final aDate = a.messages.isNotEmpty ? a.messages.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.messages.isNotEmpty ? b.messages.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

  // Widgets

  Widget buildChatBar(Chat chatData) {
    final isBlocked = globals.blockedUsers.contains(chatData.username);
    var hasUnreadMessages = chatData.unreadMessages > 0;

    final lastMessage = chatData.messages.isNotEmpty ? chatData.messages.last : null;
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
                  child: ProfilePictureDisplay(accountUsername: chatData.username, radius: 25),
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
                          if (isBlocked) HugeIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: AppColors.secondaryText.adaptTo(context)),

                          Text(
                            chatData.displayUsername ?? Account.getDefaultDisplayName(chatData.username),
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: adaptiveColor(AppColors.black, AppColors.white)),
                          ),
                        ],
                      ),

                      Expanded(
                        child:
                            lastMessage != null
                                ? Text.rich(
                                  TextSpan(
                                    children: [
                                      if (lastMessage.isOwned && statusIconData != null)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 2),
                                            child: HugeIcon(icon: statusIconData.icon, size: 20, color: statusIconData.color.withAlpha(.6.toByte())),
                                          ),
                                        ),
                                      if (lastMessage.isDeleted)
                                        WidgetSpan(
                                          alignment: PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 3),
                                            child: HugeIcon(
                                              icon: HugeIcons.strokeRoundedUnavailable,
                                              size: 14,
                                              strokeWidth: hasUnreadMessages ? 3 : 2,
                                              color: AppColors.secondaryText.adaptTo(context),
                                            ),
                                          ),
                                        ),
                                      ...CustomText.parseSpans(
                                        lastMessage.isDeleted ? "Message supprimé" : lastMessage.content.trim(),
                                        style: TextStyle(
                                          fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.w400,
                                          color: AppColors.secondaryText.adaptTo(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.ellipsis,
                                )
                                : Text("Envoyez un message...", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.tertiaryText.adaptTo(context))),
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
                        style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w400),
                      ),

                      Row(
                        spacing: 4,
                        children: [
                          if (chatData.isPinned) HugeIcon(icon: HugeIcons.strokeRoundedPin, size: 16, color: AppColors.secondaryText.adaptTo(context)),

                          if (hasUnreadMessages)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                chatData.unreadMessages.toString(),
                                style: TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
            Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(builder: (builder) => ChatPage(username: chatData.username)));
          },
        ),

        Divider(indent: 60, color: Theme.of(context).dividerColor.withAlpha(30)),
      ],
    );
  }

  // Overrides

  @override
  void initState() {
    super.initState();

    globals.blockedUsersNotifier.addListener(() => setState(() {}));

    // On connection to WebSocket
    network.connectionState.addListener(() async {
      // FOR THE REVIEW TEAMS
      if (globals.username == "apple.verification" || globals.username == "google.verification") {
        final now = DateTime.now();

        final abusiveChat = Chat.custom(username: "test.1");
        final abusiveMessages = [
          Message.custom(content: "Bonjour. Ceci est une conversation de démonstration.", sentAt: now.subtract(const Duration(minutes: 5)), isOwned: false),
          Message.custom(content: "Salut, comment ça va ?", sentAt: now.subtract(const Duration(minutes: 4)), isOwned: true),
          Message.custom(content: "Tu es vraiment nul, personne veut parler avec toi.", sentAt: now.subtract(const Duration(minutes: 3)), isOwned: false),
          Message.custom(content: "Ce message est un exemple de contenu à signaler.", sentAt: now.subtract(const Duration(minutes: 2)), isOwned: false),
        ];

        final normalChat = Chat.custom(username: "test.2");
        final normalMessages = [
          Message.custom(content: "Bonjour, ceci est un exemple de chat normal.", sentAt: now.subtract(const Duration(minutes: 6)), isOwned: false),
          Message.custom(content: "Merci, c'est parfait pour la vérification.", sentAt: now.subtract(const Duration(minutes: 5)), isOwned: true),
          Message.custom(content: "N'hésitez pas à signaler ou bloquer un utilisateur.", sentAt: now.subtract(const Duration(minutes: 4)), isOwned: false),
        ];

        for (var msg in abusiveMessages) {
          await database.messages.save(msg);
          abusiveChat.messages.add(msg);
        }

        for (var msg in normalMessages) {
          await database.messages.save(msg);
          normalChat.messages.add(msg);
        }

        await database.chats.save(abusiveChat);
        await database.chats.save(normalChat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            ValueListenableBuilder(
              valueListenable: network.connectionState,
              builder:
                  (context, connectionState, _) => CupertinoSliverNavigationBar(
                    leading:
                        (connectionState != ConnectionState.Connected || network.isLocalhost)
                            ? Row(
                              spacing: 8,
                              children: [
                                Text(
                                  network.isLocalhost ? "Connecté au Localhost" : "Connexion en cours",
                                  style: TextStyle(color: network.isLocalhost ? AppColors.red : AppColors.secondaryText.adaptTo(context)),
                                ),
                                network.isLocalhost
                                    ? HugeIcon(icon: HugeIcons.strokeRoundedAlert02, color: AppColors.red, size: 20, strokeWidth: 1.5)
                                    : LoadingAnimationWidget.waveDots(color: AppColors.secondaryText.adaptTo(context), size: 14),
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
            child: StreamBuilder(
              stream: database.chats.watchAll(),
              builder: (context, _) {
                return allChats.isEmpty
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedSleeping, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),

                        const SizedBox(height: 8),
                        Text("Silence total...", style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22)),
                        Text(
                          "Messagyre est faite aussi pour discuter !",
                          style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.tertiaryText.adaptTo(context)),
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
                      itemCount: allChats.length,
                      itemBuilder: (context, index) {
                        return buildChatBar(allChats[index]);
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
