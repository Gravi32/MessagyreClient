import 'dart:math';

import 'package:flutter/cupertino.dart' hide ConnectionState, Page;
import 'package:flutter/material.dart' hide ConnectionState, Page;
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:messagyre_client/configuration/app_colors.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/database/models/chats/chat.dart';
import 'package:messagyre_client/database/models/messages/message.dart';
import 'package:messagyre_client/main.dart';
import 'package:messagyre_client/pages/chats/subpages/chat_page.dart';
import 'package:messagyre_client/services/database_service.dart';
import 'package:messagyre_client/services/network_service.dart';
import 'package:messagyre_client/services/globals_service.dart';
import 'package:messagyre_client/utility/account_class.dart';
import 'package:messagyre_client/utility/utility.dart';
import 'package:messagyre_client/utility/widgets/basics/button.dart';
import 'package:messagyre_client/utility/widgets/basics/page.dart';
import 'package:messagyre_client/utility/widgets/basics/top_bar.dart';
import 'package:messagyre_client/utility/widgets/connection_status.dart';
import 'package:messagyre_client/utility/widgets/custom_text.dart';
import 'package:messagyre_client/utility/widgets/profile_picture_display.dart';
import 'package:messagyre_client/utility/wrappers/custom_icon.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({super.key});

  @override
  State<StatefulWidget> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final network = NetworkService();
  final globals = GlobalsService();
  final database = DatabaseService();

  final pageScrollController = ScrollController();

  bool showThumbnailChats = false;

  final Map<String, String?> _mockPhotos = {
    'lucas_v7': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=150',
    'enzo_drk': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=150',
    'mathis_99': 'https://images.unsplash.com/photo-1592194996308-7b43878e84a6?w=150',
    'nathan_off': null,
    'hugo_m': 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=150',
    'leo_paris': 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=150',
    'theo_j': 'https://images.unsplash.com/photo-1543906965-f9520aa2ed8b?w=150',
    'gabriel_l': null,
    'maxime_r': 'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=150',
    'yanis_b': 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?w=150',
  };

  final Map<String, Message> _mockLastMessages = {};

  List<Chat> get _mockedFrenchChats {
    final now = DateTime.now();
    final mocks = [
      {'user': 'lucas_v7', 'display': 'Lucas 🇫🇷', 'msg': 'On se voit à quelle heure ?', 'own': true, 'status': MessageStatus.Read},
      {'user': 'enzo_drk', 'display': 'Enzo', 'msg': 'T\'as fait l\'exo de maths ? 💀', 'own': false, 'status': MessageStatus.Delivered},
      {'user': 'mathis_99', 'display': 'Mathis B.', 'msg': 'Je t\'envoie le lien tout de suite', 'own': true, 'status': MessageStatus.Read},
      {'user': 'nathan_off', 'display': 'Nathan', 'msg': 'Vas-y chaud pour la console!', 'own': true, 'status': MessageStatus.Delivered},
      {'user': 'hugo_m', 'display': 'Hugo', 'msg': 'Mdr t\'es sérieux ??', 'own': false, 'status': MessageStatus.Delivered},
      {'user': 'leo_paris', 'display': 'Léo', 'msg': 'Je t\'ai laissé les clés.', 'own': true, 'status': MessageStatus.Read},
      {'user': 'theo_j', 'display': 'Théo', 'msg': 'Je t\'attends au skatepark.', 'own': false, 'status': MessageStatus.Delivered},
      {'user': 'gabriel_l', 'display': 'Gabriel', 'msg': 'Ok ça marche.', 'own': true, 'status': MessageStatus.Read},
      {'user': 'maxime_r', 'display': 'Maxime', 'msg': 'C\'est incroyable mec!', 'own': true, 'status': MessageStatus.Read},
      {'user': 'yanis_b', 'display': 'Yanis', 'msg': 'Je arrive dans 5 minutes.', 'own': false, 'status': MessageStatus.Delivered},
    ];

    return mocks.map((m) {
      final username = m['user'] as String;
      final chat = Chat.custom(
        username: username,
        displayUsername: m['display'] as String,
        unreadMessages: (m['own'] as bool) == false ? Random().nextInt(3) : 0,
      );

      _mockLastMessages[username] = Message.custom(
        content: m['msg'] as String,
        sentAt: now.subtract(Duration(minutes: (mocks.indexOf(m) + 1) * 12)),
        isOwned: m['own'] as bool,
      )..status = m['status'] as MessageStatus;

      return chat;
    }).toList();
  }

  List<Chat> get allChats {
    if (showThumbnailChats) {
      return _mockedFrenchChats;
    }

    return database.chats.getAll()..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      final aDate = a.messages.isNotEmpty ? a.messages.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.messages.isNotEmpty ? b.messages.last.sentAt : DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  // Widgets

  Widget buildChatBar(Chat chatData) {
    final isBlocked = globals.blockedUsers.contains(chatData.username);
    var hasUnreadMessages = chatData.unreadMessages > 0;

    final lastMessage = showThumbnailChats ? _mockLastMessages[chatData.username] : (chatData.messages.isNotEmpty ? chatData.messages.last : null);

    final statusIconData = lastMessage != null ? getStatusIcon(lastMessage.status) : null;

    // Forcing keyboard closure, it happens that the keyboard stays open
    FocusManager.instance.primaryFocus?.unfocus();

    return SizedBox(
      height: 50,
      child: CupertinoButton(
        padding: .symmetric(horizontal: 6),
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            // Profile Picture
            ProfilePictureDisplay(
              accountUsername: (showThumbnailChats && _mockPhotos[chatData.username] != null) ? null : chatData.username,
              pictureURL: showThumbnailChats ? _mockPhotos[chatData.username] : null,
              isBlocked: isBlocked,
            ),

            const SizedBox(width: 16),

            // Username and last message
            Expanded(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Spacer(flex: 1),
                  Row(
                    spacing: 6,
                    children: [
                      // Blocked icon
                      if (isBlocked) CustomIcon(icon: HugeIcons.strokeRoundedUnavailable, size: 16, color: AppColors.secondaryText.adaptTo(context)),

                      // Username
                      Flexible(
                        child: Text(
                          chatData.displayUsername ?? Account.getDefaultDisplayName(chatData.username),
                          style: AppStyles.secondaryHeader(context),
                          overflow: .ellipsis,
                        ),
                      ),
                    ],
                  ),

                  lastMessage != null
                      ? Text.rich(
                          TextSpan(
                            children: [
                              if (lastMessage.isOwned && statusIconData != null)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: CustomIcon(
                                      icon: statusIconData.icon,
                                      size: 20,
                                      color: statusIconData.color == AppColors.white && Theme.of(context).brightness == Brightness.light
                                          ? AppColors.grey
                                          : statusIconData.color.withAlpha(.6.toByte()),
                                    ),
                                  ),
                                ),
                              if (lastMessage.isDeleted)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 3),
                                    child: CustomIcon(
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
                      : Text(
                          "Envoyez un message...",
                          style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.tertiaryText.adaptTo(context)),
                        ),
                  Spacer(flex: 2),
                ],
              ),
            ),

            // Date and unread messages badge
            if (lastMessage != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    lastMessage.sentAt.isSameDayAs(DateTime.now()) ? DateFormat('HH:mm').format(lastMessage.sentAt) : formatDate(lastMessage.sentAt),
                    style: TextStyle(fontSize: 14, color: AppColors.grey, fontWeight: hasUnreadMessages ? FontWeight.w600 : FontWeight.w400),
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      if (chatData.isPinned) CustomIcon(icon: HugeIcons.strokeRoundedPin, size: 16, color: AppColors.secondaryText.adaptTo(context)),

                      if (hasUnreadMessages)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            chatData.unreadMessages.toString(),
                            style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
          ],
        ),

        onPressed: () {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(CupertinoPageRoute(builder: (builder) => ChatPage(username: chatData.username))).then((_) => setState(() {}));
        },
      ),
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
    return Page.sliver(
      controller: pageScrollController,
      topBar: TopBar.sliver(
        title: "Conversations",
        leading: ConnectionStatus(),
        trailing: Button.icon(context, icon: HugeIcons.strokeRoundedBubbleChatAdd, onTap: () => MainPage.pageIndex.value = 3),
      ),
      body: StreamBuilder(
        stream: database.chats.watchAll(),
        builder: (context, snapshot) {
          final list = allChats;
          final hasUnread = list.any((chat) => chat.unreadMessages > 0);

          if (App.pages[2].showBadge.value != hasUnread) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              App.pages[2].showBadge.value = hasUnread;
            });
          }

          return list.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    CustomIcon(icon: HugeIcons.strokeRoundedSleeping, strokeWidth: 1.5, size: 48, color: AppColors.tertiaryText.adaptTo(context)),

                    const SizedBox(height: 8),
                    Text(
                      "Silence total...",
                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.secondaryText.adaptTo(context), fontSize: 22),
                    ),
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
                          CustomIcon(icon: HugeIcons.strokeRoundedBubbleChatAdd, size: 18),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: EdgeInsets.only(top: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    return buildChatBar(list[index]);
                  },
                  separatorBuilder: (context, _) => Divider(indent: 60, color: Theme.of(context).dividerColor.withAlpha(30)),
                );
        },
      ),
    );
  }
}
